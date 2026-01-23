// home_router.dart
import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'onboarding_page.dart';
import 'categories_page.dart';

enum SortMode { dateDesc, dateAsc, valueDesc, valueAsc }

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  final supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _notifs =
      FlutterLocalNotificationsPlugin();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _settings;

  int? _mesSelecionado; // null = todos
  List<Map<String, dynamic>> _lancamentos = [];

  // filtros
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _tipoFiltro = 'T'; // T=Todos, R=Receita, D=Despesa
  String? _categoriaFiltro; // null = todas
  SortMode _sortMode = SortMode.dateDesc;

  // categorias locais
  List<String> _categorias = const [];

  double _totalReceitasAno = 0.0; // limite MEI (somente tipo!='D')
  double _totalReceitasPeriodo = 0.0;
  double _totalDespesasPeriodo = 0.0;

  List<double> _receitasMes = List.filled(12, 0.0);
  List<double> _despesasMes = List.filled(12, 0.0);

  static const List<String> _mesesShort = [
    'Todos',
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      final v = _searchCtrl.text;
      if (v != _search && mounted) {
        setState(() => _search = v);
      }
    });

    _initNotifications()
        .then((_) => _loadCategories())
        .then((_) => _loadAll());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifs.initialize(initSettings);

    final androidPlugin =
        _notifs.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('lm_categories');

      const defaults = [
        'Geral',
        'Vendas',
        'Serviços',
        'Impostos',
        'Materiais',
        'Transporte',
        'Alimentação',
        'Outros',
      ];

      _categorias = (list == null || list.isEmpty) ? defaults : list;

      if (_categoriaFiltro != null && !_categorias.contains(_categoriaFiltro)) {
        _categoriaFiltro = null;
      }

      if (mounted) setState(() {});
    } catch (_) {
      _categorias = const [
        'Geral',
        'Vendas',
        'Serviços',
        'Impostos',
        'Materiais',
        'Transporte',
        'Alimentação',
        'Outros',
      ];
      if (mounted) setState(() {});
    }
  }

  Future<void> _maybeNotifyLimit({
    required int year,
    required double limitAnual,
    required double totalReceitasAno,
    required bool notificationsEnabled,
  }) async {
    if (!notificationsEnabled) return;
    if (limitAnual <= 0) return;

    final ratio = totalReceitasAno / limitAnual;

    int level = 0;
    if (ratio >= 0.95) {
      level = 95;
    } else if (ratio >= 0.80) {
      level = 80;
    } else {
      return;
    }

    final int? lastYear = (_settings?['last_alert_year'] as int?);
    final int? lastLevel = (_settings?['last_alert_level'] as int?);

    final bool shouldNotify =
        (lastYear != year) || ((lastLevel ?? 0) < level);

    if (!shouldNotify) return;

    final pct = (ratio * 100).clamp(0, 999).toStringAsFixed(0);
    final title = level == 95
        ? 'Atenção: limite MEI quase estourando'
        : 'Aviso: perto do limite MEI';
    final body =
        'Você já usou $pct% do limite anual. Receitas no ano: ${_formatBRL(totalReceitasAno)}';

    const androidDetails = AndroidNotificationDetails(
      'limite_mei_alerts',
      'Alertas de Limite MEI',
      channelDescription: 'Avisos quando estiver perto do limite anual do MEI',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifs.show(1001, title, body, details);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('settings').update({
      'last_alert_year': year,
      'last_alert_level': level,
      'last_alert_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', user.id);

    _settings = {
      ...?_settings,
      'last_alert_year': year,
      'last_alert_level': level,
      'last_alert_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _loadAll() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _settings = null;
        _lancamentos = [];
        _totalReceitasAno = 0;
        _totalReceitasPeriodo = 0;
        _totalDespesasPeriodo = 0;
        _receitasMes = List.filled(12, 0.0);
        _despesasMes = List.filled(12, 0.0);
        _error = 'Usuário não autenticado.';
      });
      return;
    }

    try {
      final settingsRow = await supabase
          .from('settings')
          .select(
              'user_id, year, annual_limit, notifications_enabled, last_alert_year, last_alert_level, last_alert_at')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (settingsRow == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/onboarding');
        });
        setState(() {
          _loading = false;
          _settings = null;
        });
        return;
      }

      _settings = (settingsRow as Map).cast<String, dynamic>();
      final int year = (_settings!['year'] as int?) ?? DateTime.now().year;
      final double limiteAnual =
          (_settings!['annual_limit'] as num?)?.toDouble() ?? 0.0;
      final bool notifEnabled =
          (_settings!['notifications_enabled'] as bool?) ?? true;

      DateTime start;
      DateTime end;

      if (_mesSelecionado == null) {
        start = DateTime(year, 1, 1);
        end = DateTime(year + 1, 1, 1);
      } else {
        start = DateTime(year, _mesSelecionado!, 1);
        end = (_mesSelecionado == 12)
            ? DateTime(year + 1, 1, 1)
            : DateTime(year, _mesSelecionado! + 1, 1);
      }

      final totalAnoRow = await supabase
          .from('vw_receitas_total_ano')
          .select('total')
          .eq('user_id', user.id)
          .eq('year', year)
          .maybeSingle();

      final double totalReceitasAno =
          (totalAnoRow?['total'] as num?)?.toDouble() ?? 0.0;

      final fluxoRows = await supabase
          .from('vw_fluxo_por_mes')
          .select('month, receitas, despesas')
          .eq('user_id', user.id)
          .eq('year', year);

      final List<double> receitasMes = List.filled(12, 0.0);
      final List<double> despesasMes = List.filled(12, 0.0);

      for (final row in (fluxoRows as List)) {
        final m = ((row as Map)['month'] as num?)?.toInt();
        final r = (row['receitas'] as num?)?.toDouble() ?? 0.0;
        final d = (row['despesas'] as num?)?.toDouble() ?? 0.0;
        if (m != null && m >= 1 && m <= 12) {
          receitasMes[m - 1] = r;
          despesasMes[m - 1] = d;
        }
      }

      final rows = await supabase
          .from('receitas')
          .select('id, data, valor, descricao, tipo, categoria, created_at')
          .eq('user_id', user.id)
          .gte('data', _formatDate(start))
          .lt('data', _formatDate(end))
          .order('data', ascending: false)
          .limit(600);

      final list = (rows as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      double totalReceitasPeriodo = 0.0;
      double totalDespesasPeriodo = 0.0;

      for (final r in list) {
        final tipo = (r['tipo'] ?? 'R').toString();
        final valor = (r['valor'] as num?)?.toDouble() ?? 0.0;
        if (tipo == 'D') {
          totalDespesasPeriodo += valor;
        } else {
          totalReceitasPeriodo += valor;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalReceitasAno = totalReceitasAno;
        _receitasMes = receitasMes;
        _despesasMes = despesasMes;
        _lancamentos = list;
        _totalReceitasPeriodo = totalReceitasPeriodo;
        _totalDespesasPeriodo = totalDespesasPeriodo;
        _loading = false;
      });

      await _maybeNotifyLimit(
        year: year,
        limitAnual: limiteAnual,
        totalReceitasAno: totalReceitasAno,
        notificationsEnabled: notifEnabled,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar dados: $e';
      });
    }
  }

  Future<void> _exportarCsv() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final year = (_settings?['year'] as int?) ?? DateTime.now().year;

      DateTime start;
      DateTime end;

      if (_mesSelecionado == null) {
        start = DateTime(year, 1, 1);
        end = DateTime(year + 1, 1, 1);
      } else {
        start = DateTime(year, _mesSelecionado!, 1);
        end = (_mesSelecionado == 12)
            ? DateTime(year + 1, 1, 1)
            : DateTime(year, _mesSelecionado! + 1, 1);
      }

      final rows = await supabase
          .from('receitas')
          .select('data, valor, descricao, tipo, categoria')
          .eq('user_id', user.id)
          .gte('data', _formatDate(start))
          .lt('data', _formatDate(end))
          .order('data', ascending: true);

      final list = (rows as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      final filtered = _applyFiltersAndSort(list);

      final sb = StringBuffer();
      sb.writeln('data;tipo;categoria;valor;descricao');

      for (final r in filtered) {
        final data = (r['data'] ?? '').toString();
        final tipo = (r['tipo'] ?? 'R').toString();
        final categoria =
            (r['categoria'] ?? 'Geral').toString().replaceAll(';', ',');
        final valor = (r['valor'] as num?)?.toDouble() ?? 0.0;
        final rawDesc = r['descricao'];
        final desc = (rawDesc == null ? '' : rawDesc.toString())
            .replaceAll('\n', ' ')
            .replaceAll(';', ',');

        final valorTxt = valor.toStringAsFixed(2).replaceAll('.', ',');
        sb.writeln('$data;$tipo;$categoria;$valorTxt;$desc');
      }

      final dir = await getTemporaryDirectory();
      final mesTag = _mesSelecionado == null
          ? 'todos'
          : _mesSelecionado!.toString().padLeft(2, '0');

      final file =
          File('${dir.path}/limite_mei_lancamentos_${year}_$mesTag.csv');
      await file.writeAsString(sb.toString(), flush: true);

      final labelMes =
          _mesSelecionado == null ? 'Todos' : _mesesShort[_mesSelecionado!];

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exportação ($labelMes/$year) - Limite MEI',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar CSV: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _applyFiltersAndSort(
      List<Map<String, dynamic>> base) {
    final q = _search.trim().toLowerCase();

    final filtered = base.where((r) {
      final tipo = (r['tipo'] ?? 'R').toString();
      final cat = (r['categoria'] ?? 'Geral').toString();
      final desc = (r['descricao'] ?? '').toString();
      final data = (r['data'] ?? '').toString();

      if (_tipoFiltro != 'T' && tipo != _tipoFiltro) return false;
      if (_categoriaFiltro != null && cat != _categoriaFiltro) return false;

      if (q.isNotEmpty) {
        final hay = ('$cat $desc $data').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    int compareDate(Map<String, dynamic> a, Map<String, dynamic> b) {
      final da = (a['data'] ?? '').toString();
      final db = (b['data'] ?? '').toString();
      return da.compareTo(db);
    }

    int compareValue(Map<String, dynamic> a, Map<String, dynamic> b) {
      final va = (a['valor'] as num?)?.toDouble() ?? 0.0;
      final vb = (b['valor'] as num?)?.toDouble() ?? 0.0;
      return va.compareTo(vb);
    }

    filtered.sort((a, b) {
      switch (_sortMode) {
        case SortMode.dateAsc:
          return compareDate(a, b);
        case SortMode.dateDesc:
          return compareDate(b, a);
        case SortMode.valueAsc:
          final c = compareValue(a, b);
          if (c != 0) return c;
          return compareDate(b, a);
        case SortMode.valueDesc:
          final c = compareValue(b, a);
          if (c != 0) return c;
          return compareDate(b, a);
      }
    });

    return filtered;
  }

  Map<String, double> _calcResumoFrom(List<Map<String, dynamic>> list) {
    double r = 0.0;
    double d = 0.0;
    for (final row in list) {
      final tipo = (row['tipo'] ?? 'R').toString();
      final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
      if (tipo == 'D') {
        d += valor;
      } else {
        r += valor;
      }
    }
    return {'receitas': r, 'despesas': d, 'saldo': r - d};
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _formatDateBR(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatBRL(double v) {
    final negative = v < 0;
    final absV = v.abs();

    final s = absV.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }

    final sign = negative ? '-' : '';
    return 'R\$ $sign${buf.toString()},$decPart';
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _openSettings() async {
    await Future.delayed(const Duration(milliseconds: 10));

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
    );

    if (changed == true) {
      await _loadCategories();
      await _loadAll();
    }
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesPage()),
    );
    await _loadCategories();
    if (mounted) setState(() {});
  }

  Future<bool> _confirmDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir lançamento?'),
            content: const Text('Essa ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteById(dynamic id) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('receitas').delete().eq('id', id).eq('user_id', user.id);
    await _loadAll();
  }

  void _clearFilters() {
    setState(() {
      _tipoFiltro = 'T';
      _categoriaFiltro = null;
      _sortMode = SortMode.dateDesc;
    });
    _searchCtrl.clear(); // o listener já atualiza _search
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final now = DateTime.now();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Limite MEI'),
          actions: [
            IconButton(icon: const Icon(Icons.download), onPressed: _exportarCsv),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'cats') await _openCategories();
                if (v == 'settings') await _openSettings();
                if (v == 'logout') await _logout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cats', child: Text('Categorias')),
                PopupMenuItem(value: 'settings', child: Text('Configurações')),
                PopupMenuItem(value: 'logout', child: Text('Sair')),
              ],
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: _loadAll, child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ),
      );
    }

    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int year = (_settings!['year'] as int?) ?? DateTime.now().year;
    final double limiteAnual =
        (_settings!['annual_limit'] as num?)?.toDouble() ?? 0.0;

    final String labelMes =
        _mesSelecionado == null ? 'Todos' : _mesesShort[_mesSelecionado!];

    final filteredLanc = _applyFiltersAndSort(_lancamentos);
    final resumoFiltros = _calcResumoFrom(filteredLanc);

    final bool filtrosAtivos = _search.trim().isNotEmpty ||
        _tipoFiltro != 'T' ||
        _categoriaFiltro != null ||
        _sortMode != SortMode.dateDesc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limite MEI'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportarCsv),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'cats') await _openCategories();
              if (v == 'settings') await _openSettings();
              if (v == 'logout') await _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'cats', child: Text('Categorias')),
              PopupMenuItem(value: 'settings', child: Text('Configurações')),
              PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => LancamentoPage(
                year: year,
                categorias: _categorias,
              ),
            ),
          );
          if (saved == true) await _loadAll();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Olá, ${user?.email ?? ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _ResumoCard(
              now: now,
              year: year,
              mesLabel: labelMes,
              limiteAnual: limiteAnual,
              totalReceitasAno: _totalReceitasAno,
              saldoAnualLimite: limiteAnual - _totalReceitasAno,
              receitasPeriodo: _totalReceitasPeriodo,
              despesasPeriodo: _totalDespesasPeriodo,
              receitasMes: _receitasMes,
              despesasMes: _despesasMes,
              formatBRL: _formatBRL,
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Text('Mês: '),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _mesSelecionado,
                        items: const [
                          DropdownMenuItem<int?>(
                              value: null, child: Text('Todos')),
                          DropdownMenuItem<int?>(value: 1, child: Text('Janeiro')),
                          DropdownMenuItem<int?>(value: 2, child: Text('Fevereiro')),
                          DropdownMenuItem<int?>(value: 3, child: Text('Março')),
                          DropdownMenuItem<int?>(value: 4, child: Text('Abril')),
                          DropdownMenuItem<int?>(value: 5, child: Text('Maio')),
                          DropdownMenuItem<int?>(value: 6, child: Text('Junho')),
                          DropdownMenuItem<int?>(value: 7, child: Text('Julho')),
                          DropdownMenuItem<int?>(value: 8, child: Text('Agosto')),
                          DropdownMenuItem<int?>(value: 9, child: Text('Setembro')),
                          DropdownMenuItem<int?>(value: 10, child: Text('Outubro')),
                          DropdownMenuItem<int?>(value: 11, child: Text('Novembro')),
                          DropdownMenuItem<int?>(value: 12, child: Text('Dezembro')),
                        ],
                        onChanged: (v) async {
                          setState(() => _mesSelecionado = v);
                          await _loadAll();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar',
                        hintText: 'Descrição, categoria, data...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _tipoFiltro == 'T',
                            onSelected: (_) => setState(() => _tipoFiltro = 'T'),
                          ),
                          ChoiceChip(
                            label: const Text('Receitas'),
                            selected: _tipoFiltro == 'R',
                            onSelected: (_) => setState(() => _tipoFiltro = 'R'),
                          ),
                          ChoiceChip(
                            label: const Text('Despesas'),
                            selected: _tipoFiltro == 'D',
                            onSelected: (_) => setState(() => _tipoFiltro = 'D'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Limpar filtros'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text('Categoria: '),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _categoriaFiltro,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ..._categorias.map(
                                (c) => DropdownMenuItem<String?>(
                                  value: c,
                                  child: Text(c),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _categoriaFiltro = v),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Text('Ordenar: '),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<SortMode>(
                            isExpanded: true,
                            value: _sortMode,
                            items: const [
                              DropdownMenuItem(
                                value: SortMode.dateDesc,
                                child: Text('Data (mais recente)'),
                              ),
                              DropdownMenuItem(
                                value: SortMode.dateAsc,
                                child: Text('Data (mais antiga)'),
                              ),
                              DropdownMenuItem(
                                value: SortMode.valueDesc,
                                child: Text('Valor (maior)'),
                              ),
                              DropdownMenuItem(
                                value: SortMode.valueAsc,
                                child: Text('Valor (menor)'),
                              ),
                            ],
                            onChanged: (v) => setState(
                                () => _sortMode = v ?? SortMode.dateDesc),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (filtrosAtivos)
              _ResumoFiltrosCard(
                count: filteredLanc.length,
                receitas: resumoFiltros['receitas'] ?? 0.0,
                despesas: resumoFiltros['despesas'] ?? 0.0,
                saldo: resumoFiltros['saldo'] ?? 0.0,
                formatBRL: _formatBRL,
              ),

            if (filtrosAtivos) const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lançamentos ($year - $labelMes)',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: _loadAll, child: const Text('Atualizar')),
              ],
            ),
            const SizedBox(height: 8),

            if (filteredLanc.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text('Nenhum lançamento com os filtros atuais.'),
                ),
              )
            else
              ...filteredLanc.map((r) {
                final id = r['id'];
                final tipo = (r['tipo'] ?? 'R').toString();
                final valor = (r['valor'] as num?)?.toDouble() ?? 0.0;
                final data = (r['data'] ?? '').toString();
                final desc = (r['descricao'] ?? '').toString();
                final cat = (r['categoria'] ?? 'Geral').toString();

                final title =
                    tipo == 'D' ? '- ${_formatBRL(valor)}' : _formatBRL(valor);

                final subtitle = [
                  cat,
                  if (desc.trim().isNotEmpty) desc.trim(),
                ].join(' • ');

                return Dismissible(
                  key: ValueKey('lan_$id'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDeleteDialog(),
                  onDismissed: (_) async => _deleteById(id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete),
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle.isEmpty ? 'Geral' : subtitle),
                      trailing: Text(_formatDateBR(data)),
                      onTap: () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LancamentoPage(
                              year: year,
                              categorias: _categorias,
                              lancamento: r,
                            ),
                          ),
                        );
                        if (saved == true) await _loadAll();
                      },
                    ),
                  ),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ResumoFiltrosCard extends StatelessWidget {
  final int count;
  final double receitas;
  final double despesas;
  final double saldo;
  final String Function(double) formatBRL;

  const _ResumoFiltrosCard({
    required this.count,
    required this.receitas,
    required this.despesas,
    required this.saldo,
    required this.formatBRL,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo dos filtros',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            _row('Itens', count.toString()),
            const SizedBox(height: 6),
            _row('Receitas', formatBRL(receitas)),
            const SizedBox(height: 6),
            _row('Despesas', formatBRL(despesas)),
            const SizedBox(height: 6),
            _row(
              'Saldo',
              formatBRL(saldo),
              valueColor: saldo < 0 ? cs.error : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final DateTime now;
  final int year;
  final String mesLabel;

  final double limiteAnual;
  final double totalReceitasAno;
  final double saldoAnualLimite;

  final double receitasPeriodo;
  final double despesasPeriodo;

  final List<double> receitasMes;
  final List<double> despesasMes;

  final String Function(double) formatBRL;

  const _ResumoCard({
    required this.now,
    required this.year,
    required this.mesLabel,
    required this.limiteAnual,
    required this.totalReceitasAno,
    required this.saldoAnualLimite,
    required this.receitasPeriodo,
    required this.despesasPeriodo,
    required this.receitasMes,
    required this.despesasMes,
    required this.formatBRL,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final caixaPeriodo = receitasPeriodo - despesasPeriodo;

    final maxY = max(
      1.0,
      max(
        receitasMes.fold<double>(0.0, (m, v) => max(m, v)),
        despesasMes.fold<double>(0.0, (m, v) => max(m, v)),
      ),
    );

    final ratio = (limiteAnual <= 0) ? 0.0 : (totalReceitasAno / limiteAnual);
    final clamped = ratio.clamp(0.0, 1.0);

    Color barColor;
    if (ratio >= 0.95) {
      barColor = cs.error;
    } else if (ratio >= 0.80) {
      barColor = Colors.orange;
    } else {
      barColor = cs.primary;
    }

    final pctTxt = (ratio.isFinite ? (ratio * 100) : 0.0)
        .clamp(0, 999)
        .toStringAsFixed(0);

    final effectiveMonth = (now.year == year) ? now.month : 12;
    final limiteProporcional = limiteAnual * (effectiveMonth / 12.0);
    final saldoProporcional = limiteProporcional - totalReceitasAno;

    String ritmoTxt;
    Color? ritmoColor;
    if (now.year != year) {
      ritmoTxt = 'Ano $year (referência completa)';
      ritmoColor = null;
    } else if (saldoProporcional < 0) {
      ritmoTxt = 'Acima do ritmo em ${formatBRL(saldoProporcional.abs())}';
      ritmoColor = cs.error;
    } else {
      ritmoTxt = 'Abaixo do ritmo em ${formatBRL(saldoProporcional.abs())}';
      ritmoColor = cs.primary;
    }

    // Pacote A
    final restante = limiteAnual - totalReceitasAno;

    final int mesesRestantes =
        (year == now.year) ? (12 - now.month + 1) : (year < now.year ? 0 : 12);

    final double podeFaturarPorMes = (restante > 0 && mesesRestantes > 0)
        ? (restante / mesesRestantes)
        : 0.0;

    final int mesesDecorridos =
        (year == now.year) ? now.month : (year < now.year ? 12 : 0);

    final double mediaMensalAtual =
        (mesesDecorridos > 0) ? (totalReceitasAno / mesesDecorridos) : 0.0;

    final double projecaoAno =
        (mesesDecorridos > 0) ? (mediaMensalAtual * 12.0) : totalReceitasAno;

    String projTxt;
    Color? projColor;
    if (limiteAnual <= 0) {
      projTxt = 'Defina o limite anual nas configurações';
      projColor = cs.error;
    } else if (mesesDecorridos == 0) {
      projTxt = 'Projeção indisponível (ano ainda não iniciado)';
      projColor = null;
    } else if (projecaoAno >= limiteAnual) {
      projTxt = 'Projeção: estoura o limite';
      projColor = cs.error;
    } else if (projecaoAno >= limiteAnual * 0.95) {
      projTxt = 'Projeção: muito perto do limite';
      projColor = cs.error;
    } else if (projecaoAno >= limiteAnual * 0.80) {
      projTxt = 'Projeção: risco moderado';
      projColor = Colors.orange;
    } else {
      projTxt = 'Projeção: dentro do limite';
      projColor = cs.primary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo $year',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _kpiRow('Limite anual (MEI)', formatBRL(limiteAnual)),
            const SizedBox(height: 8),
            _kpiRow('Receitas do ano', formatBRL(totalReceitasAno)),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text('$pctTxt% do limite usado',
                style: Theme.of(context).textTheme.bodySmall),

            const SizedBox(height: 12),

            _kpiRow(
              'Falta para estourar',
              formatBRL(restante),
              valueColor: restante < 0 ? cs.error : null,
            ),

            const SizedBox(height: 8),

            _kpiRow(
              'Pode faturar por mês (até Dez)',
              formatBRL(podeFaturarPorMes),
              valueColor: (restante <= 0) ? cs.error : null,
            ),
            const SizedBox(height: 6),
            Text(
              (year == now.year)
                  ? 'Considerando $mesesRestantes mês(es) incluindo o mês atual'
                  : (year < now.year ? 'Ano encerrado' : 'Ano futuro (12 meses)'),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),

            _kpiRow(
              'Projeção do ano (média mensal)',
              formatBRL(projecaoAno),
              valueColor: projColor,
            ),
            const SizedBox(height: 6),
            Text(
              projTxt,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: projColor),
            ),

            const Divider(height: 24),

            _kpiRow('Limite proporcional (até $effectiveMonth/12)',
                formatBRL(limiteProporcional)),
            const SizedBox(height: 8),
            _kpiRow(
              'Saldo proporcional',
              formatBRL(saldoProporcional),
              valueColor: saldoProporcional < 0 ? cs.error : null,
            ),
            const SizedBox(height: 6),
            Text(
              ritmoTxt,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ritmoColor),
            ),

            const Divider(height: 24),

            _kpiRow('Receitas ($mesLabel)', formatBRL(receitasPeriodo)),
            const SizedBox(height: 8),
            _kpiRow('Despesas ($mesLabel)', formatBRL(despesasPeriodo)),
            const SizedBox(height: 8),
            _kpiRow(
              'Saldo caixa ($mesLabel)',
              formatBRL(caixaPeriodo),
              valueColor: caixaPeriodo < 0 ? cs.error : null,
            ),

            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.15,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = groupIndex + 1;
                        final isReceita = rodIndex == 0;
                        final value = isReceita
                            ? receitasMes[groupIndex]
                            : despesasMes[groupIndex];
                        final label = isReceita ? 'Receitas' : 'Despesas';
                        return BarTooltipItem(
                          'Mês $month\n$label: ${formatBRL(value)}',
                          const TextStyle(fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i > 11) return const SizedBox.shrink();
                          const labels = [
                            'Jan','Fev','Mar','Abr','Mai','Jun',
                            'Jul','Ago','Set','Out','Nov','Dez'
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[i],
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 6,
                      barRods: [
                        BarChartRodData(
                          toY: receitasMes[i],
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: cs.primary,
                        ),
                        BarChartRodData(
                          toY: despesasMes[i],
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: cs.error,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}

/// ----------------------
/// TELA DE LANÇAMENTO (Novo + Editar)
/// ----------------------
class LancamentoPage extends StatefulWidget {
  final int year;
  final Map<String, dynamic>? lancamento;
  final List<String> categorias;

  const LancamentoPage({
    super.key,
    required this.year,
    required this.categorias,
    this.lancamento,
  });

  @override
  State<LancamentoPage> createState() => _LancamentoPageState();
}

class _LancamentoPageState extends State<LancamentoPage> {
  final supabase = Supabase.instance.client;

  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _tipo = 'R';
  String _categoria = 'Geral';
  DateTime _data = DateTime.now();

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.lancamento != null;

  @override
  void initState() {
    super.initState();

    final cats = widget.categorias.isNotEmpty
        ? widget.categorias
        : const ['Geral', 'Outros'];

    if (_isEdit) {
      final l = widget.lancamento!;
      final valor = (l['valor'] as num?)?.toDouble() ?? 0.0;
      final desc = (l['descricao'] ?? '').toString();
      final dataStr = (l['data'] ?? '').toString();
      final tipo = (l['tipo'] ?? 'R').toString();
      final cat = (l['categoria'] ?? 'Geral').toString();

      _tipo = (tipo == 'D') ? 'D' : 'R';
      _categoria = cats.contains(cat)
          ? cat
          : (cats.contains('Outros') ? 'Outros' : cats.first);

      _valorCtrl.text = _toBrMoney(valor);
      _descCtrl.text = desc;

      final parts = dataStr.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? widget.year;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        _data = DateTime(y, m, d);
      } else {
        _data = DateTime(widget.year, 1, 1);
      }
    } else {
      if (_data.year != widget.year) _data = DateTime(widget.year, 1, 1);
      _categoria = cats.contains('Geral') ? 'Geral' : cats.first;
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  double _parseMoneyToDouble(String input) {
    var s = input.trim().replaceAll(' ', '');
    if (s.isEmpty) return 0;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '');
        s = s.replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }

    return double.tryParse(s) ?? 0;
  }

  String _toBrMoney(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final pos = intPart.length - i;
      buf.write(intPart[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()},$decPart';
  }

  Future<void> _salvar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final valor = _parseMoneyToDouble(_valorCtrl.text);
      if (valor <= 0) throw Exception('Informe um valor maior que zero.');
      if (_data.year != widget.year) {
        throw Exception('A data precisa estar dentro do ano ${widget.year}.');
      }

      final payload = {
        'data': _formatDate(_data),
        'valor': valor,
        'descricao': _descCtrl.text.trim(),
        'tipo': _tipo,
        'categoria': _categoria,
      };

      if (_isEdit) {
        final id = widget.lancamento!['id'];
        await supabase
            .from('receitas')
            .update(payload)
            .eq('id', id)
            .eq('user_id', user.id);
      } else {
        await supabase.from('receitas').insert({
          'user_id': user.id,
          ...payload,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(widget.year, 1, 1),
      lastDate: DateTime(widget.year, 12, 31),
    );
    if (picked != null) setState(() => _data = picked);
  }

  Future<void> _excluir() async {
    if (!_isEdit) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir lançamento?'),
            content: const Text('Essa ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final id = widget.lancamento!['id'];
      await supabase.from('receitas').delete().eq('id', id).eq('user_id', user.id);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao excluir: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = '${_data.day.toString().padLeft(2, '0')}/'
        '${_data.month.toString().padLeft(2, '0')}/'
        '${_data.year}';

    final cats = widget.categorias.isNotEmpty ? widget.categorias : const ['Geral', 'Outros'];

    if (!cats.contains(_categoria)) {
      _categoria = cats.contains('Geral') ? 'Geral' : cats.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar lançamento' : 'Novo lançamento'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _loading ? null : _excluir,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(dateText),
              trailing: TextButton(
                onPressed: _loading ? null : _pickDate,
                child: const Text('Alterar'),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipo,
              items: const [
                DropdownMenuItem(value: 'R', child: Text('Receita')),
                DropdownMenuItem(value: 'D', child: Text('Despesa')),
              ],
              onChanged: _loading ? null : (v) => setState(() => _tipo = v ?? 'R'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoria,
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _loading ? null : (v) => setState(() => _categoria = v ?? cats.first),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [BrCurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: 'Ex: 1.500,00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              enableSuggestions: true,
              autocorrect: true,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                child: Text(_loading ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final raw = int.parse(digits);
    final cents = raw % 100;
    final whole = raw ~/ 100;

    final wholeStr = whole.toString();
    final buf = StringBuffer();
    for (int i = 0; i < wholeStr.length; i++) {
      final pos = wholeStr.length - i;
      buf.write(wholeStr[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }

    final text = '${buf.toString()},${cents.toString().padLeft(2, '0')}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

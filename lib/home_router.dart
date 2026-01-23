import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/lancamento.dart';
import 'models/settings_model.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/export_service.dart';
import 'services/categories_service.dart';
import 'widgets/home_components.dart';
import 'onboarding_page.dart';
import 'categories_page.dart';
import 'pages/lancamento_page.dart';

enum SortMode { dateDesc, dateAsc, valueDesc, valueAsc }

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  final supabase = Supabase.instance.client;
  final SupabaseService _svc = SupabaseService();
  final NotificationService _notifSvc = NotificationService();
  final CategoriesService _catsSvc = CategoriesService();
  final ExportService _exportSvc = ExportService();

  bool _loading = true;
  String? _error;
  SettingsModel? _settings;

  int? _mesSelecionado;
  List<Lancamento> _lancamentos = [];

  // filtros
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _tipoFiltro = 'T';
  String? _categoriaFiltro;
  SortMode _sortMode = SortMode.dateDesc;

  List<String> _categorias = const [];

  // estatísticas
  double _totalReceitasAno = 0.0;
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
      if (v != _search && mounted) setState(() => _search = v);
    });

    _initAll();
  }

  Future<void> _initAll() async {
    await _notifSvc.init();
    await _loadCategories();
    await _loadAll();
  }

  Future<void> _loadCategories() async {
    _categorias = await _catsSvc.loadCategories();
    if (_categoriaFiltro != null && !_categorias.contains(_categoriaFiltro)) {
      _categoriaFiltro = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Usuário não autenticado.';
        _settings = null;
        _lancamentos = [];
      });
      return;
    }

    try {
      final s = await _svc.getSettingsForUser(user.id);
      if (s == null) {
        // sem settings => onboarding
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

      _settings = s;

      final year = s.year;
      final range = _mesSelecionado == null
          ? DateTimeRange(start: DateTime(year, 1, 1), end: DateTime(year + 1, 1, 1))
          : DateTimeRange(start: DateTime(year, _mesSelecionado!, 1), end: _mesSelecionado == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, _mesSelecionado! + 1, 1));

      final totalAno = await _svc.getTotalReceitasAno(user.id, year);
      final fluxo = await _svc.getFluxoPorMes(user.id, year);
      final lanc = await _svc.getReceitasInRange(user.id, range.start, range.end);

      // calcular resumo simples
      double totalReceitasPeriodo = 0.0;
      double totalDespesasPeriodo = 0.0;
      for (final l in lanc) {
        if (l.tipo == 'D') totalDespesasPeriodo += l.valor;
        else totalReceitasPeriodo += l.valor;
      }

      final receitasMes = List<double>.filled(12, 0.0);
      final despesasMes = List<double>.filled(12, 0.0);
      for (final f in fluxo) {
        if (f.month >= 1 && f.month <= 12) {
          receitasMes[f.month - 1] = f.receitas;
          despesasMes[f.month - 1] = f.despesas;
        }
      }

      // atualizar estado
      if (!mounted) return;
      setState(() {
        _totalReceitasAno = totalAno;
        _receitasMes = receitasMes;
        _despesasMes = despesasMes;
        _lancamentos = lanc;
        _totalReceitasPeriodo = totalReceitasPeriodo;
        _totalDespesasPeriodo = totalDespesasPeriodo;
        _loading = false;
      });

      // notificação se necessário
      await _notifSvc.maybeNotifyLimit(
        year: year,
        limitAnual: s.annualLimit,
        totalReceitasAno: totalAno,
        settingsId: s.userId,
        supabaseService: _svc,
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
    try {
      final filePath = await _exportSvc.exportCsv(
        lancamentos: _applyFiltersAndSort(_lancamentos),
        settings: _settings!,
        mesSelecionado: _mesSelecionado,
      );
      await _exportSvc.shareFile(filePath, context: context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar CSV: $e')));
    }
  }

  List<Lancamento> _applyFiltersAndSort(List<Lancamento> base) {
    final q = _search.trim().toLowerCase();
    final filtered = base.where((r) {
      if (_tipoFiltro != 'T' && r.tipo != _tipoFiltro) return false;
      if (_categoriaFiltro != null && r.categoria != _categoriaFiltro) return false;
      if (q.isNotEmpty) {
        final hay = '${r.categoria} ${r.descricao} ${r.data}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    int compareDate(Lancamento a, Lancamento b) => a.data.compareTo(b.data);
    int compareValue(Lancamento a, Lancamento b) => a.valor.compareTo(b.valor);

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

  Map<String, double> _calcResumoFrom(List<Lancamento> list) {
    double r = 0.0;
    double d = 0.0;
    for (final row in list) {
      if (row.tipo == 'D') d += row.valor;
      else r += row.valor;
    }
    return {'receitas': r, 'despesas': d, 'saldo': r - d};
  }

  void _clearFilters() {
    setState(() {
      _tipoFiltro = 'T';
      _categoriaFiltro = null;
      _sortMode = SortMode.dateDesc;
    });
    _searchCtrl.clear();
  }

  Future<void> _openSettings() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OnboardingPage()));
    if (changed == true) await _loadAll();
  }

  Future<void> _openCategories() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
    await _loadCategories();
  }

  Future<void> _deleteById(dynamic id) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await _svc.deleteLancamentoById(id, user.id);
    await _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final now = DateTime.now();

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Limite MEI')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadAll, child: const Text('Tentar novamente')),
          ]),
        ),
      );
    }
    if (_settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final year = _settings!.year;
    final labelMes = _mesSelecionado == null ? 'Todos' : _mesesShort[_mesSelecionado!];

    final filtered = _applyFiltersAndSort(_lancamentos);
    final resumoFiltros = _calcResumoFrom(filtered);
    final filtrosAtivos = _search.trim().isNotEmpty || _tipoFiltro != 'T' || _categoriaFiltro != null || _sortMode != SortMode.dateDesc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limite MEI'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportarCsv),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'cats') await _openCategories();
              if (v == 'settings') await _openSettings();
              if (v == 'logout') {
                await supabase.auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              }
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
          final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => LancamentoPage(year: year, categorias: _categorias)));
          if (saved == true) await _loadAll();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Olá, ${user?.email ?? ''}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ResumoCard(
              now: now,
              year: year,
              mesLabel: labelMes,
              limiteAnual: _settings!.annualLimit,
              totalReceitasAno: _totalReceitasAno,
              saldoAnualLimite: _settings!.annualLimit - _totalReceitasAno,
              receitasPeriodo: _totalReceitasPeriodo,
              despesasPeriodo: _totalDespesasPeriodo,
              receitasMes: _receitasMes,
              despesasMes: _despesasMes,
              formatBRL: (v) => _svc.formatBRL(v),
            ),
            const SizedBox(height: 12),
            // ... filtros e lista delegados para widgets
            FiltersCard(
              searchCtrl: _searchCtrl,
              tipoFiltro: _tipoFiltro,
              onTipoChanged: (t) => setState(() => _tipoFiltro = t),
              categorias: _categorias,
              categoriaFiltro: _categoriaFiltro,
              onCategoriaChanged: (c) => setState(() => _categoriaFiltro = c),
              sortMode: _sortMode,
              onSortChanged: (s) => setState(() => _sortMode = s),
              onClear: _clearFilters,
            ),
            const SizedBox(height: 12),
            if (filtrosAtivos) ResumoFiltrosCard(count: filtered.length, receitas: resumoFiltros['receitas']!, despesas: resumoFiltros['despesas']!, saldo: resumoFiltros['saldo']!, formatBRL: (v) => _svc.formatBRL(v)),
            if (filtrosAtivos) const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Lançamentos ($year - $labelMes)', style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: _loadAll, child: const Text('Atualizar')),
            ]),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: Text('Nenhum lançamento com os filtros atuais.')))
            else
              ...filtered.map((r) => LancamentoItem(
                lancamento: r,
                onEdit: () async {
                  // abrir edição - reutilize LancamentoPage
                  final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => LancamentoPage(year: year, categorias: _categorias, lancamento: r)));
                  if (saved == true) await _loadAll();
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Excluir lançamento?'), content: const Text('Essa ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
                  if (confirm == true) await _deleteById(r.id);
                },
              )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
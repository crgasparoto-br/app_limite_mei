import 'package:flutter/material.dart';

import '../data/services/alert_service.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/usecases/get_dashboard_usecase.dart';
import '../presentation/widgets/premium_purchase_flow.dart';
import '../service_locator.dart';
import 'add_receita_page.dart';
import 'comparativos_page.dart';
import 'configuracoes_page.dart';
import 'receitas_page.dart';
import 'relatorio_mensal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GetDashboardUseCase _getDashboard;
  late SettingsRepository _settingsRepo;
  late AlertService _alertService;

  DashboardData? _dashboardData;
  bool _loading = true;
  int _anoSelecionado = DateTime.now().year;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _getDashboard = getIt<GetDashboardUseCase>();
    _settingsRepo = getIt<SettingsRepository>();
    _alertService = getIt<AlertService>();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final entitlementsRepo = getIt<EntitlementsRepository>();
    final isPremium = await entitlementsRepo.isPremiumActive();
    final anoSelecionado = await _settingsRepo.getSelectedYear();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _anoSelecionado = anoSelecionado;
      });
    }
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final entitlementsRepo = getIt<EntitlementsRepository>();
      final isPremium = await entitlementsRepo.isPremiumActive();
      final settings = await _settingsRepo.getSettings();
      final data = await _getDashboard();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _dashboardData = data;
          _loading = false;
        });
        await _showInAppAlertsIfNeeded(
          data: data,
          alertasAtivos: settings.alertasAtivos,
          isPremium: isPremium,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _showInAppAlertsIfNeeded({
    required DashboardData data,
    required Map<int, bool> alertasAtivos,
    required bool isPremium,
  }) async {
    final pendingThresholds = _alertService.evaluateConfiguredThresholds(
      data.percentual,
      alertasAtivos,
      isPremium,
      data.year,
    );

    if (pendingThresholds.isEmpty || !mounted) return;

    pendingThresholds.sort();
    final threshold = pendingThresholds.last;

    for (final value in pendingThresholds) {
      await _alertService.markAlertAsSent(value, data.year);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_buildAlertTitle(threshold, data)),
            content: Text(_buildAlertMessage(threshold, data)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
    });
  }

  String _buildAlertTitle(int threshold, DashboardData data) {
    if (threshold >= 100 || data.percentual >= 1.0) {
      return 'Limite anual atingido';
    }
    return 'Alerta de limite';
  }

  String _buildAlertMessage(int threshold, DashboardData data) {
    final percentual = (data.percentual * 100).toStringAsFixed(1);
    if (threshold >= 100 || data.percentual >= 1.0) {
      return 'Limite atingido: você chegou a $percentual% do limite anual.';
    }
    return 'Alerta de limite: você chegou a $percentual% do limite anual e cruzou o aviso de $threshold%.';
  }

  Future<void> _adicionarReceita() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddReceitaPage()),
    );

    if (result == true) {
      await _loadDashboard();
    }
  }

  Future<void> _selecionarAno(int ano) async {
    if (!_isPremium && ano != DateTime.now().year) {
      _showAnosAnterioresPaywall();
      return;
    }

    await _settingsRepo.setSelectedYear(ano);
    setState(() {
      _anoSelecionado = ano;
      _loading = true;
    });
    await _loadDashboard();
  }

  void _showAnosAnterioresPaywall() {
    showPremiumPaywallFlow(
      context,
      title: 'Histórico de anos anteriores',
      subtitle:
          'Escolha um plano para acessar o histórico completo e configurar limites por ano.',
      onSuccess: _loadDashboard,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'ALERTA_70':
        return Colors.green.shade800;
      case 'ALERTA_80':
        return Colors.yellow.shade700;
      case 'ALERTA_90':
        return Colors.orange;
      case 'ALERTA_95':
        return Colors.red;
      case 'LIMITE_ESTOURADO':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getStatusTexto(String status, double percentual) {
    final percentualInt = (percentual * 100).round();

    switch (status) {
      case 'OK':
        return 'Tudo certo';
      case 'ALERTA_70':
        return 'Informativo: $percentualInt% utilizado';
      case 'ALERTA_80':
        return 'Atenção: $percentualInt% utilizado';
      case 'ALERTA_90':
        return 'Alerta: $percentualInt% utilizado';
      case 'ALERTA_95':
        return 'Crítico: $percentualInt% utilizado';
      case 'LIMITE_ESTOURADO':
        return 'LIMITE ESTOURADO!';
      default:
        return 'Status desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limite MEI'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _isPremium
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<int>(
                      value: _anoSelecionado,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      underline: Container(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                      ),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      items: List.generate(5, (i) {
                        final ano = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: ano,
                          child: Text(ano.toString()),
                        );
                      }),
                      onChanged: (ano) {
                        if (ano != null) _selecionarAno(ano);
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: _showAnosAnterioresPaywall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateTime.now().year.toString(),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardData == null
              ? const Center(child: Text('Erro ao carregar dados'))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildResumoCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final data = _dashboardData!;
    final percentual = data.percentual;
    final status = data.status;
    final statusColor = _getStatusColor(status);
    final statusTexto = _getStatusTexto(status, percentual);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentual.clamp(0, 1),
                    minHeight: 16,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
                Text(
                  '${(percentual * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              statusTexto,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('Total ano', _formatCurrency(data.totalAno)),
                _buildDetailItem('Limite', _formatCurrency(data.limite)),
                _buildDetailItem('Restante', _formatCurrency(data.restante)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildResumoCard() {
    final data = _dashboardData!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Este mês',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatCurrency(data.totalMes),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lançamentos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${data.countReceitas}${data.isPremium ? '' : '/120'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final data = _dashboardData!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: data.canAddMore
                  ? const LinearGradient(
                      colors: [Color(0xFF0b798b), Color(0xFF0d96ab)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: data.canAddMore ? null : Colors.grey,
              borderRadius: BorderRadius.circular(8),
              boxShadow: data.canAddMore
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0b798b).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton.icon(
              onPressed:
                  data.canAddMore ? _adicionarReceita : _showReceitaLimitPaywall,
              icon: const Icon(Icons.add_circle, size: 28),
              label: const Text(
                '+ Nova Receita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReceitasPage()),
                  );
                  await _loadInitialData();
                },
                icon: const Icon(Icons.list),
                label: const Text('Receitas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracoesPage(),
                    ),
                  );
                  await _loadInitialData();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurações'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_isPremium) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RelatorioMensalPage(),
                      ),
                    );
                  } else {
                    showPremiumPaywallFlow(
                      context,
                      title: 'Liberar relatório mensal',
                      subtitle:
                          'Veja seu faturamento por mês com mais profundidade e mais clareza.',
                      onSuccess: _loadDashboard,
                    );
                  }
                },
                icon: Icon(
                  Icons.analytics,
                  color: _isPremium ? Colors.blue : Colors.grey,
                ),
                label: Text(
                  'Relatório',
                  style: TextStyle(
                    color: _isPremium ? Colors.blue : Colors.grey,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isPremium ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_isPremium) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComparativosPage(),
                      ),
                    );
                  } else {
                    showPremiumPaywallFlow(
                      context,
                      title: 'Liberar comparativos',
                      subtitle:
                          'Compare meses, anos e acompanhe seu ritmo de faturamento.',
                      onSuccess: _loadDashboard,
                    );
                  }
                },
                icon: Icon(
                  Icons.compare_arrows,
                  color: _isPremium ? Colors.purple : Colors.grey,
                ),
                label: Text(
                  'Comparar',
                  style: TextStyle(
                    color: _isPremium ? Colors.purple : Colors.grey,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isPremium ? Colors.purple : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showReceitaLimitPaywall() {
    showPremiumPaywallFlow(
      context,
      title: 'Limite de lançamentos atingido',
      subtitle:
          'Você já registrou 120 receitas. Escolha um plano para continuar lançando sem limite.',
      onSuccess: _loadDashboard,
    );
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = int.parse(parts[0]);
    final intFormatted = intPart.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $intFormatted,${parts[1]}';
  }
}

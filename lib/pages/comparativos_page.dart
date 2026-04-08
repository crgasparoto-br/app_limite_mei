import 'package:flutter/material.dart';

import '../domain/entities/comparativo_mensal.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../domain/usecases/get_comparativos_usecase.dart';
import '../presentation/widgets/paywall_dialog.dart';
import '../service_locator.dart';

class ComparativosPage extends StatefulWidget {
  const ComparativosPage({super.key});

  @override
  State<ComparativosPage> createState() => _ComparativosPageState();
}

class _ComparativosPageState extends State<ComparativosPage>
    with SingleTickerProviderStateMixin {
  late GetComparativosUseCase _getComparativos;
  late EntitlementsRepository _entitlementsRepo;
  late TabController _tabController;

  bool _loading = true;
  bool _isPremium = false;

  ComparativoMensal? _comparativoMensal;
  ComparativoAnual? _comparativoAnual;
  MetaRitmo? _metaRitmo;

  final int _anoSelecionado = DateTime.now().year;
  int _mesSelecionado = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getComparativos = getIt<GetComparativosUseCase>();
    _entitlementsRepo = getIt<EntitlementsRepository>();
    _checkPremiumAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPremiumAndLoad() async {
    final isPremium = await _entitlementsRepo.isPremiumActive();

    if (!isPremium) {
      _showPaywall();
      return;
    }

    setState(() => _isPremium = true);
    await _loadComparativos();
  }

  Future<void> _loadComparativos() async {
    setState(() => _loading = true);

    try {
      final comparativoMensal = await _getComparativos.compararMeses(
        _anoSelecionado,
        _mesSelecionado,
      );
      final comparativoAnual = await _getComparativos.compararAnos(
        _anoSelecionado,
      );
      final metaRitmo = await _getComparativos.getMetaRitmo(_anoSelecionado);

      if (!mounted) return;
      setState(() {
        _comparativoMensal = comparativoMensal;
        _comparativoAnual = comparativoAnual;
        _metaRitmo = metaRitmo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _showPaywall() {
    showPaywall(
      context,
      title: 'Comparativos - Premium',
      subtitle: 'Compare meses, anos e acompanhe seu ritmo de faturamento!',
      onUpgrade: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
      onRestore: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _selecionarMes() async {
    final mes = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Selecionar mês',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...List.generate(12, (index) {
                final value = index + 1;
                return ListTile(
                  title: Text(_getNomeMes(value)),
                  trailing: value == _mesSelecionado
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.pop(context, value),
                );
              }),
            ],
          ),
        );
      },
    );

    if (mes == null || mes == _mesSelecionado) return;

    setState(() => _mesSelecionado = mes);
    await _loadComparativos();
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

  String _getNomeMes(int mes) {
    const meses = [
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
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPremium) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparativos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meses'),
            Tab(text: 'Anos'),
            Tab(text: 'Ritmo'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComparativoMensal(),
                _buildComparativoAnual(),
                _buildMetaRitmo(),
              ],
            ),
    );
  }

  Widget _buildComparativoMensal() {
    if (_comparativoMensal == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final comp = _comparativoMensal!;
    final isPositivo = comp.isPositivo;
    final corFundo = isPositivo ? Colors.green.shade50 : Colors.red.shade50;
    final corTexto = isPositivo ? Colors.green.shade800 : Colors.red.shade800;
    final seta = isPositivo ? '↑' : '↓';

    return RefreshIndicator(
      onRefresh: _loadComparativos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text('${_getNomeMes(_mesSelecionado)}/$_anoSelecionado'),
              trailing: const Icon(Icons.edit),
              onTap: _selecionarMes,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: corFundo,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '$seta ${_formatCurrency(comp.delta.abs())}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comp.temComparacao
                        ? '${isPositivo ? '+' : ''}${comp.deltaPorcentagem.toStringAsFixed(1)}%'
                        : 'Novo faturamento',
                    style: TextStyle(
                      fontSize: 20,
                      color: corTexto,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    comp.temComparacao
                        ? 'Você faturou ${_formatCurrency(comp.delta.abs())} ${isPositivo ? 'a mais' : 'a menos'} que no mês anterior'
                        : 'Este é o primeiro mês com lançamentos',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildLinhaComparativo(
                    '${_getNomeMes(comp.mesBase)}/${comp.anoBase}',
                    _formatCurrency(comp.totalBase),
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildLinhaComparativo(
                    '${_getNomeMes(comp.mesComparado)}/${comp.anoComparado}',
                    _formatCurrency(comp.totalComparado),
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativoAnual() {
    if (_comparativoAnual == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final comp = _comparativoAnual!;
    final isPositivo = comp.isPositivo;
    final corFundo = isPositivo ? Colors.green.shade50 : Colors.red.shade50;
    final corTexto = isPositivo ? Colors.green.shade800 : Colors.red.shade800;
    final seta = isPositivo ? '↑' : '↓';

    return RefreshIndicator(
      onRefresh: _loadComparativos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: corFundo,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '$seta ${_formatCurrency(comp.delta.abs())}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comp.totalAnoAnterior > 0
                        ? '${isPositivo ? '+' : ''}${comp.deltaPorcentagem.toStringAsFixed(1)}%'
                        : 'Primeiro ano',
                    style: TextStyle(
                      fontSize: 20,
                      color: corTexto,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${comp.anoBase} vs ${comp.anoAnterior}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Por mês',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  ...List.generate(12, (index) {
                    final mes = index + 1;
                    final compMes = comp.comparativoPorMes[mes];
                    if (compMes == null) return const SizedBox.shrink();

                    final deltaMes = compMes.delta;
                    final setaMes = deltaMes >= 0 ? '↑' : '↓';
                    final corMes = deltaMes >= 0 ? Colors.green : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              _getNomeMes(mes),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_formatCurrency(compMes.totalBase)} vs ${_formatCurrency(compMes.totalAnterior)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '$setaMes ${_formatCurrency(deltaMes.abs())}',
                            style: TextStyle(
                              color: corMes,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRitmo() {
    if (_metaRitmo == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final meta = _metaRitmo!;
    final cor = meta.acimaDoRitmo ? Colors.orange : Colors.green;
    final corFundo = meta.acimaDoRitmo
        ? Colors.orange.shade50
        : Colors.green.shade50;
    final statusTexto = meta.acimaDoRitmo
        ? 'Acima do ritmo ideal'
        : 'Dentro do ritmo ideal';

    return RefreshIndicator(
      onRefresh: _loadComparativos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: corFundo,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    meta.acimaDoRitmo ? Icons.trending_up : Icons.check_circle,
                    size: 64,
                    color: cor.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    statusTexto,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: meta.acimaDoRitmo
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Análise',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildLinhaComparativo(
                    'Média ideal/mês',
                    _formatCurrency(meta.mediaIdeal),
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildLinhaComparativo(
                    'Sua média atual',
                    _formatCurrency(meta.mediaAtual),
                    cor,
                  ),
                  const SizedBox(height: 12),
                  _buildLinhaComparativo(
                    'Diferença mensal',
                    _formatCurrency(meta.diferencaMensal.abs()),
                    meta.diferencaMensal >= 0 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explicação',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para não estourar o limite de ${_formatCurrency(meta.limiteAnual)} em $_anoSelecionado, você precisa faturar em média ${_formatCurrency(meta.mediaIdeal)} por mês.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meta.acimaDoRitmo
                        ? 'Você está faturando ${_formatCurrency(meta.mediaAtual)} por mês (${meta.porcentagemDoRitmo.toStringAsFixed(0)}% do ritmo ideal). Considere reduzir o ritmo nos próximos meses para não estourar o limite.'
                        : 'Você está faturando ${_formatCurrency(meta.mediaAtual)} por mês (${meta.porcentagemDoRitmo.toStringAsFixed(0)}% do ritmo ideal). Continue neste ritmo para ficar dentro do limite!',
                    style: TextStyle(
                      fontSize: 14,
                      color: cor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaComparativo(String label, String valor, Color cor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

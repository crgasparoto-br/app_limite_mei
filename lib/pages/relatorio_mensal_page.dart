import 'package:flutter/material.dart';
import '../domain/entities/relatorio_mensal.dart';
import '../domain/usecases/get_relatorio_mensal_usecase.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../service_locator.dart';
import '../presentation/widgets/paywall_dialog.dart';
import '../utils/date_formatters.dart';

class RelatorioMensalPage extends StatefulWidget {
  const RelatorioMensalPage({super.key});

  @override
  State<RelatorioMensalPage> createState() => _RelatorioMensalPageState();
}

class _RelatorioMensalPageState extends State<RelatorioMensalPage> {
  late GetRelatorioMensalUseCase _getRelatorio;
  late EntitlementsRepository _entitlementsRepo;

  RelatorioMensal? _relatorio;
  bool _loading = true;
  bool _isPremium = false;

  int _anoSelecionado = DateTime.now().year;
  int _mesSelecionado = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _getRelatorio = getIt<GetRelatorioMensalUseCase>();
    _entitlementsRepo = getIt<EntitlementsRepository>();
    _checkPremiumAndLoad();
  }

  Future<void> _checkPremiumAndLoad() async {
    final isPremium = await _entitlementsRepo.isPremiumActive();

    if (!isPremium) {
      _showPaywall();
      return;
    }

    setState(() => _isPremium = true);
    await _loadRelatorio();
  }

  Future<void> _loadRelatorio() async {
    setState(() => _loading = true);

    try {
      final relatorio = await _getRelatorio(_anoSelecionado, _mesSelecionado);
      if (mounted) {
        setState(() {
          _relatorio = relatorio;
          _loading = false;
        });
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

  void _showPaywall() {
    showPaywall(
      context,
      title: 'Relatório Mensal - Premium',
      subtitle: 'Entenda seu faturamento por mês + análise de semanas e dias!',
      onUpgrade: () {
        Navigator.pop(context);
        Navigator.pop(context); // Volta para tela anterior
      },
      onRestore: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
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

  String _getNomeMes(int mes) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Junho',
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
        title: const Text('Relatório Mensal'),
        actions: [
          // Seletor de Mês/Ano
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: '$_anoSelecionado-$_mesSelecionado',
                dropdownColor: Theme.of(context).colorScheme.surface,
                underline: Container(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                items: _buildMesAnoItems(),
                onChanged: (value) {
                  if (value != null) {
                    final parts = value.split('-');
                    setState(() {
                      _anoSelecionado = int.parse(parts[0]);
                      _mesSelecionado = int.parse(parts[1]);
                    });
                    _loadRelatorio();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _relatorio == null
          ? const Center(child: Text('Erro ao carregar relatório'))
          : RefreshIndicator(
              onRefresh: _loadRelatorio,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Título do mês
                  Text(
                    '${_getNomeMes(_mesSelecionado)} de $_anoSelecionado',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cards principais
                  _buildCardsResumo(),
                  const SizedBox(height: 24),

                  // Seção por semana
                  _buildSecaoPorSemana(),
                  const SizedBox(height: 24),

                  // Top 5 dias
                  _buildTop5Dias(),
                ],
              ),
            ),
    );
  }

  List<DropdownMenuItem<String>> _buildMesAnoItems() {
    final items = <DropdownMenuItem<String>>[];
    final now = DateTime.now();

    // Últimos 12 meses
    for (int i = 0; i < 12; i++) {
      final data = DateTime(now.year, now.month - i, 1);
      items.add(
        DropdownMenuItem(
          value: '${data.year}-${data.month}',
          child: Text('${_getNomeMes(data.month)}/${data.year}'),
        ),
      );
    }

    return items;
  }

  Widget _buildCardsResumo() {
    final relatorio = _relatorio!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardInfo(
                'Total do Mês',
                _formatCurrency(relatorio.totalMes),
                Icons.attach_money,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInfo(
                'Lançamentos',
                relatorio.qtdLancamentos.toString(),
                Icons.receipt_long,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardInfo(
                'Média/Lançamento',
                _formatCurrency(relatorio.mediaPorLancamento),
                Icons.show_chart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardInfo(
                'Maior Lançamento',
                _formatCurrency(relatorio.maiorLancamento),
                Icons.star,
                Colors.purple,
              ),
            ),
          ],
        ),
        if (relatorio.dataMaiorLancamento != null) ...[
          const SizedBox(height: 8),
          Text(
            'Maior lançamento em ${DateFormatters.date(relatorio.dataMaiorLancamento!)}',

            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
        if (relatorio.diaDePico != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏆 Dia de Pico',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormatters.date(relatorio.diaDePico!.data)} - ${_formatCurrency(relatorio.diaDePico!.total)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Text(
                          '${relatorio.diaDePico!.qtdLancamentos} lançamento(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardInfo(String label, String valor, IconData icon, Color cor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoPorSemana() {
    final relatorio = _relatorio!;

    if (relatorio.totalPorSemana.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxTotal = relatorio.totalPorSemana.values.isEmpty
        ? 0.0
        : relatorio.totalPorSemana.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por Semana',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final semana = index + 1;
              final total = relatorio.totalPorSemana[semana] ?? 0;
              final percentual = maxTotal > 0
                  ? (total / maxTotal).toDouble()
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Semana $semana'),
                        Text(
                          _formatCurrency(total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentual,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.blue.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTop5Dias() {
    final relatorio = _relatorio!;

    if (relatorio.top5Dias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Dias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...relatorio.top5Dias.asMap().entries.map((entry) {
              final index = entry.key;
              final dia = entry.value;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.amber
                      : Colors.blue.shade100,
                  child: Text(
                    '${index + 1}º',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.black : Colors.blue.shade900,
                    ),
                  ),
                ),
                title: Text(
                  DateFormatters.date(dia.data),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${dia.qtdLancamentos} lançamento(s)'),
                trailing: Text(
                  _formatCurrency(dia.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../domain/entities/receita.dart';
import '../domain/repositories/receita_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../service_locator.dart';
import '../presentation/widgets/paywall_dialog.dart';
import 'edit_receita_page.dart';

class ReceitasPage extends StatefulWidget {
  const ReceitasPage({super.key});

  @override
  State<ReceitasPage> createState() => _ReceitasPageState();
}

class _ReceitasPageState extends State<ReceitasPage> {
  late ReceitaRepository _receitaRepo;
  late SettingsRepository _settingsRepo;
  late EntitlementsRepository _entitlementsRepo;

  List<Receita> _receitas = [];
  List<Receita> _receitasFiltradas = [];
  bool _loading = true;
  bool _isPremium = false;
  int? _mesFiltro; // null = todos os meses
  int _anoSelecionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _receitaRepo = getIt<ReceitaRepository>();
    _settingsRepo = getIt<SettingsRepository>();
    _entitlementsRepo = getIt<EntitlementsRepository>();
    _loadReceitas();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await _entitlementsRepo.isPremiumActive();
    final anoSelecionado = await _settingsRepo.getSelectedYear();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _anoSelecionado = anoSelecionado;
      });
    }
  }

  Future<void> _loadReceitas() async {
    try {
      final year = await _settingsRepo.getSelectedYear();
      final receitas = await _receitaRepo.getReceitasByYear(year);
      // Ordenar por data descendente
      receitas.sort((a, b) => b.data.compareTo(a.data));

      if (mounted) {
        setState(() {
          _receitas = receitas;
          _aplicarFiltro();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _aplicarFiltro() {
    if (_mesFiltro == null) {
      _receitasFiltradas = List.from(_receitas);
    } else {
      _receitasFiltradas = _receitas.where((r) => r.data.month == _mesFiltro).toList();
    }
  }

  void _selecionarMes(int? mes) {
    if (!_isPremium && mes != null) {
      _showFiltroPaywall();
      return;
    }

    setState(() {
      _mesFiltro = mes;
      _aplicarFiltro();
    });
  }

  void _showFiltroPaywall() {
    showPaywall(
      context,
      title: 'Filtro por Mês - Premium',
      subtitle: 'Filtre suas receitas por mês e tenha mais controle sobre seus lançamentos!',
      onUpgrade: () {
        Navigator.pop(context);
        // TODO: Navegar para tela de compra ou ativar premium
      },
    );
  }

  Future<void> _selecionarAno(int ano) async {
    if (!_isPremium && ano != DateTime.now().year) {
      _showAnoPaywall();
      return;
    }

    await _settingsRepo.setSelectedYear(ano);
    setState(() {
      _anoSelecionado = ano;
      _loading = true;
      _mesFiltro = null; // Resetar filtro de mês ao trocar ano
    });
    await _loadReceitas();
  }

  void _showAnoPaywall() {
    showPaywall(
      context,
      title: 'Histórico de Anos Anteriores',
      subtitle: 'Acesse o histórico completo de todos os anos!',
      onUpgrade: () {
        Navigator.pop(context);
        // TODO: Navegar para tela de compra ou ativar premium
      },
    );
  }

  Future<void> _deletarReceita(String id) async {
    try {
      await _receitaRepo.deleteReceita(id);
      await _loadReceitas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _editarReceita(Receita receita) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReceitaPage(receita: receita),
      ),
    );

    if (result == true) {
      await _loadReceitas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receita atualizada com sucesso')),
        );
      }
    }
  }

  void _exportarReceitas() {
    if (!_isPremium) {
      _showExportPaywall();
      return;
    }

    // TODO: Implementar exportação CSV/PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Funcionalidade de exportação em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showExportPaywall() {
    showPaywall(
      context,
      title: 'Exportação Premium',
      subtitle: 'Exporte suas receitas em CSV ou PDF para enviar ao contador!',
      onUpgrade: () {
        Navigator.pop(context);
        // TODO: Navegar para tela de compra ou ativar premium
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

  @override
  Widget build(BuildContext context) {
    final anoAtual = DateTime.now().year;
    final anosDisponiveis = List.generate(5, (i) => anoAtual - i);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          // Seletor de Ano
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: _isPremium
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<int>(
                      value: _anoSelecionado,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      items: anosDisponiveis.map((ano) {
                        return DropdownMenuItem(
                          value: ano,
                          child: Text(ano.toString()),
                        );
                      }).toList(),
                      onChanged: (ano) {
                        if (ano != null) _selecionarAno(ano);
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: _showAnoPaywall,
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
                            _anoSelecionado.toString(),
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
          // Botão de exportar
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: _isPremium ? Colors.blue : Colors.grey,
            ),
            tooltip: _isPremium ? 'Exportar' : 'Exportar (Premium)',
            onPressed: _exportarReceitas,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtro por mês
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: _isPremium ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: _mesFiltro,
                          hint: Text(
                            'Filtrar por mês${_isPremium ? '' : ' (Premium)'}',
                            style: TextStyle(
                              color: _isPremium ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todos os meses'),
                            ),
                            ...List.generate(12, (i) => i + 1).map((mes) {
                              const meses = [
                                'Janeiro', 'Fevereiro', 'Março', 'Abril',
                                'Maio', 'Junho', 'Julho', 'Agosto',
                                'Setembro', 'Outubro', 'Novembro', 'Dezembro'
                              ];
                              return DropdownMenuItem<int?>(
                                value: mes,
                                child: Text(meses[mes - 1]),
                              );
                            }),
                          ],
                          onChanged: _selecionarMes,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de receitas
                Expanded(
                  child: _receitasFiltradas.isEmpty
                      ? const Center(
                          child: Text('Nenhuma receita encontrada'),
                        )
                      : ListView.builder(
                          itemCount: _receitasFiltradas.length,
                          itemBuilder: (context, index) {
                            final receita = _receitasFiltradas[index];
                    return ListTile(
                      title: Text(_formatCurrency(receita.valor)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(receita.data.toString().split(' ')[0]),
                          if (receita.descricao != null)
                            Text(
                              receita.descricao!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarReceita(receita),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(receita.id),
                          ),
                        ],
                      ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar receita?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletarReceita(id);
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

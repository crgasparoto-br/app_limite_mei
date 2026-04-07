import 'package:flutter/material.dart';
import '../domain/entities/receita.dart';
import '../domain/repositories/receita_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../data/services/export_service.dart';
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
  late ExportService _exportService;

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
    _exportService = getIt<ExportService>();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _editarReceita(Receita receita) async {
    // Bloquear edição se FREE e receita está acima de 120
    if (!_isPremium) {
      final indexReceita = _receitas.indexOf(receita);
      if (indexReceita >= 120) {
        _showEditBlockedPaywall();
        return;
      }
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReceitaPage(receita: receita),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadReceitas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receita atualizada com sucesso')),
      );
    }
  }

  void _showEditBlockedPaywall() {
    showPaywall(
      context,
      title: 'Edição Bloqueada',
      subtitle: 'Você atingiu o limite de 120 receitas no plano Free. Assine Premium para editar todas as suas receitas!',
      onUpgrade: () async {
        Navigator.pop(context);
        await _activatePremium();
      },
      onRestore: () async {
        Navigator.pop(context);
        await _restorePremium();
      },
    );
  }

  void _exportarReceitas() {
    if (!_isPremium) {
      _showExportPaywall();
      return;
    }

    _showExportDialog();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Receitas'),
        content: const Text('Escolha o formato de exportação:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportCSV();
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _exportPDF();
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV() async {
    try {
      await _exportService.exportToCSV(
        _receitas,
        mes: _mesFiltro,
        ano: _anoSelecionado,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CSV exportado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    try {
      await _exportService.exportToPDF(
        _receitas,
        mes: _mesFiltro,
        ano: _anoSelecionado,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF exportado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportPaywall() {
    showPaywall(
      context,
      title: 'Exportação Premium',
      subtitle: 'Exporte suas receitas em CSV ou PDF para enviar ao contador!',
      onUpgrade: () async {
        Navigator.pop(context);
        await _activatePremium();
      },
      onRestore: () async {
        Navigator.pop(context);
        await _restorePremium();
      },
    );
  }

  Future<void> _activatePremium() async {
    try {
      final entitlements = await _entitlementsRepo.getEntitlements();
      final newEntitlements = entitlements.copyWith(
        isPremium: true,
        dataCompra: DateTime.now(),
      );
      await _entitlementsRepo.setEntitlements(newEntitlements);
      
      if (mounted) {
        setState(() {
          _isPremium = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Premium ativado! (modo desenvolvimento)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ativar Premium: $e')),
        );
      }
    }
  }

  Future<void> _restorePremium() async {
    try {
      final restored = await _entitlementsRepo.restorePurchase();
      if (mounted) {
        if (restored) {
          setState(() {
            _isPremium = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium restaurado!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma compra encontrada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
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
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
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

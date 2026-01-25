import 'package:flutter/material.dart';
import '../domain/entities/receita.dart';
import '../domain/usecases/update_receita_usecase.dart';
import '../service_locator.dart';
import '../widgets/currency_input_formatter.dart';

class EditReceitaPage extends StatefulWidget {
  final Receita receita;

  const EditReceitaPage({super.key, required this.receita});

  @override
  State<EditReceitaPage> createState() => _EditReceitaPageState();
}

class _EditReceitaPageState extends State<EditReceitaPage> {
  late UpdateReceitaUseCase _updateReceita;
  late TextEditingController _valorCtrl;
  late TextEditingController _descricaoCtrl;

  late DateTime _dataSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _updateReceita = getIt<UpdateReceitaUseCase>();
    
    // Pré-preencher com dados existentes
    _valorCtrl = TextEditingController(text: _formatValorInput(widget.receita.valor));
    _descricaoCtrl = TextEditingController(text: widget.receita.descricao ?? '');
    _dataSelecionada = widget.receita.data;
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  String _formatValorInput(double value) {
    // Formatar para formato brasileiro: 1500.50 -> 1.500,50
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = int.parse(parts[0]);
    final intFormatted = intPart.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$intFormatted,${parts[1]}';
  }

  Future<void> _salvar() async {
    // Validar valor
    if (_valorCtrl.text.trim().isEmpty) {
      _showSnackbar('Informe o valor');
      return;
    }

    final valor = _parseValor(_valorCtrl.text);
    if (valor <= 0) {
      _showSnackbar('Valor deve ser maior que zero');
      return;
    }

    setState(() => _salvando = true);

    try {
      final receitaAtualizada = Receita(
        id: widget.receita.id,
        valor: valor,
        data: _dataSelecionada,
        descricao: _descricaoCtrl.text.trim().isEmpty
            ? null
            : _descricaoCtrl.text.trim(),
        criadoEm: widget.receita.criadoEm,
        atualizadoEm: DateTime.now(),
      );

      final result = await _updateReceita(receitaAtualizada);

      if (!result.success) {
        _showSnackbar(result.error ?? 'Erro ao salvar');
      } else {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showSnackbar('Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(_dataSelecionada.year - 5),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  double _parseValor(String input) {
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
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Receita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [BrCurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: 'Ex: 1.500,00',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Data'),
              subtitle: Text(_dataSelecionada.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _escolherData,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Venda de produto, Serviço...',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando ? 'Salvando...' : 'Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

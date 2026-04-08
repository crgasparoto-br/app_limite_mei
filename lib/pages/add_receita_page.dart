import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/receita.dart';
import '../domain/usecases/add_receita_usecase.dart';
import '../presentation/widgets/premium_purchase_flow.dart';
import '../service_locator.dart';
import '../utils/date_formatters.dart';
import '../widgets/currency_input_formatter.dart';

class AddReceitaPage extends StatefulWidget {
  const AddReceitaPage({super.key});

  @override
  State<AddReceitaPage> createState() => _AddReceitaPageState();
}

class _AddReceitaPageState extends State<AddReceitaPage> {
  late AddReceitaUseCase _addReceita;
  final _valorCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  DateTime _dataSelecionada = DateTime.now();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _addReceita = getIt<AddReceitaUseCase>();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
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

    // Validar data nÃ£o futura
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dataSelecionadaSemHora = DateTime(_dataSelecionada.year, _dataSelecionada.month, _dataSelecionada.day);
    
    if (dataSelecionadaSemHora.isAfter(hojeSemHora)) {
      _showSnackbar('A data nÃ£o pode ser futura');
      return;
    }

    setState(() => _salvando = true);

    try {
      final receita = Receita(
        id: const Uuid().v4(),
        valor: valor,
        data: _dataSelecionada,
        descricao: _descricaoCtrl.text.trim().isEmpty
            ? null
            : _descricaoCtrl.text.trim(),
        criadoEm: DateTime.now(),
      );

      final result = await _addReceita(receita);

      if (!result.success) {
        if (result.isLimitReached) {
          // Mostrar paywall
          if (mounted) {
            _showPaywall();
          }
        } else {
          _showSnackbar(result.error ?? 'Erro ao salvar');
        }
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

  void _showPaywall() {
    showPremiumPaywallFlow(
      context,
      title: 'Limite de lancamentos atingido',
      subtitle: 'Voce ja registrou 120 receitas. Escolha um plano para liberar lancamentos ilimitados.',
      onSuccess: () async {
        _showSnackbar('Plano ativado! Agora voce pode adicionar a receita.');
      },
    );
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
      locale: const Locale('pt', 'BR'),
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
      appBar: AppBar(title: const Text('Nova Receita')),
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
              subtitle: Text(DateFormatters.date(_dataSelecionada)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _escolherData,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'DescriÃ§Ã£o (opcional)',
                hintText: 'Ex: Venda de produto, ServiÃ§o...',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: Text(_salvando ? 'Salvando...' : 'Salvar Receita'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





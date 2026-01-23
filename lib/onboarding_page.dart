import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _limitCtrl = TextEditingController(text: '81.000,00');
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  bool _notif = true;

  bool _loading = false;
  String? _error;

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

  String? _validate() {
    final yearText = _yearCtrl.text.trim();
    final limitText = _limitCtrl.text.trim();

    if (yearText.isEmpty) return 'Informe o ano.';
    final year = int.tryParse(yearText);
    if (year == null) return 'Ano inválido.';
    if (year < 2000 || year > 2100) return 'Ano fora do intervalo (2000–2100).';

    if (limitText.isEmpty) return 'Informe o limite anual.';
    final limit = _parseMoneyToDouble(limitText);
    if (limit <= 0) return 'Limite anual deve ser maior que zero.';

    return null;
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final limit = _parseMoneyToDouble(_limitCtrl.text);
      final year = int.parse(_yearCtrl.text.trim());

      await supabase.from('settings').upsert({
        'user_id': user.id,
        'year': year,
        'annual_limit': limit,
        'notifications_enabled': _notif,
        // opcional: limpar alertas ao mudar limite/ano
        'last_alert_year': null,
        'last_alert_level': null,
        'last_alert_at': null,
      });

      if (!mounted) return;

      // ✅ fix definitivo: sempre volta para HOME “limpando a pilha”
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração inicial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Ano'),
            ),
            const SizedBox(height: 12),
TextField(
  controller: _limitCtrl,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [BrCurrencyInputFormatter()],
  decoration: const InputDecoration(
    labelText: 'Limite anual (R\$)',
    hintText: 'Ex: 81.000,00',
  ),
),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _notif,
              onChanged: _loading ? null : (v) => setState(() => _notif = v),
              title: const Text('Notificações'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: Text(_loading ? 'Salvando...' : 'Salvar'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Máscara simples BRL: digita números e vira "1.234,56"
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

    String wholeStr = whole.toString();
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
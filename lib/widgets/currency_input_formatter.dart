import 'package:flutter/services.dart';

/// Máscara para entrada de moeda em BRL: digita números e vira "1.234,56"
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

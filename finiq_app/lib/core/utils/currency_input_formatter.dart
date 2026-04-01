import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input in Indian number system (e.g. 12,34,567).
/// Use on all money-related TextFormField widgets.
class CurrencyInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,##,###', 'en_IN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove everything except digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digitsOnly) ?? 0;
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Parses any formatted currency string to a double.
/// Handles: "₹5,00,000", "5,000", "₹ 5000", "5000"
double parseAmount(String? input) {
  if (input == null || input.isEmpty) return 0;
  final cleaned = input
      .replaceAll('₹', '')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();
  return double.tryParse(cleaned) ?? 0;
}

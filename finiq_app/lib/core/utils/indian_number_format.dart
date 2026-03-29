import 'package:intl/intl.dart';

class IndianNumberFormat {
  IndianNumberFormat._();

  static final _inrFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _inrDecFormat = NumberFormat('#,##,##0.00', 'en_IN');

  /// Format as ₹1,20,000
  static String formatRupee(double amount, {bool showDecimals = false}) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    if (showDecimals) return '$prefix₹${_inrDecFormat.format(abs)}';
    return '$prefix₹${_inrFormat.format(abs)}';
  }

  /// Format with Indian shorthand: L (lakhs), Cr (crores)
  static String formatCompact(double amount) {
    if (amount == 0) return '₹0';
    final prefix = amount < 0 ? '-' : '';
    final abs = amount.abs();

    if (abs >= 10000000) {
      final crores = abs / 10000000;
      if (crores == crores.roundToDouble()) {
        return '$prefix₹${crores.toInt()}Cr';
      }
      return '$prefix₹${crores.toStringAsFixed(2)}Cr';
    } else if (abs >= 100000) {
      final lakhs = abs / 100000;
      if (lakhs == lakhs.roundToDouble()) {
        return '$prefix₹${lakhs.toInt()}L';
      }
      return '$prefix₹${lakhs.toStringAsFixed(2)}L';
    } else if (abs >= 1000) {
      final thousands = abs / 1000;
      return '$prefix₹${thousands.toStringAsFixed(0)}K';
    }
    return formatRupee(amount);
  }

  /// Format plain number in Indian system
  static String formatNumber(double number) {
    return _inrFormat.format(number.abs());
  }

  /// Parse a plain indian-formatted string to double
  static double? parse(String value) {
    try {
      final cleaned = value.replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Format amount for display (full Indian rupee format)
  static String formatFull(double amount) {
    return _inrFormat.format(amount.abs());
  }

  /// Format as percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
}

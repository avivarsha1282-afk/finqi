import 'package:intl/intl.dart';

class IndianNumberFormat {
  IndianNumberFormat._();

  static final _inrFormat = NumberFormat('#,##,##0', 'en_IN');
  static final _inrDecFormat = NumberFormat('#,##,##0.00', 'en_IN');

  /// Format as ₹1,20,000
  static String formatRupee(double amount, {bool showDecimals = false}) {
    if (showDecimals) return '₹${_inrDecFormat.format(amount)}';
    return '₹${_inrFormat.format(amount)}';
  }

  /// Format with Indian shorthand: L (lakhs), Cr (crores)
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      final crores = amount / 10000000;
      if (crores == crores.roundToDouble()) {
        return '₹${crores.toInt()}Cr';
      }
      return '₹${crores.toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      final lakhs = amount / 100000;
      if (lakhs == lakhs.roundToDouble()) {
        return '₹${lakhs.toInt()}L';
      }
      return '₹${lakhs.toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '₹${thousands.toStringAsFixed(0)}K';
    }
    return formatRupee(amount);
  }

  /// Format plain number in Indian system
  static String formatNumber(double number) {
    return _inrFormat.format(number);
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
    return _inrFormat.format(amount);
  }

  /// Format as percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
}

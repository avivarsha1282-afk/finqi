import 'indian_number_format.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Full rupee: ₹50,00,000
  static String format(double amount) => IndianNumberFormat.formatRupee(amount);

  /// Compact: ₹50L, ₹1.52Cr
  static String compact(double amount) => IndianNumberFormat.formatCompact(amount);

  /// For display with decimals: ₹50,00,000.00
  static String formatWithDecimals(double amount) =>
      IndianNumberFormat.formatRupee(amount, showDecimals: true);

  /// Monthly SIP: ₹1.80L/mo
  static String monthly(double amount) => '${IndianNumberFormat.formatCompact(amount)}/mo';

  /// Parse user input string to double
  static double? parse(String value) => IndianNumberFormat.parse(value);
}

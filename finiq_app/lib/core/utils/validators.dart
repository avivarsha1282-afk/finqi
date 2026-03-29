class Validators {
  Validators._();

  static String? salary(String? value) {
    if (value == null || value.isEmpty) return 'Salary is required';
    final cleaned = value.replaceAll(',', '').replaceAll('₹', '').trim();
    final num = double.tryParse(cleaned);
    if (num == null) return 'Enter a valid number';
    if (num < 100000) return 'Minimum salary is ₹1,00,000';
    if (num > 1000000000) return 'Enter a realistic salary';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? amount(String? value, {double min = 0}) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final cleaned = value.replaceAll(',', '').replaceAll('₹', '').trim();
    final num = double.tryParse(cleaned);
    if (num == null) return 'Enter a valid amount';
    if (num < min) return 'Amount must be at least ₹${min.toInt()}';
    return null;
  }

  static String? years(String? value) {
    if (value == null || value.isEmpty) return 'Timeline is required';
    final num = int.tryParse(value);
    if (num == null) return 'Enter whole years (e.g., 7)';
    if (num < 1) return 'Minimum 1 year';
    if (num > 40) return 'Maximum 40 years';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) return 'Enter a 10-digit mobile number';
    return null;
  }
}

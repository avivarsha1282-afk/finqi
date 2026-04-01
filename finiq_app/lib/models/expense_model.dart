import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String category;
  final String categoryIcon;
  final String categoryColor;
  final double amount;
  final String note;
  final DateTime date;
  final String monthKey; // "2026-03" for fast monthly queries

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    this.note = '',
    required this.date,
    required this.monthKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'category_icon': categoryIcon,
        'category_color': categoryColor,
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(date),
        'month_key': monthKey,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory ExpenseModel.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return ExpenseModel(
      id: json['id'] ?? docId,
      category: json['category'] ?? 'Other',
      categoryIcon: json['category_icon'] ?? '📦',
      categoryColor: json['category_color'] ?? 'D3D3D3',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      note: json['note'] ?? '',
      date: parsedDate,
      monthKey: json['month_key'] ?? '',
    );
  }

  /// Preset categories with icons, colors, and default quick-add amounts
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food / Mess', 'icon': '🍱', 'color': 'FF6B35', 'defaultAmount': 80.0},
    {'name': 'Tea / Snacks', 'icon': '☕', 'color': 'C8963E', 'defaultAmount': 20.0},
    {'name': 'Transport', 'icon': '🚌', 'color': '4ECDC4', 'defaultAmount': 30.0},
    {'name': 'Room Rent', 'icon': '🏠', 'color': '45B7D1', 'defaultAmount': 0.0},
    {'name': 'Recharge', 'icon': '📱', 'color': '96CEB4', 'defaultAmount': 0.0},
    {'name': 'Entertainment', 'icon': '🎬', 'color': 'DDA0DD', 'defaultAmount': 0.0},
    {'name': 'Shopping', 'icon': '🛍️', 'color': 'FF9999', 'defaultAmount': 0.0},
    {'name': 'Medical', 'icon': '💊', 'color': 'FF6B6B', 'defaultAmount': 0.0},
    {'name': 'Pocket Money', 'icon': '💵', 'color': '98D8C8', 'defaultAmount': 0.0},
    {'name': 'Prints/Stationery', 'icon': '📄', 'color': 'B8B8FF', 'defaultAmount': 10.0},
    {'name': 'Groceries', 'icon': '🛒', 'color': '90EE90', 'defaultAmount': 0.0},
    {'name': 'Other', 'icon': '📦', 'color': 'D3D3D3', 'defaultAmount': 0.0},
  ];
}

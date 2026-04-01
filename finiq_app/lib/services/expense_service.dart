import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

class ExpenseService {
  ExpenseService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _expensesRef {
    return _db.collection('users').doc(_uid).collection('expenses');
  }

  /// Add a new expense
  static Future<void> addExpense(ExpenseModel expense) async {
    if (_uid == null) return;
    final docRef = _expensesRef.doc(expense.id);
    await docRef.set(expense.toJson());

    // Update monthly summary cache
    await _updateMonthlySummary(expense.monthKey);
  }

  /// Delete an expense
  static Future<void> deleteExpense(String expenseId, String monthKey) async {
    if (_uid == null) return;
    await _expensesRef.doc(expenseId).delete();
    await _updateMonthlySummary(monthKey);
  }

  /// Get expenses for a specific date
  static Future<List<ExpenseModel>> getExpensesForDate(DateTime date) async {
    if (_uid == null) return [];
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final snapshot = await _expensesRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all expenses for a month
  static Future<List<ExpenseModel>> getExpensesForMonth(String monthKey) async {
    if (_uid == null) return [];
    try {
      final snapshot = await _expensesRef
          .where('month_key', isEqualTo: monthKey)
          .get();

      final list = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Get monthly summary (total spent, by category)
  static Future<Map<String, dynamic>> getMonthlySummary(String monthKey) async {
    final expenses = await getExpensesForMonth(monthKey);

    double totalSpent = 0;
    final Map<String, double> byCategory = {};
    final Map<String, double> dailyTotals = {};

    for (final e in expenses) {
      totalSpent += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      final dayKey = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + e.amount;
    }

    return {
      'total_spent': totalSpent,
      'by_category': byCategory,
      'daily_totals': dailyTotals,
      'expense_count': expenses.length,
    };
  }

  /// Update cached monthly summary
  static Future<void> _updateMonthlySummary(String monthKey) async {
    // Lightweight cache update - just invalidate, let provider re-fetch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expense_updated_$monthKey', DateTime.now().toIso8601String());
  }

  /// Get monthly budget from user profile
  static Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid ?? '';
    // Try custom budget first, then fall back to onboarding monthly_expense
    final customBudget = prefs.getDouble('${uid}_expense_budget');
    if (customBudget != null && customBudget > 0) return customBudget;

    final monthlyExpense = prefs.getDouble('${uid}_monthly_expense') ??
        prefs.getDouble('monthly_expense') ?? 10000;
    return monthlyExpense;
  }

  /// Set custom monthly budget
  static Future<void> setMonthlyBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid ?? '';
    await prefs.setDouble('${uid}_expense_budget', budget);
  }

  /// Get today's total
  static Future<double> getTodayTotal() async {
    final today = DateTime.now();
    final expenses = await getExpensesForDate(today);
    double total = 0;
    for (final e in expenses) {
      total += e.amount;
    }
    return total;
  }
}

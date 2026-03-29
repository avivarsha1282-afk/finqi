import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/health_score_model.dart';
import '../../../models/fire_plan_model.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/api_service.dart';

// ─── Dashboard data class ──────────────────────────────────
class DashboardData {
  final String userName;
  final String? userPhoto;
  final HealthScoreModel score;
  final FirePlanModel firePlan;
  final TaxReportModel taxReport;
  final List<dynamic> priorityActions;
  final String arthaBrief;

  DashboardData({
    required this.userName,
    this.userPhoto,
    required this.score,
    required this.firePlan,
    required this.taxReport,
    required this.priorityActions,
    required this.arthaBrief,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userName: json['user']?['name'] ?? 'User',
      userPhoto: json['user']?['photo_url'],
      score: json['latest_score'] != null
          ? HealthScoreModel.fromJson(json['latest_score'])
          : HealthScoreModel.demo(),
      firePlan: json['fire_plan'] != null
          ? FirePlanModel.fromJson(json['fire_plan'])
          : FirePlanModel.demo(),
      taxReport: json['tax_report'] != null
          ? TaxReportModel.fromJson(json['tax_report'])
          : TaxReportModel.demo(),
      priorityActions: json['priority_actions'] ?? [],
      arthaBrief: json['artha_brief'] ??
          'Starting ₹5,000/mo in a Nifty 50 index fund costs less than most weekend dinners — and grows to ₹82,000 in 10 years.',
    );
  }

  factory DashboardData.demo(String name, String? photo) {
    return DashboardData(
      userName: name,
      userPhoto: photo,
      score: HealthScoreModel.demo(),
      firePlan: FirePlanModel.demo(),
      taxReport: TaxReportModel.demo(),
      priorityActions: [],
      arthaBrief:
          'Starting ₹5,000/mo in a Nifty 50 index fund costs less than most weekend dinners — and grows to ₹82,000 in 10 years.',
    );
  }
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  // Get the real Firebase user so fallbacks use their actual name/photo
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final realName = firebaseUser?.displayName ?? 'User';
  final realPhoto = firebaseUser?.photoURL;

  try {
    final json = await ApiService.instance.getDashboard();
    // API succeeded — parse real data but patch name/photo from Firebase if backend omitted them
    final data = DashboardData.fromJson(json);
    if (data.userName == 'User' && realName != 'User') {
      return DashboardData(
        userName: realName,
        userPhoto: realPhoto,
        score: data.score,
        firePlan: data.firePlan,
        taxReport: data.taxReport,
        priorityActions: data.priorityActions,
        arthaBrief: data.arthaBrief,
      );
    }
    return data;
  } on ApiException catch (e) {
    // Network/server error — show real user's name but indicate data is unavailable
    if (e.statusCode == 401) rethrow; // Auth failure → kick to login screen
    // For other errors: show the user's real name with demo financial data
    return DashboardData.demo(realName, realPhoto);
  } catch (_) {
    return DashboardData.demo(realName, realPhoto);
  }
});

// ─── Health Score ──────────────────────────────────────────
final healthScoreProvider = FutureProvider.autoDispose<HealthScoreModel>((ref) async {
  return await ApiService.instance.calculateScore();
});

// ─── Tax Report ────────────────────────────────────────────
final taxReportProvider =
    FutureProvider.autoDispose.family<TaxReportModel, double>((ref, income) async {
  return await ApiService.instance.compareTax(annualIncome: income);
});

// Stateful income for tax wizard
class TaxIncomeNotifier extends StateNotifier<double> {
  TaxIncomeNotifier() : super(5000000.0); // Default: ₹50L
  void setIncome(double val) => state = val;
}

final taxIncomeProvider =
    StateNotifierProvider<TaxIncomeNotifier, double>((ref) => TaxIncomeNotifier());

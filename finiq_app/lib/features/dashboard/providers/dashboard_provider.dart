import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/health_score_model.dart';
import '../../../models/fire_plan_model.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_data_service.dart';
import '../../../services/user_prefs_service.dart';

// ─── Dashboard data class ──────────────────────────────────────────
class DashboardData {
  final String userName;
  final String? userPhoto;
  final HealthScoreModel score;
  final FirePlanModel firePlan;
  final TaxReportModel taxReport;
  final List<PriorityAction> priorityActions;
  final String arthaBrief;
  final String goalName;
  final double goalAmount;
  final int goalYears;
  final double goalSavings;
  final double monthlySipNeeded;

  DashboardData({
    required this.userName,
    this.userPhoto,
    required this.score,
    required this.firePlan,
    required this.taxReport,
    required this.priorityActions,
    required this.arthaBrief,
    required this.goalName,
    required this.goalAmount,
    required this.goalYears,
    required this.goalSavings,
    required this.monthlySipNeeded,
  });
}

/// Dashboard provider — reads from UID-prefixed SharedPreferences (real user data)
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final profile = await UserDataService.getUserProfile();

  // User name: prefer profile, then Firebase, then default
  final firstName = (profile['name'] as String).split(' ').first;
  final realPhoto = firebaseUser?.photoURL;

  // Read calculated values from UID-prefixed SharedPreferences
  final healthScore = (await UserPrefsService.getInt('health_score')) ?? 44;
  final grade = (await UserPrefsService.getString('grade')) ?? 'D';
  final arthaBrief = (await UserPrefsService.getString('artha_brief')) ??
      '$firstName, complete your onboarding to get personalised financial insights.';

  // Read dimension scores
  final dimEmergency = (await UserPrefsService.getInt('dim_emergency')) ?? 6;
  final dimInsurance = (await UserPrefsService.getInt('dim_insurance')) ?? 0;
  final dimInvestment = (await UserPrefsService.getInt('dim_investment')) ?? 8;
  final dimDebt = (await UserPrefsService.getInt('dim_debt')) ?? 14;
  final dimTax = (await UserPrefsService.getInt('dim_tax')) ?? 4;
  final dimFire = (await UserPrefsService.getInt('dim_fire')) ?? 2;

  String gradeLabel(String g) {
    switch (g) {
      case 'A': return 'Excellent';
      case 'B': return 'Good Shape';
      case 'C': return 'Decent';
      case 'D': return 'Needs Attention';
      default: return 'Needs Help';
    }
  }

  String dimStatus(int score, int max) {
    final pct = score / max;
    if (pct >= 0.7) return 'DECENT';
    if (pct <= 0.1) return 'CRITICAL';
    return 'NEEDS WORK';
  }

  final scoreModel = HealthScoreModel(
    totalScore: healthScore,
    maxScore: 100,
    grade: grade,
    gradeLabel: gradeLabel(grade),
    dimensions: [
      DimensionScore(name: 'Emergency Fund', icon: 'savings', score: dimEmergency, maxScore: 20, status: dimStatus(dimEmergency, 20)),
      DimensionScore(name: 'Insurance', icon: 'shield', score: dimInsurance, maxScore: 20, status: dimStatus(dimInsurance, 20)),
      DimensionScore(name: 'Investment Mix', icon: 'pie_chart', score: dimInvestment, maxScore: 20, status: dimStatus(dimInvestment, 20)),
      DimensionScore(name: 'Debt Health', icon: 'credit_card', score: dimDebt, maxScore: 20, status: dimStatus(dimDebt, 20)),
      DimensionScore(name: 'Tax Efficiency', icon: 'receipt', score: dimTax, maxScore: 10, status: dimStatus(dimTax, 10)),
      DimensionScore(name: 'FIRE Progress', icon: 'local_fire_department', score: dimFire, maxScore: 10, status: dimStatus(dimFire, 10)),
    ],
    priorityActions: [
      PriorityAction(
        title: (await UserPrefsService.getString('priority_action_1')) ?? 'Complete your financial profile',
        subtitle: 'Personalised for you',
        severity: 'CRITICAL',
        dimension: 'General',
      ),
      PriorityAction(
        title: (await UserPrefsService.getString('priority_action_2')) ?? 'Explore Tax Wizard',
        subtitle: 'Save on taxes',
        severity: 'WARNING',
        dimension: 'Tax Efficiency',
      ),
      PriorityAction(
        title: (await UserPrefsService.getString('priority_action_3')) ?? 'Chat with Artha',
        subtitle: 'Get personalised advice',
        severity: 'WARNING',
        dimension: 'General',
      ),
    ],
    arthaInsight: arthaBrief,
    lastUpdated: DateTime.now(),
  );

  // FIRE plan from real user data
  final goalAmount = (profile['goal_amount'] as num).toDouble();
  final goalYears = profile['goal_years'] as int;
  final currentSavings = (profile['current_savings'] as num).toDouble();
  final annualIncome = (profile['annual_income'] as num).toDouble();

  final sip = MockDataService.calculateSIP(
    targetAmount: goalAmount,
    currentSavings: currentSavings,
    years: goalYears,
  );
  final timeline = MockDataService.generateTimeline(
    currentSavings: currentSavings,
    monthlySip: sip,
    years: goalYears,
  );

  final firePlan = FirePlanModel(
    targetCorpus: goalAmount,
    targetYears: goalYears,
    currentSavings: currentSavings,
    requiredMonthlySip: sip,
    projectedCorpus: goalAmount,
    estimatedReturn: 12.0,
    scenarios: [
      FireScenario(
        years: (goalYears / 2).ceil(),
        label: 'Hyper-Aggressive',
        monthlySip: MockDataService.calculateSIP(targetAmount: goalAmount, currentSavings: currentSavings, years: (goalYears / 2).ceil()),
        risk: 'HIGH RISK',
      ),
      FireScenario(years: goalYears, label: 'Sustainable Growth', monthlySip: sip, risk: 'RECOMMENDED', isRecommended: true),
    ],
    assetAllocation: const [
      AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
      AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#3B82F6'),
      AssetAllocation(name: 'Gold / Debt', percentage: 20, colorHex: '#F59E0B'),
      AssetAllocation(name: 'Intl. Funds', percentage: 10, colorHex: '#8B5CF6'),
    ],
    arthaMessage: 'Your $goalYears-year plan requires a monthly SIP to reach your goal.',
    growthData: timeline,
    achievability: sip <= 100000 ? 'ACHIEVABLE' : (sip <= 300000 ? 'STRETCH' : 'VERY_AGGRESSIVE'),
  );

  // Tax report from real user data — use actual deductions
  final userDeductions80c = (profile['deduction_80c'] as num?)?.toDouble() ?? 0;
  final userDeductions80d = (profile['deduction_80d'] as num?)?.toDouble() ?? 0;
  final userNps = (profile['annual_nps'] as num?)?.toDouble() ?? 0;
  final taxReport = MockDataService.getTaxReport(
    annualIncome: annualIncome > 0 ? annualIncome : 500000,
    actual80c: userDeductions80c,
    actual80d: userDeductions80d,
    actualNps: userNps,
  );

  return DashboardData(
    userName: firstName,
    userPhoto: realPhoto,
    score: scoreModel,
    firePlan: firePlan,
    taxReport: taxReport,
    priorityActions: scoreModel.priorityActions,
    arthaBrief: arthaBrief,
    goalName: profile['goal_name'] as String,
    goalAmount: goalAmount,
    goalYears: goalYears,
    goalSavings: currentSavings,
    monthlySipNeeded: sip,
  );
});

// ─── Health Score (async, reads from UID-prefixed SharedPreferences) ────
final healthScoreProvider = FutureProvider<HealthScoreModel>((ref) async {
  final dash = await ref.watch(dashboardProvider.future);
  return dash.score;
});

// ─── Tax Report (with custom income + actual deductions) ───────────────
final taxReportProvider =
    Provider.family<TaxReportModel, double>((ref, income) {
  return MockDataService.getTaxReport(annualIncome: income);
});

// Stateful income for tax wizard
class TaxIncomeNotifier extends StateNotifier<double> {
  TaxIncomeNotifier(double initial) : super(initial);
  void setIncome(double val) => state = val;
}

final taxIncomeProvider =
    StateNotifierProvider<TaxIncomeNotifier, double>((ref) => TaxIncomeNotifier(5000000.0));

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/health_score_model.dart';
import '../../../models/fire_plan_model.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
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
  final bool isOffline;
  final Map<String, dynamic>? profile;

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
    this.isOffline = false,
    this.profile,
  });
}

Future<DashboardData> _buildDashboardData(Map<String, dynamic> profile, bool offline) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  
  // DO NOT overwrite profile with Firestore data — Firestore only has
  // {onboarding_complete: true}. All financial data lives in SharedPrefs/MongoDB.

  final firstName = (profile['name'] as String?)?.split(' ').first ?? firebaseUser?.displayName?.split(' ').first ?? 'User';
  final realPhoto = firebaseUser?.photoURL;

  // Real user data — support BOTH old and new field name formats
  final goalAmount = ((profile['financial_goal_amount'] ?? profile['goal_amount']) as num?)?.toDouble() ?? 10000000.0;
  final goalYears = (profile['target_timeline'] ?? profile['goal_years']);
  final goalYearsInt = (goalYears is int) ? goalYears : int.tryParse(goalYears?.toString() ?? '') ?? 10;
  final currentSavings = (profile['current_savings'] as num?)?.toDouble() ?? 0.0;
  final monthlySalary = ((profile['monthly_salary'] ?? profile['monthly_income']) as num?)?.toDouble() ?? 0.0;
  final annualIncome = (profile['annual_income'] as num?)?.toDouble() ?? (monthlySalary * 12);
  final monthlyExpense = ((profile['monthly_expense'] ?? profile['monthly_expenses']) as num?)?.toDouble() ?? 1.0;
  final totalEmi = ((profile['total_emi'] ?? profile['emis']) as num?)?.toDouble() ?? 0.0;
  final monthlyIncome = monthlySalary > 0 ? monthlySalary : (annualIncome / 12);

  // Extract backend analysis if it exists
  final hsMap = profile['health_score'] as Map<String, dynamic>?;
  
  final healthScore = hsMap?['total_score'] ?? (await UserPrefsService.getInt('health_score') ?? 44);
  final grade = hsMap?['grade'] ?? (await UserPrefsService.getString('grade') ?? 'D');
  final arthaBrief = profile['artha_brief'] as String? ??
      (await UserPrefsService.getString('artha_brief')) ??
      '$firstName, complete your onboarding to get personalised financial insights.';

  final dims = hsMap?['dimensions'] as Map<String, dynamic>? ?? {};
  final dimEmergency = dims['emergency_fund'] ?? (await UserPrefsService.getInt('dim_emergency') ?? 6);
  final dimInsurance = dims['insurance'] ?? (await UserPrefsService.getInt('dim_insurance') ?? 0);
  final dimInvestment = dims['diversification'] ?? (await UserPrefsService.getInt('dim_investment') ?? 8);
  final dimDebt = dims['debt_health'] ?? (await UserPrefsService.getInt('dim_debt') ?? 14);
  final dimTax = dims['tax_efficiency'] ?? (await UserPrefsService.getInt('dim_tax') ?? 4);
  final dimFire = dims['retirement'] ?? (await UserPrefsService.getInt('dim_fire') ?? 2);

  String gradeLabel(String g) {
    switch (g) {
      case 'A': return 'Excellent';
      case 'B': return 'Good Shape';
      case 'C': return 'Decent';
      case 'D': return 'Needs Attention';
      default: return 'Needs Help';
    }
  }

  String dimStatus(int score, int max, {bool isDebt = false}) {
    if (isDebt && monthlyIncome > 0 && (totalEmi / monthlyIncome) > 0.6) return 'CRITICAL';
    final pct = score / max;
    if (pct >= 0.7) return 'DECENT';
    if (pct <= 0.1) return 'CRITICAL';
    return 'NEEDS WORK';
  }

  List<PriorityAction> buildPriorityActions() {
    List<PriorityAction> actions = [];
    if (currentSavings < monthlyExpense) {
      actions.add(const PriorityAction(
        title: 'Emergency Fund Alert',
        subtitle: 'Build 3 months of savings first',
        severity: 'CRITICAL',
        dimension: 'Emergency Fund',
      ));
    }
    if (monthlyIncome > 0 && (totalEmi / monthlyIncome) > 0.6) {
      actions.add(const PriorityAction(
        title: 'High Debt Burden',
        subtitle: 'Your EMIs exceed 60% of income',
        severity: 'CRITICAL',
        dimension: 'Debt Health',
      ));
    }
    if (annualIncome >= 300000) {
      actions.add(const PriorityAction(
        title: 'Explore Tax Wizard',
        subtitle: 'Save on taxes',
        severity: 'WARNING',
        dimension: 'Tax Efficiency',
      ));
    }
    if (actions.isEmpty) {
      actions.add(const PriorityAction(
        title: 'Chat with Artha',
        subtitle: 'Get personalised advice',
        severity: 'INFO',
        dimension: 'General',
      ));
    }
    return actions;
  }

  final scoreModel = HealthScoreModel(
    totalScore: (healthScore as num).toInt(),
    maxScore: 100,
    grade: grade,
    gradeLabel: gradeLabel(grade),
    dimensions: [
      DimensionScore(name: 'Emergency Fund', icon: 'savings', score: (dimEmergency as num).toInt(), maxScore: 20, status: dimStatus((dimEmergency as num).toInt(), 20)),
      DimensionScore(name: 'Insurance', icon: 'shield', score: (dimInsurance as num).toInt(), maxScore: 20, status: dimStatus((dimInsurance as num).toInt(), 20)),
      DimensionScore(name: 'Investment Mix', icon: 'pie_chart', score: (dimInvestment as num).toInt(), maxScore: 20, status: dimStatus((dimInvestment as num).toInt(), 20)),
      DimensionScore(name: 'Debt Health', icon: 'credit_card', score: (dimDebt as num).toInt(), maxScore: 20, status: dimStatus((dimDebt as num).toInt(), 20, isDebt: true)),
      if (annualIncome >= 300000)
        DimensionScore(name: 'Tax Efficiency', icon: 'receipt', score: (dimTax as num).toInt(), maxScore: 20, status: dimStatus((dimTax as num).toInt(), 20)),
      DimensionScore(name: 'FIRE Progress', icon: 'local_fire_department', score: (dimFire as num).toInt(), maxScore: 20, status: dimStatus((dimFire as num).toInt(), 20)),
    ],
    priorityActions: buildPriorityActions(),
    arthaInsight: arthaBrief,
    lastUpdated: DateTime.now(),
  );

  final fireMap = profile['fire_plan'] as Map<String, dynamic>?;
  
  final sip = fireMap != null ? (fireMap['required_monthly_sip'] as num).toDouble() : MockDataService.calculateSIP(
    targetAmount: goalAmount,
    currentSavings: currentSavings,
    years: goalYearsInt,
  );
  
  final timeline = fireMap != null ? (fireMap['timeline'] as List).map((e) => ChartDataPoint(year: (e['year'] as num).toInt(), corpus: (e['corpus'] as num).toDouble())).toList() : MockDataService.generateTimeline(
    currentSavings: currentSavings,
    monthlySip: sip,
    years: goalYearsInt,
  );

  final firePlan = FirePlanModel(
    targetCorpus: goalAmount,
    targetYears: goalYearsInt,
    currentSavings: currentSavings,
    requiredMonthlySip: sip,
    projectedCorpus: goalAmount,
    estimatedReturn: 12.0,
    scenarios: [
      FireScenario(
        years: (goalYearsInt / 2).ceil(),
        label: 'Hyper-Aggressive',
        monthlySip: MockDataService.calculateSIP(targetAmount: goalAmount, currentSavings: currentSavings, years: (goalYearsInt / 2).ceil()),
        risk: 'HIGH RISK',
      ),
      FireScenario(years: goalYearsInt, label: 'Sustainable Growth', monthlySip: sip, risk: 'RECOMMENDED', isRecommended: true),
    ],
    assetAllocation: const [
      AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
      AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#3B82F6'),
      AssetAllocation(name: 'Gold / Debt', percentage: 20, colorHex: '#F59E0B'),
      AssetAllocation(name: 'Intl. Funds', percentage: 10, colorHex: '#8B5CF6'),
    ],
    arthaMessage: 'Your $goalYearsInt-year plan requires a monthly SIP to reach your goal.',
    growthData: timeline,
    achievability: fireMap != null ? fireMap['achievability'] : (sip <= 100000 ? 'ACHIEVABLE' : (sip <= 300000 ? 'STRETCH' : 'VERY_AGGRESSIVE')),
  );

  final taxMap = profile['tax_report'] as Map<String, dynamic>?;
  
  final userDeductions80c = ((profile['section_80c'] ?? profile['deduction_80c']) as num?)?.toDouble() ?? 0.0;
  final userDeductions80d = ((profile['premium_80d'] ?? profile['deduction_80d']) as num?)?.toDouble() ?? 0.0;
  final userNps = ((profile['nps_contribution'] ?? profile['annual_nps']) as num?)?.toDouble() ?? 0.0;
  
  final mockTax = MockDataService.getTaxReport(
    annualIncome: annualIncome > 0 ? annualIncome : 500000,
    actual80c: userDeductions80c,
    actual80d: userDeductions80d,
    actualNps: userNps,
  );
  
  final taxReport = taxMap != null ? TaxReportModel(
    annualIncome: annualIncome > 0 ? annualIncome : 500000,
    oldRegime: TaxRegimeResult.fromJson(taxMap['old_regime'] ?? {}),
    newRegime: TaxRegimeResult.fromJson(taxMap['new_regime'] ?? {}),
    verdict: (taxMap['recommended_regime'] ?? 'new').toString().toUpperCase(),
    totalPotentialSaving: (taxMap['total_potential_saving'] as num?)?.toDouble() ?? 0.0,
    channels: (taxMap['missed_deductions'] as List<dynamic>? ?? [])
        .map((c) => TaxChannel.fromJson(c as Map<String, dynamic>))
        .toList(),
    arthaVerdict: taxMap['artha_verdict'] ?? '',
  ) : mockTax;

  return DashboardData(
    userName: firstName,
    userPhoto: realPhoto,
    score: scoreModel,
    firePlan: firePlan,
    taxReport: taxReport,
    priorityActions: scoreModel.priorityActions,
    arthaBrief: arthaBrief,
    goalName: (profile['financial_goal'] ?? profile['goal_name']) as String? ?? 'Financial Goal',
    goalAmount: goalAmount,
    goalYears: goalYearsInt,
    goalSavings: currentSavings,
    monthlySipNeeded: sip,
    isOffline: offline,
    profile: profile,
  );
}

final dashboardProvider = StreamProvider.autoDispose<DashboardData>((ref) async* {
  final cached = CacheService.getFreshDashboard();
  if (cached != null) {
    yield await _buildDashboardData(cached, false);
  } else {
    final localPrefs = await UserDataService.getUserProfile();
    yield await _buildDashboardData(localPrefs, false);
  }

  try {
    final apiData = await ApiService.instance.getDashboard();
    final merged = Map<String, dynamic>.from(apiData['profile'] ?? apiData);
    // Map both possible key names for health score
    final scoreData = apiData['health_score'] ?? apiData['latest_score'];
    if (scoreData != null) merged['health_score'] = scoreData;
    if (apiData.containsKey('fire_plan')) merged['fire_plan'] = apiData['fire_plan'];
    if (apiData.containsKey('tax_report')) merged['tax_report'] = apiData['tax_report'];
    if (apiData.containsKey('gemini_dashboard')) merged['gemini_dashboard'] = apiData['gemini_dashboard'];
    if (apiData.containsKey('artha_brief')) merged['artha_brief'] = apiData['artha_brief'];

    await CacheService.cacheDashboard(merged);
    yield await _buildDashboardData(merged, false);
  } catch (e) {
    debugPrint("Dashboard: backend unavailable — using local data. $e");
  }
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

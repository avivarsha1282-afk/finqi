
import '../models/health_score_model.dart';
import '../models/fire_plan_model.dart';
import '../models/tax_report_model.dart';

/// Central data service — provides calculations and fallback data.
/// No longer reads SharedPreferences directly (that's UserDataService's job).
class MockDataService {
  MockDataService._();

  // ── Health Score (static fallback) ────────────────────────────────────────
  static HealthScoreModel getHealthScore() {
    return HealthScoreModel(
      totalScore: 44,
      maxScore: 100,
      grade: 'D',
      gradeLabel: 'Needs Attention',
      dimensions: [
        const DimensionScore(name: 'Emergency Fund', icon: 'savings', score: 16, maxScore: 20, status: 'DECENT'),
        const DimensionScore(name: 'Insurance', icon: 'shield', score: 0, maxScore: 20, status: 'CRITICAL'),
        const DimensionScore(name: 'Investment Mix', icon: 'pie_chart', score: 8, maxScore: 20, status: 'NEEDS WORK'),
        const DimensionScore(name: 'Debt Health', icon: 'credit_card', score: 14, maxScore: 20, status: 'DECENT'),
        const DimensionScore(name: 'Tax Efficiency', icon: 'receipt', score: 4, maxScore: 10, status: 'NEEDS WORK'),
        const DimensionScore(name: 'FIRE Progress', icon: 'local_fire_department', score: 2, maxScore: 10, status: 'NEEDS WORK'),
      ],
      priorityActions: const [
        PriorityAction(title: 'Get Term Insurance', subtitle: 'Life Cover Missing', severity: 'CRITICAL', dimension: 'Insurance'),
        PriorityAction(title: 'Start ELSS SIP for 80C', subtitle: 'Tax deduction opportunity', severity: 'WARNING', dimension: 'Tax Efficiency'),
        PriorityAction(title: 'Open NPS Account', subtitle: '₹50K additional tax benefit', severity: 'WARNING', dimension: 'Tax Efficiency'),
      ],
      arthaInsight: 'Complete your onboarding to get personalised financial insights.',
      lastUpdated: DateTime.now(),
    );
  }

  // ── FIRE Plan (static fallback) ──────────────────────────────────────────
  static FirePlanModel getFirePlan() {
    return FirePlanModel(
      targetCorpus: 15200000,
      targetYears: 7,
      currentSavings: 200000,
      requiredMonthlySip: 180000,
      projectedCorpus: 15200000,
      estimatedReturn: 12.0,
      scenarios: const [
        FireScenario(years: 3, label: 'Hyper-Aggressive', monthlySip: 425000, risk: 'HIGH RISK'),
        FireScenario(years: 7, label: 'Sustainable Growth', monthlySip: 180000, risk: 'RECOMMENDED', isRecommended: true),
        FireScenario(years: 10, label: 'Conservative Path', monthlySip: 95000, risk: 'LOW RISK'),
      ],
      assetAllocation: const [
        AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
        AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#3B82F6'),
        AssetAllocation(name: 'Gold / Debt', percentage: 20, colorHex: '#F59E0B'),
        AssetAllocation(name: 'Intl. Funds', percentage: 10, colorHex: '#8B5CF6'),
      ],
      arthaMessage: 'Plan your FIRE journey with FinIQ.',
      growthData: const [
        ChartDataPoint(year: 0, corpus: 200000),
        ChartDataPoint(year: 1, corpus: 2360000),
        ChartDataPoint(year: 2, corpus: 4800000),
        ChartDataPoint(year: 3, corpus: 7600000),
        ChartDataPoint(year: 4, corpus: 10200000),
        ChartDataPoint(year: 5, corpus: 12800000),
        ChartDataPoint(year: 6, corpus: 14400000),
        ChartDataPoint(year: 7, corpus: 15200000),
      ],
      achievability: 'ACHIEVABLE',
    );
  }

  /// Calculate SIP amount using standard formula
  static double calculateSIP({
    required double targetAmount,
    required double currentSavings,
    required int years,
    double annualReturn = 12.0,
  }) {
    if (years <= 0 || targetAmount <= 0) return 0;
    final r = annualReturn / 100 / 12; // monthly rate
    final n = years * 12; // total months
    final futureValueOfSavings = currentSavings * _pow(1 + r, n);
    final remaining = targetAmount - futureValueOfSavings;
    if (remaining <= 0) return 0;
    final denominator = _pow(1 + r, n) - 1;
    if (denominator <= 0) return 0;
    final sip = remaining * r / denominator;
    return sip;
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  /// Generate growth timeline for chart
  static List<ChartDataPoint> generateTimeline({
    required double currentSavings,
    required double monthlySip,
    required int years,
    double annualReturn = 12.0,
  }) {
    if (years <= 0) return [ChartDataPoint(year: 0, corpus: currentSavings)];
    final r = annualReturn / 100 / 12;
    List<ChartDataPoint> points = [];
    for (int y = 0; y <= years; y++) {
      final n = y * 12;
      final savingsGrowth = currentSavings * _pow(1 + r, n);
      final sipGrowth = n > 0 ? monthlySip * (_pow(1 + r, n) - 1) / r : 0;
      points.add(ChartDataPoint(year: y, corpus: savingsGrowth + sipGrowth));
    }
    return points;
  }

  // ── Tax Report ────────────────────────────────────────────────────────────
  /// Calculate tax with ACTUAL user deductions (not hardcoded max).
  static TaxReportModel getTaxReport({
    double? annualIncome,
    double actual80c = 0,
    double actual80d = 0,
    double actualNps = 0,
  }) {
    final income = annualIncome ?? 5000000;
    return _calculateTax(income, actual80c, actual80d, actualNps);
  }

  static TaxReportModel _calculateTax(
      double income, double actual80c, double actual80d, double actualNps) {
    // FY 2025-26 NEW REGIME slabs
    double newTax = 0;
    final newSlabs = [
      [400000.0, 0.0], [800000.0, 0.05], [1200000.0, 0.10],
      [1600000.0, 0.15], [2000000.0, 0.20], [2400000.0, 0.25],
    ];
    const newStdDeduction = 75000.0;
    double newTaxableIncome = income - newStdDeduction;
    if (newTaxableIncome < 0) newTaxableIncome = 0;

    double remaining = newTaxableIncome;
    double prevLimit = 0;
    for (final slab in newSlabs) {
      final limit = slab[0];
      final rate = slab[1];
      final taxable = (remaining > (limit - prevLimit)) ? (limit - prevLimit) : remaining;
      newTax += taxable * rate;
      remaining -= taxable;
      prevLimit = limit;
      if (remaining <= 0) break;
    }
    if (remaining > 0) newTax += remaining * 0.30;
    newTax *= 1.04; // 4% cess

    // FY 2025-26 OLD REGIME slabs
    // Use ACTUAL deductions the user already has
    const oldStdDeduction = 50000.0;
    final double totalActualDeductions = actual80c.clamp(0.0, 150000.0) +
        actual80d.clamp(0.0, 25000.0) +
        actualNps.clamp(0.0, 50000.0);
    double oldTaxableIncome = income - oldStdDeduction - totalActualDeductions;
    if (oldTaxableIncome < 0) oldTaxableIncome = 0;

    double oldTax = 0;
    final oldSlabs = [
      [250000.0, 0.0], [500000.0, 0.05], [1000000.0, 0.20],
    ];
    remaining = oldTaxableIncome;
    prevLimit = 0;
    for (final slab in oldSlabs) {
      final limit = slab[0];
      final rate = slab[1];
      final taxable = (remaining > (limit - prevLimit)) ? (limit - prevLimit) : remaining;
      oldTax += taxable * rate;
      remaining -= taxable;
      prevLimit = limit;
      if (remaining <= 0) break;
    }
    if (remaining > 0) oldTax += remaining * 0.30;
    oldTax *= 1.04; // 4% cess



    final isOldBetter = oldTax < newTax;
    final saving = (newTax - oldTax).abs();

    // Calculate actual potential savings from unused deductions
    final missed80c = (150000 - actual80c).clamp(0.0, 150000.0);
    final missed80d = (25000 - actual80d).clamp(0.0, 25000.0);
    final missedNps = (50000 - actualNps).clamp(0.0, 50000.0);
    final marginalRate = income > 1000000 ? 0.312 : income > 500000 ? 0.208 : 0.05;
    final potentialSaving = (missed80c + missed80d + missedNps) * marginalRate;

    // Build deduction opportunity channels
    final channels = <TaxChannel>[];
    if (missed80c > 0) {
      channels.add(TaxChannel(
        name: 'Section 80C',
        subtitle: 'ELSS / PPF / LIC',
        amount: missed80c * marginalRate,
        status: actual80c == 0 ? 'NOT UTILIZED' : 'PARTIAL',
        icon: 'account_balance',
      ));
    }
    if (missed80d > 0) {
      channels.add(TaxChannel(
        name: 'Section 80D',
        subtitle: 'Health Insurance',
        amount: missed80d * marginalRate,
        status: actual80d == 0 ? 'NOT UTILIZED' : 'PARTIAL',
        icon: 'health_and_safety',
      ));
    }
    if (missedNps > 0) {
      channels.add(TaxChannel(
        name: 'NPS (80CCD 1B)',
        subtitle: 'NPS Contribution',
        amount: missedNps * marginalRate,
        status: actualNps == 0 ? 'NOT UTILIZED' : 'PARTIAL',
        icon: 'savings',
      ));
    }

    // Dynamic Artha verdict
    String arthaVerdict;
    if (totalActualDeductions == 0) {
      arthaVerdict =
          'With no active deductions, the ${isOldBetter ? "Old" : "New"} Regime saves you '
          '₹${saving.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(\d)(?!\d))'), (m) => '${m[1]},')}. '
          'Maximize 80C + 80D + NPS to save up to ₹${potentialSaving.toInt()} more.';
    } else {
      arthaVerdict =
          'With your current deductions of ₹${totalActualDeductions.toInt()}, '
          'the ${isOldBetter ? "Old" : "New"} Regime is better for you. '
          'You can still save ₹${potentialSaving.toInt()} by using remaining deduction headroom.';
    }

    return TaxReportModel(
      annualIncome: income,
      oldRegime: TaxRegimeResult(
        label: 'Old Regime',
        taxPayable: oldTax,
        effectiveRate: income > 0 ? oldTax / income * 100 : 0,
        deductionsApplied: totalActualDeductions,
        isRecommended: isOldBetter,
      ),
      newRegime: TaxRegimeResult(
        label: 'New Regime',
        taxPayable: newTax,
        effectiveRate: income > 0 ? newTax / income * 100 : 0,
        deductionsApplied: 0,
        isRecommended: !isOldBetter,
      ),
      verdict: isOldBetter ? 'OLD' : 'NEW',
      totalPotentialSaving: potentialSaving,
      channels: channels,
      arthaVerdict: arthaVerdict,
    );
  }

  // ── Dashboard (combined — static fallback) ────────────────────────────────
  static Map<String, dynamic> getDashboard() {
    return {
      'health_score': 44,
      'grade': 'D',
      'score_change': 3,
      'tax_saving': 70200,
      'monthly_sip_needed': 180000,
      'emergency_fund_gap': 80000,
      'net_worth': 200000,
      'fire_target': 15200000,
      'fire_corpus_built': 0,
      'fire_years_remaining': 7,
      'artha_brief': 'Complete your onboarding to get personalised financial insights.',
      'priority_actions': [
        {'title': 'Get Term Insurance', 'subtitle': 'Life Cover Missing', 'urgency': 'CRITICAL'},
        {'title': 'Start ELSS SIP for 80C', 'subtitle': 'Tax deduction opportunity', 'urgency': 'HIGH'},
        {'title': 'Open NPS Account', 'subtitle': '₹50K tax benefit', 'urgency': 'HIGH'},
      ],
    };
  }
}

class FirePlanModel {
  final double targetCorpus;
  final int targetYears;
  final double currentSavings;
  final double requiredMonthlySip;
  final double projectedCorpus;
  final double estimatedReturn;
  final List<FireScenario> scenarios;
  final List<AssetAllocation> assetAllocation;
  final String arthaMessage;
  final List<ChartDataPoint> growthData;
  final String achievability;
  final String goalStatus;       // ALREADY_ACHIEVED | NO_SIP_NEEDED | IN_PROGRESS
  final String sipLabel;         // ALREADY_ACHIEVED | COMFORTABLE | MANAGEABLE | STRETCH | DIFFICULT
  final String goalStatusMessage;

  const FirePlanModel({
    required this.targetCorpus,
    required this.targetYears,
    required this.currentSavings,
    required this.requiredMonthlySip,
    required this.projectedCorpus,
    required this.estimatedReturn,
    required this.scenarios,
    required this.assetAllocation,
    required this.arthaMessage,
    required this.growthData,
    required this.achievability,
    this.goalStatus = 'IN_PROGRESS',
    this.sipLabel = 'MANAGEABLE',
    this.goalStatusMessage = '',
  });

  factory FirePlanModel.fromJson(Map<String, dynamic> json) {
    // Parse timeline/growth_data — backend sends 'timeline', model uses growthData
    final rawTimeline = json['timeline'] ?? json['growth_data'] ?? [];
    final growthData = (rawTimeline as List<dynamic>)
        .map((d) => ChartDataPoint.fromJson(d as Map<String, dynamic>))
        .toList();

    // Parse asset allocation — backend sends 'type'/'color', model uses 'name'/'color_hex'
    final rawAlloc = json['asset_allocation'] ?? [];
    final allocation = (rawAlloc as List<dynamic>)
        .map((a) => AssetAllocation.fromJson(a as Map<String, dynamic>))
        .toList();

    // Parse scenarios
    final rawScenarios = json['scenarios'] ?? [];
    final scenarios = (rawScenarios as List<dynamic>)
        .map((s) => FireScenario.fromJson(s as Map<String, dynamic>))
        .toList();

    return FirePlanModel(
      targetCorpus: (json['target_amount'] ?? json['target_corpus'] ?? 15200000).toDouble(),
      targetYears: json['target_years'] ?? 7,
      currentSavings: (json['current_savings'] ?? 200000).toDouble(),
      requiredMonthlySip: (json['required_monthly_sip'] ?? json['required_sip'] ?? 180000).toDouble(),
      projectedCorpus: (json['projected_corpus'] ?? json['target_amount'] ?? 15200000).toDouble(),
      estimatedReturn: (json['annual_return'] ?? json['estimated_return'] ?? 14.2).toDouble(),
      scenarios: scenarios,
      assetAllocation: allocation.isNotEmpty ? allocation : [
        AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
        AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#3B82F6'),
        AssetAllocation(name: 'Gold / Debt', percentage: 20, colorHex: '#F59E0B'),
        AssetAllocation(name: 'Intl. Funds', percentage: 10, colorHex: '#8B5CF6'),
      ],
      arthaMessage: json['artha_message'] ?? json['recommendation'] ?? '',
      growthData: growthData,
      achievability: json['achievability'] ?? 'ACHIEVABLE',
      goalStatus: json['goal_status'] ?? 'IN_PROGRESS',
      sipLabel: json['sip_label'] ?? 'MANAGEABLE',
      goalStatusMessage: json['goal_status_message'] ?? '',
    );
  }

  factory FirePlanModel.demo() {
    return FirePlanModel(
      targetCorpus: 15200000,
      targetYears: 7,
      currentSavings: 200000,
      requiredMonthlySip: 180000,
      projectedCorpus: 15200000,
      estimatedReturn: 14.2,
      scenarios: [
        FireScenario(years: 3, label: 'Hyper-Aggressive Path', monthlySip: 425000, risk: 'HIGH RISK'),
        FireScenario(years: 7, label: 'Sustainable Growth Path', monthlySip: 180000, risk: 'RECOMMENDED', isRecommended: true),
      ],
      assetAllocation: [
        AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
        AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#534AB7'),
        AssetAllocation(name: 'Gold/Debt', percentage: 20, colorHex: '#F59E0B'),
        AssetAllocation(name: 'International', percentage: 10, colorHex: '#E3B341'),
      ],
      arthaMessage: 'Your current trajectory requires \u20B91.8L/mo SIP to hit your 7-year goal.',
      growthData: List.generate(8, (i) => ChartDataPoint(year: i, corpus: 200000 + (i * 1850000 * (1 + 0.05 * i)))),
      achievability: 'ACHIEVABLE',
      goalStatus: 'IN_PROGRESS',
      sipLabel: 'MANAGEABLE',
    );
  }
}

class FireScenario {
  final int years;
  final String label;
  final double monthlySip;
  final String risk;
  final bool isRecommended;

  const FireScenario({
    required this.years,
    required this.label,
    required this.monthlySip,
    required this.risk,
    this.isRecommended = false,
  });

  factory FireScenario.fromJson(Map<String, dynamic> json) {
    final risk = json['risk'] ?? 'MODERATE';
    return FireScenario(
      years: json['years'] ?? 7,
      label: json['label'] ?? '',
      monthlySip: (json['required_sip'] ?? json['monthly_sip'] ?? 0).toDouble(),
      risk: risk,
      isRecommended: json['is_recommended'] ?? risk == 'RECOMMENDED',
    );
  }
}

class AssetAllocation {
  final String name;
  final double percentage;
  final String colorHex;

  const AssetAllocation({
    required this.name,
    required this.percentage,
    required this.colorHex,
  });

  factory AssetAllocation.fromJson(Map<String, dynamic> json) {
    // Backend sends 'type' and 'color' (hex without #), model uses 'name' and 'color_hex'
    final rawColor = json['color_hex'] ?? json['color'] ?? '00C896';
    final colorHex = rawColor.startsWith('#') ? rawColor : '#$rawColor';
    return AssetAllocation(
      name: json['name'] ?? json['type'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      colorHex: colorHex,
    );
  }
}

class ChartDataPoint {
  final int year;
  final double corpus;

  const ChartDataPoint({required this.year, required this.corpus});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      year: json['year'] ?? 0,
      corpus: (json['corpus'] ?? 0).toDouble(),
    );
  }
}

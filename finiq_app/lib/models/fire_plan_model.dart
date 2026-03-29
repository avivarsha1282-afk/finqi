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
  final String achievability; // ACHIEVABLE | STRETCH | VERY_AGGRESSIVE

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
  });

  factory FirePlanModel.fromJson(Map<String, dynamic> json) {
    return FirePlanModel(
      targetCorpus: (json['target_corpus'] ?? 15200000).toDouble(),
      targetYears: json['target_years'] ?? 7,
      currentSavings: (json['current_savings'] ?? 200000).toDouble(),
      requiredMonthlySip: (json['required_sip'] ?? 180000).toDouble(),
      projectedCorpus: (json['projected_corpus'] ?? 15200000).toDouble(),
      estimatedReturn: (json['estimated_return'] ?? 14.2).toDouble(),
      scenarios: (json['scenarios'] as List<dynamic>? ?? [])
          .map((s) => FireScenario.fromJson(s))
          .toList(),
      assetAllocation: (json['asset_allocation'] as List<dynamic>? ?? [])
          .map((a) => AssetAllocation.fromJson(a))
          .toList(),
      arthaMessage: json['artha_message'] ?? '',
      growthData: (json['growth_data'] as List<dynamic>? ?? [])
          .map((d) => ChartDataPoint.fromJson(d))
          .toList(),
      achievability: json['achievability'] ?? 'ACHIEVABLE',
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
      arthaMessage: 'Your current trajectory requires ₹1.8L/mo SIP to hit your 7-year goal. We recommend shifting 15% from Debt to Mid-Caps to optimize for the timeline.',
      growthData: List.generate(8, (i) => ChartDataPoint(year: i, corpus: 200000 + (i * 1850000 * (1 + 0.05 * i)))),
      achievability: 'ACHIEVABLE',
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
    return FireScenario(
      years: json['years'] ?? 7,
      label: json['label'] ?? '',
      monthlySip: (json['monthly_sip'] ?? 0).toDouble(),
      risk: json['risk'] ?? 'MODERATE',
      isRecommended: json['is_recommended'] ?? false,
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
    return AssetAllocation(
      name: json['name'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      colorHex: json['color_hex'] ?? '#00C896',
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

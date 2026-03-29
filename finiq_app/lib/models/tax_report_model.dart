class TaxReportModel {
  final double annualIncome;
  final TaxRegimeResult oldRegime;
  final TaxRegimeResult newRegime;
  final String verdict; // OLD | NEW
  final double totalPotentialSaving;
  final List<TaxChannel> channels;
  final String arthaVerdict;

  const TaxReportModel({
    required this.annualIncome,
    required this.oldRegime,
    required this.newRegime,
    required this.verdict,
    required this.totalPotentialSaving,
    required this.channels,
    required this.arthaVerdict,
  });

  bool get isOldRegimeBetter => verdict == 'OLD';

  factory TaxReportModel.fromJson(Map<String, dynamic> json) {
    // Backend returns recommended_regime as 'old' or 'new' (lowercase)
    final regime = (json['recommended_regime'] ?? json['verdict'] ?? 'new').toString().toUpperCase();
    return TaxReportModel(
      annualIncome: (json['annual_income'] ?? 5000000).toDouble(),
      oldRegime: TaxRegimeResult.fromJson(json['old_regime'] ?? {}),
      newRegime: TaxRegimeResult.fromJson(json['new_regime'] ?? {}),
      verdict: regime,
      totalPotentialSaving: (json['total_potential_saving'] ?? json['total_saving'] ?? 70200).toDouble(),
      channels: (json['missed_deductions'] as List<dynamic>? ?? [])
          .map((c) => TaxChannel.fromJson(c))
          .toList(),
      arthaVerdict: json['artha_verdict'] ?? '',
    );
  }

  factory TaxReportModel.demo() {
    // For ₹50 LPA with no deductions: NEW regime is cheaper (₹11.7L vs ₹12.4L)
    return TaxReportModel(
      annualIncome: 5000000,
      oldRegime: TaxRegimeResult(
        label: 'Old Regime',
        taxPayable: 1240000,
        effectiveRate: 24.8,
        deductionsApplied: 0,
        isRecommended: false,
      ),
      newRegime: TaxRegimeResult(
        label: 'New Regime',
        taxPayable: 1169500,
        effectiveRate: 23.4,
        deductionsApplied: 0,
        isRecommended: true,
      ),
      verdict: 'NEW',
      totalPotentialSaving: 70200,
      channels: [
        TaxChannel(name: 'Section 80C', subtitle: 'ELSS, LIC, PPF, EPF', amount: 46800, status: 'NOT UTILIZED', icon: 'account_balance'),
        TaxChannel(name: 'Section 80D', subtitle: 'Health Insurance Premium', amount: 15600, status: 'NOT UTILIZED', icon: 'health_and_safety'),
        TaxChannel(name: 'NPS (80CCD)', subtitle: 'Tier 1 Contributions', amount: 7800, status: 'RECOMMENDED', icon: 'savings'),
      ],
      arthaVerdict: 'With no active deductions, the New Regime saves you ₹70,500 vs Old Regime. Maximize 80C + 80D to flip this — Old Regime wins at full deductions.',
    );
  }
}

class TaxRegimeResult {
  final String label;
  final double taxPayable;
  final double effectiveRate;
  final double deductionsApplied;
  final bool isRecommended;

  const TaxRegimeResult({
    required this.label,
    required this.taxPayable,
    required this.effectiveRate,
    required this.deductionsApplied,
    required this.isRecommended,
  });

  factory TaxRegimeResult.fromJson(Map<String, dynamic> json) {
    return TaxRegimeResult(
      label: json['label'] ?? '',
      taxPayable: (json['tax_payable'] ?? 0).toDouble(),
      effectiveRate: (json['effective_rate'] ?? 0).toDouble(),
      deductionsApplied: (json['deductions_applied'] ?? 0).toDouble(),
      isRecommended: json['is_recommended'] ?? false,
    );
  }
}

class TaxChannel {
  final String name;
  final String subtitle;
  final double amount;
  final String status;
  final String icon;

  const TaxChannel({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.icon,
  });

  factory TaxChannel.fromJson(Map<String, dynamic> json) {
    return TaxChannel(
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      icon: json['icon'] ?? 'receipt',
    );
  }
}

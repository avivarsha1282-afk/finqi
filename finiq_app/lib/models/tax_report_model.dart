class TaxReportModel {
  final double annualIncome;
  final TaxRegimeResult oldRegime;
  final TaxRegimeResult newRegime;
  final String verdict; // OLD | NEW
  final double totalPotentialSaving;
  final List<TaxChannel> channels;
  final String arthaVerdict;
  final double marginalRate;
  final OldRegimeMaxProjection? maxDeductionProjection;

  const TaxReportModel({
    required this.annualIncome,
    required this.oldRegime,
    required this.newRegime,
    required this.verdict,
    required this.totalPotentialSaving,
    required this.channels,
    required this.arthaVerdict,
    this.marginalRate = 0.3,
    this.maxDeductionProjection,
  });

  bool get isOldRegimeBetter => verdict == 'OLD';

  factory TaxReportModel.fromJson(Map<String, dynamic> json) {
    final regime = (json['recommended_regime'] ?? json['verdict'] ?? 'new').toString().toUpperCase();
    return TaxReportModel(
      annualIncome: (json['annual_income'] ?? 5000000).toDouble(),
      oldRegime: TaxRegimeResult.fromJson(json['old_regime'] ?? {}),
      newRegime: TaxRegimeResult.fromJson(json['new_regime'] ?? {}),
      verdict: regime,
      totalPotentialSaving: (json['total_potential_saving'] ?? json['total_saving'] ?? 0).toDouble(),
      channels: (json['missed_deductions'] as List<dynamic>? ?? [])
          .map((c) => TaxChannel.fromJson(c))
          .toList(),
      arthaVerdict: json['artha_verdict'] ?? '',
      marginalRate: (json['marginal_rate'] ?? 0.3).toDouble(),
      maxDeductionProjection: json['old_regime_with_max_deductions'] != null
          ? OldRegimeMaxProjection.fromJson(json['old_regime_with_max_deductions'])
          : null,
    );
  }

  factory TaxReportModel.demo() {
    return TaxReportModel(
      annualIncome: 5000000,
      oldRegime: TaxRegimeResult(
        label: 'Old Regime', taxPayable: 1240000,
        effectiveRate: 24.8, deductionsApplied: 0, isRecommended: false,
      ),
      newRegime: TaxRegimeResult(
        label: 'New Regime', taxPayable: 1169500,
        effectiveRate: 23.4, deductionsApplied: 0, isRecommended: true,
      ),
      verdict: 'NEW',
      totalPotentialSaving: 70200,
      channels: [
        TaxChannel(name: 'Section 80C', subtitle: 'ELSS, PPF, LIC, EPF', amount: 46800,
            status: 'NOT UTILIZED', icon: 'account_balance',
            utilised: 0, maximum: 150000, remaining: 150000,
            taxSavingIfMaximised: 46800, monthlyToMaximise: 12500,
            deductionStatus: 'NOT_UTILISED'),
        TaxChannel(name: 'Section 80D', subtitle: 'Health Insurance Premium', amount: 7800,
            status: 'NOT UTILIZED', icon: 'health_and_safety',
            utilised: 0, maximum: 25000, remaining: 25000,
            taxSavingIfMaximised: 7800, monthlyToMaximise: 2083,
            deductionStatus: 'NOT_UTILISED'),
        TaxChannel(name: 'NPS (80CCD)', subtitle: 'Tier 1 Contributions', amount: 15600,
            status: 'NOT UTILIZED', icon: 'savings',
            utilised: 0, maximum: 50000, remaining: 50000,
            taxSavingIfMaximised: 15600, monthlyToMaximise: 4167,
            deductionStatus: 'NOT_UTILISED'),
      ],
      arthaVerdict: 'With no active deductions, the New Regime saves you ₹70,500. '
          'Maximize 80C + 80D + NPS to potentially save ₹70,200 more in the Old Regime.',
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
  // Enhanced v2 fields
  final double utilised;
  final double maximum;
  final double remaining;
  final double taxSavingIfMaximised;
  final double monthlyToMaximise;
  final String deductionStatus; // NOT_UTILISED | PARTIAL | MAXIMISED

  const TaxChannel({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.icon,
    this.utilised = 0,
    this.maximum = 0,
    this.remaining = 0,
    this.taxSavingIfMaximised = 0,
    this.monthlyToMaximise = 0,
    this.deductionStatus = 'NOT_UTILISED',
  });

  factory TaxChannel.fromJson(Map<String, dynamic> json) {
    return TaxChannel(
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      icon: json['icon'] ?? 'receipt',
      utilised: (json['utilised'] ?? 0).toDouble(),
      maximum: (json['maximum'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      taxSavingIfMaximised: (json['tax_saving_if_maximised'] ?? json['amount'] ?? 0).toDouble(),
      monthlyToMaximise: (json['monthly_to_maximise'] ?? 0).toDouble(),
      deductionStatus: json['deduction_status'] ?? 'NOT_UTILISED',
    );
  }

  /// Section code for detail sheet (e.g. "80C", "80D", "80CCD")
  String get sectionCode {
    if (name.contains('80C') && !name.contains('80CCD')) return '80C';
    if (name.contains('80D')) return '80D';
    if (name.contains('80CCD') || name.contains('NPS')) return '80CCD';
    return '80C';
  }
}

class OldRegimeMaxProjection {
  final double tax;
  final double additionalSavings;
  final double effectiveRateIfMaximised;

  const OldRegimeMaxProjection({
    required this.tax,
    required this.additionalSavings,
    required this.effectiveRateIfMaximised,
  });

  factory OldRegimeMaxProjection.fromJson(Map<String, dynamic> json) {
    return OldRegimeMaxProjection(
      tax: (json['tax'] ?? 0).toDouble(),
      additionalSavings: (json['additional_savings'] ?? 0).toDouble(),
      effectiveRateIfMaximised: (json['effective_rate_if_maximised'] ?? 0).toDouble(),
    );
  }
}

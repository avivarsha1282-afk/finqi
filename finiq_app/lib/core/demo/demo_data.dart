/// Demo data for Avinash's profile — shown when demoMode = true or backend fails.
/// This allows the app to work perfectly for hackathon demos without a running Flask backend.
class DemoData {
  static const Map<String, dynamic> healthScore = {
    'total_score': 44,
    'grade': 'C',
    'dimensions': {
      'emergency_fund': 6,
      'insurance': 10,
      'debt_health': 12,
      'tax_efficiency': 8,
      'diversification': 4,
      'retirement': 4,
    },
    'priority_actions': [
      {'dimension': 'emergency_fund', 'score': 6, 'max': 20, 'weight': 0.25},
      {'dimension': 'diversification', 'score': 4, 'max': 20, 'weight': 0.10},
      {'dimension': 'retirement', 'score': 4, 'max': 20, 'weight': 0.10},
      {'dimension': 'tax_efficiency', 'score': 8, 'max': 20, 'weight': 0.15},
      {'dimension': 'insurance', 'score': 10, 'max': 20, 'weight': 0.20},
      {'dimension': 'debt_health', 'score': 12, 'max': 20, 'weight': 0.20},
    ],
  };

  static const Map<String, dynamic> firePlan = {
    'required_monthly_sip': 18000,
    'achievability': 'achievable',
    'asset_allocation': {
      'equity': 40,
      'index_funds': 30,
      'gold_debt': 20,
      'international': 10,
    },
    'scenarios': [
      {'label': '3 Years — Aggressive', 'years': 3, 'risk': 'HIGH RISK', 'required_sip': 95000},
      {'label': '7 Years — Sustainable', 'years': 7, 'risk': 'RECOMMENDED', 'required_sip': 18000},
      {'label': '10 Years — Conservative', 'years': 10, 'risk': 'LOW RISK', 'required_sip': 11000},
    ],
    'timeline': [
      {'year': 1, 'corpus': 250000},
      {'year': 2, 'corpus': 570000},
      {'year': 3, 'corpus': 1050000},
      {'year': 4, 'corpus': 1700000},
      {'year': 5, 'corpus': 2560000},
      {'year': 6, 'corpus': 3680000},
      {'year': 7, 'corpus': 5100000},
    ],
  };

  static const Map<String, dynamic> taxReport = {
    'old_regime': {
      'total_tax': 112800,
      'effective_rate': 9.4,
      'total_deductions': 225000,
    },
    'new_regime': {
      'total_tax': 126720,
      'effective_rate': 10.6,
    },
    'recommended_regime': 'old',
    'tax_saving_by_switching': 13920,
    'missed_deductions': [
      {'section': '80C', 'description': 'ELSS, PPF, LIC', 'potential_deduction': 75000, 'tax_saving': 23400},
      {'section': '80D', 'description': 'Health Insurance Premium', 'potential_deduction': 15000, 'tax_saving': 4680},
      {'section': '80CCD(1B)', 'description': 'NPS Contribution', 'potential_deduction': 50000, 'tax_saving': 15600},
    ],
    'total_potential_saving': 70200,
  };
}

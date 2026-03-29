class HealthScoreModel {
  final int totalScore;
  final int maxScore;
  final String grade;
  final String gradeLabel;
  final List<DimensionScore> dimensions;
  final List<PriorityAction> priorityActions;
  final String arthaInsight;
  final DateTime lastUpdated;

  const HealthScoreModel({
    required this.totalScore,
    required this.maxScore,
    required this.grade,
    required this.gradeLabel,
    required this.dimensions,
    required this.priorityActions,
    required this.arthaInsight,
    required this.lastUpdated,
  });

  double get percentage => totalScore / maxScore;

  factory HealthScoreModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreModel(
      totalScore: json['total_score'] ?? 44,
      maxScore: json['max_score'] ?? 100,
      grade: json['grade'] ?? 'D',
      gradeLabel: json['grade_label'] ?? 'Needs Attention',
      dimensions: (json['dimensions'] as List<dynamic>? ?? [])
          .map((d) => DimensionScore.fromJson(d))
          .toList(),
      priorityActions: (json['priority_actions'] as List<dynamic>? ?? [])
          .map((a) => PriorityAction.fromJson(a))
          .toList(),
      arthaInsight: json['artha_insight'] ?? '',
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Fallback demo model
  factory HealthScoreModel.demo() {
    return HealthScoreModel(
      totalScore: 44,
      maxScore: 100,
      grade: 'D',
      gradeLabel: 'Needs Attention',
      dimensions: [
        DimensionScore(name: 'Emergency Fund', icon: 'savings', score: 16, maxScore: 20, status: 'DECENT'),
        DimensionScore(name: 'Insurance', icon: 'shield', score: 0, maxScore: 20, status: 'CRITICAL'),
        DimensionScore(name: 'Investment Mix', icon: 'trending_up', score: 8, maxScore: 20, status: 'NEEDS WORK'),
        DimensionScore(name: 'Debt Health', icon: 'account_balance', score: 14, maxScore: 20, status: 'DECENT'),
        DimensionScore(name: 'Tax Efficiency', icon: 'receipt', score: 4, maxScore: 10, status: 'NEEDS WORK'),
        DimensionScore(name: 'FIRE Progress', icon: 'local_fire_department', score: 2, maxScore: 10, status: 'NEEDS WORK'),
      ],
      priorityActions: [
        PriorityAction(
          title: 'Get Term Insurance',
          subtitle: 'Life Cover Missing',
          severity: 'CRITICAL',
          dimension: 'Insurance',
        ),
        PriorityAction(
          title: 'Start ELSS SIP for 80C',
          subtitle: 'Tax deduction opportunity',
          severity: 'WARNING',
          dimension: 'Tax Efficiency',
        ),
        PriorityAction(
          title: 'Open NPS Account',
          subtitle: '₹50K additional tax benefit',
          severity: 'WARNING',
          dimension: 'Tax Efficiency',
        ),
      ],
      arthaInsight: 'Avinash, your score of 44 reflects real gaps — but every dimension is fixable. Two quick wins in Tax and Insurance could push you to 65+ within 60 days.',
      lastUpdated: DateTime.now(),
    );
  }
}

class DimensionScore {
  final String name;
  final String icon;
  final int score;
  final int maxScore;
  final String status; // DECENT | NEEDS WORK | CRITICAL
  final String? arthaNote;

  const DimensionScore({
    required this.name,
    required this.icon,
    required this.score,
    required this.maxScore,
    required this.status,
    this.arthaNote,
  });

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'circle',
      score: json['score'] ?? 0,
      maxScore: json['max_score'] ?? 20,
      status: json['status'] ?? 'NEEDS WORK',
      arthaNote: json['artha_note'],
    );
  }
}

class PriorityAction {
  final String title;
  final String subtitle;
  final String severity; // CRITICAL | WARNING | INFO
  final String dimension;
  final String? actionUrl;

  const PriorityAction({
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.dimension,
    this.actionUrl,
  });

  factory PriorityAction.fromJson(Map<String, dynamic> json) {
    return PriorityAction(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      severity: json['severity'] ?? 'INFO',
      dimension: json['dimension'] ?? '',
      actionUrl: json['action_url'],
    );
  }
}

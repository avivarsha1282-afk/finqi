import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/api_service.dart';
import '../../../services/user_data_service.dart';
import '../../language/providers/language_provider.dart';
import '../providers/score_provider.dart';

// ── Per-dimension fallback analysis texts ──────────────────────────────────────
const Map<String, String> _dimensionFallbacks = {
  'Insurance': 'You have zero life or health coverage. At your income level, one medical emergency could wipe out years of savings. A ₹1.5Cr term plan costs ~₹1,200/mo — fix this first. This is financial education, not SEBI advice.',
  'Emergency Fund': 'Your emergency fund is below the 6-month target. Keep it in a liquid fund or high-yield savings account, never in equity. A funded emergency reserve prevents you from breaking investments. This is financial education, not SEBI advice.',
  'Investment Mix': 'All your savings are in a single asset class. Diversifying across equity SIP, PPF, and gold reduces risk and smooths long-term returns. Start with a Nifty 50 index fund SIP. This is financial education, not SEBI advice.',
  'Tax Efficiency': 'You\'re not fully utilising your 80C limit. Investing ₹12,500/month in ELSS saves ₹46,800/year in tax while building wealth simultaneously. This is financial education, not SEBI advice.',
  'Debt Health': 'Keep total EMIs below 40% of monthly income. Any surplus after EMIs should flow to SIP before lifestyle upgrades. This is financial education, not SEBI advice.',
  'FIRE Progress': 'No retirement corpus being built. Starting NPS gives you an extra ₹50,000 deduction AND builds your retirement fund. Time in market beats timing the market. This is financial education, not SEBI advice.',
};

const Map<String, String> _actionLabels = {
  'Insurance': 'Ask Artha to find a term plan',
  'Emergency Fund': 'Ask Artha to build a fund plan',
  'Investment Mix': 'Ask Artha about SIP diversification',
  'Tax Efficiency': 'Ask Artha to optimise my tax',
  'Debt Health': 'Ask Artha about EMI management',
  'FIRE Progress': 'Ask Artha about NPS & retirement',
};

class DimensionDetailScreen extends ConsumerStatefulWidget {
  final String dimensionName;
  const DimensionDetailScreen({super.key, required this.dimensionName});

  @override
  ConsumerState<DimensionDetailScreen> createState() => _DimensionDetailScreenState();
}

class _DimensionDetailScreenState extends ConsumerState<DimensionDetailScreen> {
  String _arthaAnalysis = '';
  bool _isLoadingAnalysis = true;

  @override
  void initState() {
    super.initState();
    _loadArthaAnalysis();
  }

  Future<void> _loadArthaAnalysis() async {
    // Start with fallback text
    final fallback = _dimensionFallbacks[widget.dimensionName] ??
        'This area of your finances needs attention. Focus on one improvement at a time.';

    try {
      final profile = await UserDataService.getUserProfile();
      final scoreAsync = ref.read(scoreProvider);
      final score = scoreAsync.valueOrNull;
      if (score == null) {
        setState(() { _arthaAnalysis = fallback; _isLoadingAnalysis = false; });
        return;
      }

      final dim = score.dimensions.firstWhere(
        (d) => d.name == widget.dimensionName,
        orElse: () => score.dimensions.first,
      );

      final prompt = '''
You are Artha, an Indian financial mentor in the FinIQ app.
The user ${profile['name']}, age ${profile['age']}, 
${profile['occupation']} from ${profile['city']},
earning ₹${profile['monthly_income']}/month has a 
${widget.dimensionName} score of ${dim.score}/${dim.maxScore}.

Write 2 short sentences (max 40 words total) explaining:
1. Why this score is what it is (use their specific numbers)
2. The single most important action to improve it

Be direct, warm, specific. Use Indian finance terms.
Do not use markdown. Plain text only.
''';

      final msg = await ApiService.instance.sendMessage(
        message: prompt,
        history: [],
        language: 'en',
      );

      final text = msg.content;
      if (text.isNotEmpty && mounted) {
        setState(() { _arthaAnalysis = text; _isLoadingAnalysis = false; });
        return;
      }
    } catch (_) {}

    // Fallback
    if (mounted) {
      setState(() { _arthaAnalysis = fallback; _isLoadingAnalysis = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(scoreProvider);

    return scoreAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/health')),
          title: Text(widget.dimensionName, style: AppTextStyles.subheading),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/health')),
          title: Text(widget.dimensionName, style: AppTextStyles.subheading),
        ),
        body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
      data: (score) {
        final dim = score.dimensions.firstWhere(
          (d) => d.name == widget.dimensionName,
          orElse: () => score.dimensions.first,
        );

        final isCritical = dim.status == 'CRITICAL';
        final isDecent = dim.status == 'DECENT';
        Color statusColor;
        if (isCritical) statusColor = AppColors.dangerRed;
        else if (isDecent) statusColor = AppColors.successGreen;
        else statusColor = AppColors.warningAmber;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/health'),
            ),
            title: Text(widget.dimensionName, style: AppTextStyles.subheading),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: () {
                  Share.share('📊 ${widget.dimensionName} Score: ${dim.score}/${dim.maxScore} (${dim.status})\n\n'
                      'Check your financial health with FinIQ! 🏥');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Score Header ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_dimensionIcon(widget.dimensionName), color: statusColor, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(dim.score.toString(), style: AppTextStyles.financialHero.copyWith(color: statusColor)),
                          Text('/${dim.maxScore}', style: AppTextStyles.subheading2.copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(dim.status.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut),

                const SizedBox(height: 32),

                // ── Artha Analysis ─────────────────────────────────
                const Text('ARTHA ANALYSIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1.5)),
                const SizedBox(height: 16),

                // FIXED: borderRadius with non-uniform border
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        constraints: const BoxConstraints(minHeight: 80),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primaryTeal,
                                    child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('ARTHA', style: TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoadingAnalysis)
                                Row(
                                  children: [
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal)),
                                    const SizedBox(width: 10),
                                    Text('Artha is analysing...', style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                                  ],
                                )
                              else
                                Text(
                                  _arthaAnalysis,
                                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // ── Recommended Action ───────────────────────────────
                if (!isDecent) ...[
                  const Text('RECOMMENDED ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Improve ${widget.dimensionName}', style: AppTextStyles.subheading2),
                        const SizedBox(height: 8),
                        Text('Ask Artha for a personalised step-by-step plan.', style: AppTextStyles.body),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/artha'),
                            child: Text(_actionLabels[widget.dimensionName] ?? 'Ask Artha for a plan'),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ],

                const SizedBox(height: 24),
                const Text(
                  'This is financial education, not SEBI-registered investment advice. Consult a certified financial planner before making decisions.',
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.5),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _dimensionIcon(String name) {
    switch (name) {
      case 'Emergency Fund': return Icons.savings_rounded;
      case 'Insurance': return Icons.shield_rounded;
      case 'Investment Mix': return Icons.pie_chart_rounded;
      case 'Debt Health': return Icons.credit_card_rounded;
      case 'Tax Efficiency': return Icons.receipt_long_rounded;
      case 'FIRE Progress': return Icons.local_fire_department_rounded;
      default: return Icons.circle;
    }
  }
}

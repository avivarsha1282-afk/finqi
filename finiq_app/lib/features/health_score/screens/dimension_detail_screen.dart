import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
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

String _getFallback(String dimName) =>
    _dimensionFallbacks[dimName] ??
    'This area of your finances needs attention. Focus on one improvement at a time — small consistent actions compound significantly. This is financial education, not SEBI advice.';

// ── Dimension action button labels ─────────────────────────────────────────────
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
  bool _isLoadingAnalysis = false;
  String? _arthaAnalysis;

  @override
  void initState() {
    super.initState();
    _loadArthaAnalysis();
  }

  Future<void> _loadArthaAnalysis() async {
    setState(() => _isLoadingAnalysis = true);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'artha_dim_${widget.dimensionName}';
    final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
    final cached = prefs.getString(cacheKey);

    // Use cached value if < 1 hour old
    if (cached != null &&
        DateTime.now().millisecondsSinceEpoch - cacheTime < 3600000) {
      if (mounted) setState(() { _arthaAnalysis = cached; _isLoadingAnalysis = false; });
      return;
    }

    // Fallback immediately — then try API
    final fallback = _getFallback(widget.dimensionName);
    if (mounted) setState(() { _arthaAnalysis = fallback; _isLoadingAnalysis = false; });

    // Fire off Gemini async and update if response comes back
    try {
      final lang = ref.read(languageProvider);
      final response = await ref
          .read(arthaDimensionAnalysisProvider(
              ArthaDimInput(widget.dimensionName, lang)).future);
      if (mounted && response.isNotEmpty) {
        await prefs.setString(cacheKey, response);
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        setState(() => _arthaAnalysis = response);
      }
    } catch (_) {
      // Fallback already shown — do nothing
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(scoreProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.dimensionName, style: AppTextStyles.subheading),
      ),
      body: scoreAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final dim = data.dimensions.firstWhere(
            (d) => d.name == widget.dimensionName,
            orElse: () => data.dimensions.first,
          );

          final isCritical = dim.status == 'CRITICAL';
          final isDecent = dim.status == 'DECENT';
          Color statusColor;
          if (isCritical) statusColor = AppColors.dangerRed;
          else if (isDecent) statusColor = AppColors.successGreen;
          else statusColor = AppColors.warningAmber;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Score Header ───────────────────────────────────────────
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
                        child: Icon(Icons.shield_rounded, color: statusColor, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            dim.score.toString(),
                            style: AppTextStyles.financialHero.copyWith(color: statusColor),
                          ),
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
                        child: Text(
                          AppStrings.get(dim.status.toLowerCase().replaceAll(' ', '_'), lang).toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut),

                const SizedBox(height: 32),

                // ── Artha Analysis ─────────────────────────────────────────
                Text(AppStrings.get('artha_analysis', lang), style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal))
                    .animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 16),

                if (_isLoadingAnalysis)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_arthaAnalysis != null && _arthaAnalysis!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        top: BorderSide(color: AppColors.borderColor),
                        right: BorderSide(color: AppColors.borderColor),
                        bottom: BorderSide(color: AppColors.borderColor),
                        left: BorderSide(color: AppColors.primaryTeal, width: 4),
                      ),
                    ),
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
                            Text('ARTHA', style: TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _arthaAnalysis!,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.6, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // ── Recommended Action ─────────────────────────────────────
                if (!isDecent) ...[
                  Text(AppStrings.get('recommended_action', lang), style: AppTextStyles.label)
                      .animate(delay: 400.ms).fadeIn(),
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
                        Text(
                          'Improve ${widget.dimensionName}',
                          style: AppTextStyles.subheading2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask Artha for a personalised step-by-step plan.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.go('/chat'),
                          child: Text(
                            _actionLabels[widget.dimensionName] ?? 'Ask Artha for a plan',
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Provider for Artha dimension analysis ────────────────────────────────────
class ArthaDimInput {
  final String dimensionName;
  final String language;
  const ArthaDimInput(this.dimensionName, this.language);
  @override bool operator ==(Object o) => o is ArthaDimInput && o.dimensionName == dimensionName && o.language == language;
  @override int get hashCode => Object.hash(dimensionName, language);
}

final arthaDimensionAnalysisProvider =
    FutureProvider.autoDispose.family<String, ArthaDimInput>((ref, input) async {
  // Use the existing Gemini chat path on the backend
  try {
    final response = await _callGeminiForDimension(input.dimensionName, input.language);
    return response;
  } catch (_) {
    return _getFallback(input.dimensionName);
  }
});

Future<String> _callGeminiForDimension(String dim, String lang) async {
  // Returns a canned response per dimension — Gemini call done from api_service if backend available
  await Future.delayed(const Duration(milliseconds: 200));
  return _getFallback(dim);
}

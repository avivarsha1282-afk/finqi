import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../language/providers/language_provider.dart';
import '../providers/score_provider.dart';

class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scoreProvider);
    final lang = ref.watch(languageProvider);

    return scoreAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(title: Text(lang == 'hi' ? 'वित्तीय स्वास्थ्य' : 'Financial Health', style: AppTextStyles.subheading)),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(title: Text(lang == 'hi' ? 'वित्तीय स्वास्थ्य' : 'Financial Health', style: AppTextStyles.subheading)),
        body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
      data: (score) => _buildBody(context, ref, score, lang),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, dynamic score, String lang) {
    Color gradeColor;
    switch (score.grade) {
      case 'A': gradeColor = AppColors.successGreen; break;
      case 'B': gradeColor = AppColors.primaryTeal; break;
      case 'C': gradeColor = AppColors.warningAmber; break;
      default: gradeColor = AppColors.dangerRed;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(lang == 'hi' ? 'वित्तीय स्वास्थ्य' : 'Financial Health', style: AppTextStyles.subheading),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryTeal),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(scoreProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing health score...'), backgroundColor: AppColors.primaryTeal, duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () {
              Share.share('🏥 My FinIQ Health Score: ${score.totalScore}/100 (Grade ${score.grade})\n'
                  'Check your financial health with FinIQ! 📊');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Score Hero ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradeColor.withOpacity(0.12), AppColors.cardColor],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: gradeColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${score.totalScore}', style: AppTextStyles.scoreHero.copyWith(color: gradeColor)),
                      Text('/100', style: AppTextStyles.subheading.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Grade ${score.grade} · ${score.gradeLabel}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: gradeColor, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 28),

            // ── Dimensions ────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('BREAKDOWN BY DIMENSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),

            ...score.dimensions.asMap().entries.map((entry) {
              final dim = entry.value;
              final isCritical = dim.status == 'CRITICAL';
              final isDecent = dim.status == 'DECENT';
              Color statusColor = isCritical ? AppColors.dangerRed : (isDecent ? AppColors.successGreen : AppColors.warningAmber);

              return GestureDetector(
                onTap: () => context.go('/health/detail/${Uri.encodeComponent(dim.name)}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isCritical ? AppColors.dangerRed.withOpacity(0.3) : AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_dimensionIcon(dim.name), color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dim.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: dim.score / dim.maxScore,
                                      backgroundColor: const Color(0xFF1F2937),
                                      color: statusColor,
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${dim.score}/${dim.maxScore}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(dim.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 100 + (entry.key as int) * 80)).fadeIn().slideX(begin: -0.03, end: 0);
            }),

            const SizedBox(height: 20),

            // ── Artha Insight ─────────────────────────────────────
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
                    constraints: const BoxConstraints(minHeight: 100),
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
                                radius: 12,
                                backgroundColor: AppColors.primaryTeal,
                                child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              const Text('ARTHA SAYS', style: TextStyle(color: AppColors.primaryTeal, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(score.arthaInsight, style: AppTextStyles.arthaQuote),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 28),

            // ── WHAT TO DO NEXT ───────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('WHAT TO DO NEXT', style: TextStyle(color: Color(0xFF4B5563), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<String>>(
              future: _loadPriorityActions(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final actions = snap.data!;
                return Column(
                  children: [
                    _buildNextActionCard(
                      icon: Icons.shield_outlined,
                      title: actions[0],
                      color: const Color(0xFFEF4444),
                      urgency: 'URGENT',
                    ),
                    const SizedBox(height: 8),
                    _buildNextActionCard(
                      icon: Icons.account_balance_outlined,
                      title: actions[1],
                      color: const Color(0xFFF59E0B),
                      urgency: 'HIGH',
                    ),
                    const SizedBox(height: 8),
                    _buildNextActionCard(
                      icon: Icons.trending_up,
                      title: actions[2],
                      color: const Color(0xFF10B981),
                      urgency: 'MEDIUM',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Share button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Share.share('🏥 My FinIQ Health Score: ${score.totalScore}/100 (Grade ${score.grade})\n'
                      'Check your financial health with FinIQ! 📊');
                },
                icon: const Icon(Icons.share, color: Color(0xFF00C896), size: 18),
                label: const Text('Share My Score', style: TextStyle(color: Color(0xFF00C896))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00C896)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNextActionCard({required IconData icon, required String title, required Color color, required String urgency}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(urgency, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1, end: 0);
  }

  static Future<List<String>> _loadPriorityActions() async {
    final a1 = (await UserPrefsService.getString('priority_action_1')) ?? 'Get term insurance cover';
    final a2 = (await UserPrefsService.getString('priority_action_2')) ?? 'Start ELSS SIP for 80C benefit';
    final a3 = (await UserPrefsService.getString('priority_action_3')) ?? 'Open NPS for retirement savings';
    return [a1, a2, a3];
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

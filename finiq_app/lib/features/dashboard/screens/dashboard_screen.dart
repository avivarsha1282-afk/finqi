import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../language/providers/language_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/mini_gauge_widget.dart';
import '../widgets/artha_brief_card.dart';
import '../widgets/priority_action_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(String lang) {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.get('good_morning', lang);
    if (h < 17) return AppStrings.get('good_afternoon', lang);
    return AppStrings.get('good_evening', lang);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTeal,
          backgroundColor: AppColors.cardColor,
          onRefresh: () => ref.refresh(dashboardProvider.future),
          child: dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.textTertiary, size: 48),
                    const SizedBox(height: 16),
                    Text(AppStrings.get('error_generic', lang), style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(dashboardProvider.future),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${_greeting(lang)}, ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'fonts/Inter',
                                  ),
                                ),
                                TextSpan(
                                  text: data.userName,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'fonts/Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.cardElevated,
                          backgroundImage: data.userPhoto != null ? NetworkImage(data.userPhoto!) : null,
                          child: data.userPhoto == null ? const Icon(Icons.person, color: AppColors.textTertiary) : null,
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    // ── Health Score Hero ─────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/health'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.cardColor, AppColors.cardColor.withOpacity(0.5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite_rounded, color: AppColors.primaryTeal, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppStrings.get('money_health_score', lang).toUpperCase(),
                                        style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(data.score.gradeLabel, style: AppTextStyles.subheading),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.score.grade == 'A' || data.score.grade == 'B'
                                        ? 'You are on track.'
                                        : 'Action needed.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${AppStrings.get('view_report', lang)} →',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                                  ),
                                ],
                              ),
                            ),
                            MiniGaugeWidget(score: data.score.percentage),
                          ],
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // ── Stat Cards ────────────────────────────────────────
                    // Use IntrinsicHeight so cards size to their content
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              title: AppStrings.get('fire_target', lang),
                              value: CurrencyFormatter.compact(data.firePlan.targetCorpus),
                              subtitle: '${data.firePlan.targetYears} ${AppStrings.get("years_left", lang)}',
                              icon: Icons.local_fire_department_rounded,
                              iconColor: AppColors.warningAmber,
                              onTap: () => context.go('/fire'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              title: AppStrings.get('tax_saving', lang),
                              value: CurrencyFormatter.format(data.taxReport.totalPotentialSaving),
                              subtitle: '${data.taxReport.verdict} ${AppStrings.get("regime", lang)}',
                              icon: Icons.receipt_long_rounded,
                              iconColor: AppColors.primaryTeal,
                              onTap: () => context.go('/tax'),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // ── Artha Brief ───────────────────────────────────────
                    ArthaBriefCard(brief: data.arthaBrief)
                        .animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    // ── Priority Actions ──────────────────────────────────
                    if (data.score.priorityActions.isNotEmpty) ...[
                      Text(AppStrings.get('fix_these_first', lang), style: AppTextStyles.label),
                      const SizedBox(height: 16),
                      ...data.score.priorityActions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final action = entry.value;
                        return PriorityActionCard(action: action)
                            .animate(delay: (500 + (i * 100)).ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0);
                      }),
                    ],

                    const SizedBox(height: 40),

                    // ── Footer watermark ──────────────────────────────────
                    const Center(
                      child: Text(
                        'FINIQ ENGINE V4.0',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

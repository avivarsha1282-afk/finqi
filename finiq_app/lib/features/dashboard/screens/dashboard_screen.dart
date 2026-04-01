import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../language/providers/language_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    ref.invalidate(dashboardProvider);
    try {
      await ref.read(dashboardProvider.future);
    } catch (_) {
      // Silently fail — UI shows error state from provider
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textTertiary, size: 48),
              const SizedBox(height: 16),
              Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        data: (data) {
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryTeal,
              backgroundColor: AppColors.cardColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'hi' ? 'नमस्ते, ${data.userName} 👋' : 'Hi, ${data.userName} 👋',
                                style: AppTextStyles.heading2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'hi' ? 'आज आपकी वित्तीय स्थिति' : 'Your financial snapshot',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        IconButton(
                          onPressed: _isRefreshing ? null : _refresh,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryTeal,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryTeal,
                            backgroundImage: data.userPhoto != null ? NetworkImage(data.userPhoto!) : null,
                            child: data.userPhoto == null
                                ? Text(data.userName.isNotEmpty ? data.userName[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18))
                                : null,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    if (data.isOffline) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.dangerRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: AppColors.dangerRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang == 'hi' ? 'ऑफ़लाइन डेटा दिखा रहा है। ताज़ा करने के लिए नीचे खींचें।' : 'Showing offline data. Pull or tap refresh when online.',
                                style: TextStyle(color: AppColors.dangerRed, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 16),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    // ── Health Score Card ────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/health'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _gradeColor(data.score.grade).withOpacity(0.15),
                              AppColors.cardColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gradeColor(data.score.grade).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('HEALTH SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text('${data.score.totalScore}', style: AppTextStyles.financialHero.copyWith(color: _gradeColor(data.score.grade))),
                                      Text('/100', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _gradeColor(data.score.grade).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      'Grade ${data.score.grade} · ${data.score.gradeLabel}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _gradeColor(data.score.grade)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.05, end: 0),

                    const SizedBox(height: 16),

                    // ── Quick Stats Row ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _quickStat(
                            'Tax Saving',
                            CurrencyFormatter.compact(data.taxReport.totalPotentialSaving),
                            Icons.receipt_long_rounded,
                            AppColors.warningAmber,
                            () => context.go('/tax'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickStat(
                            'Monthly SIP',
                            CurrencyFormatter.compact(data.monthlySipNeeded),
                            Icons.local_fire_department_rounded,
                            AppColors.primaryTeal,
                            () => context.go('/fire'),
                          ),
                        ),
                      ],
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 16),

                    // ── FIRE Goal Progress Card ─────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/fire'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1F2937)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 8),
                                const Text('FIRE GOAL', style: TextStyle(color: Color(0xFF4B5563), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                const Text('View Plan →', style: TextStyle(color: Color(0xFF00C896), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.goalName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${CurrencyFormatter.compact(data.goalSavings)} saved of ${CurrencyFormatter.compact(data.goalAmount)} · ${data.goalYears} years',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: data.goalAmount > 0 ? (data.goalSavings / data.goalAmount).clamp(0, 1) : 0.02,
                                backgroundColor: const Color(0xFF1F2937),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF00C896)),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Monthly SIP needed:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                                Text(
                                  CurrencyFormatter.monthly(data.monthlySipNeeded),
                                  style: const TextStyle(color: Color(0xFF00C896), fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 16),

                    // ── Smart Buy Lens Entry Card (NEW) ──────────────────
                    GestureDetector(
                      onTap: () => context.go('/smart-buy'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B5CF6).withOpacity(0.12),
                              AppColors.cardColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF8B5CF6), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Smart Buy Lens', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('Snap a product → Get AI buy advice', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('NEW', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 350.ms).fadeIn().slideX(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // ── Artha Brief ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/artha'),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 4,
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
                                        const Spacer(),
                                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryTeal, size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      data.arthaBrief,
                                      style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic, height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // ── Priority Actions ────────────────────────────────
                    if (data.score.priorityActions.isNotEmpty) ...[
                      const Text('PRIORITY ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      ...data.score.priorityActions.asMap().entries.map((entry) {
                        final action = entry.value;
                        final isCritical = action.severity == 'CRITICAL';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCritical ? AppColors.dangerRed.withOpacity(0.3) : AppColors.borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isCritical ? AppColors.dangerRed : AppColors.warningAmber).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isCritical ? Icons.warning_rounded : Icons.info_rounded,
                                  color: isCritical ? AppColors.dangerRed : AppColors.warningAmber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(action.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/artha'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Ask Artha', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: Duration(milliseconds: 500 + entry.key * 100)).fadeIn().slideX(begin: 0.05, end: 0);
                      }),
                    ],

                    const SizedBox(height: 80), // Bottom nav clearance
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_ask_artha',
        onPressed: () => context.go('/artha'),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
        label: const Text('Ask Artha', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _quickStat(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return AppColors.successGreen;
      case 'B': return AppColors.primaryTeal;
      case 'C': return AppColors.warningAmber;
      default: return AppColors.dangerRed;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/fire_provider.dart';
import '../widgets/fire_chart_widget.dart';
import '../widgets/scenario_card.dart';
import '../widgets/asset_allocation_widget.dart';

class FirePlannerScreen extends ConsumerWidget {
  const FirePlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(fireInputProvider);
    final fireAsync = ref.watch(firePlanProvider(input));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('F.I.R.E. Engine', style: AppTextStyles.subheading),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        backgroundColor: AppColors.cardColor,
        onRefresh: () async => ref.refresh(firePlanProvider(ref.read(fireInputProvider)).future),
        child: fireAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (data) {
            final isOnTrack = data.achievability == 'ACHIEVABLE';
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isOnTrack ? AppColors.primaryTeal.withOpacity(0.05) : AppColors.warningAmber.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnTrack ? AppColors.primaryTeal.withOpacity(0.3) : AppColors.warningAmber.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOnTrack ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                              color: isOnTrack ? AppColors.primaryTeal : AppColors.warningAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnTrack ? 'ON TRACK' : 'NEEDS OPTIMIZATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOnTrack ? AppColors.primaryTeal : AppColors.warningAmber,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Target Corpus', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.compact(data.targetCorpus),
                          style: AppTextStyles.financialHero,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildMetric('Timeline', '${data.targetYears} yrs')),
                            Expanded(child: _buildMetric('Required SIP', CurrencyFormatter.monthly(data.requiredMonthlySip))),
                          ],
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut),

                  const SizedBox(height: 32),

                  // Artha's Verdict
                  Text('ARTHA\'S VERDICT', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 16),
                  Text(
                    data.arthaMessage,
                    style: AppTextStyles.arthaQuote.copyWith(fontSize: 15),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  // Chart
                  Text('PROJECTED GROWTH', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 300.ms).fadeIn(),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: FireChartWidget(data: data.growthData),
                  ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  // Alternative Scenarios
                  Text('ALTERNATIVE PATHS', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 500.ms).fadeIn(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: data.scenarios.length,
                      itemBuilder: (context, i) {
                        return ScenarioCard(scenario: data.scenarios[i])
                            .animate(delay: (600 + i * 100).ms).fadeIn().slideX(begin: 0.1, end: 0);
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Asset Allocation
                  AssetAllocationWidget(allocation: data.assetAllocation)
                      .animate(delay: 800.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.financialMedium.copyWith(fontSize: 16)),
      ],
    );
  }
}

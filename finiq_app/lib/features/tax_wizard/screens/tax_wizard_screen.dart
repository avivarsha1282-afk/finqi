import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/tax_provider.dart';
import '../widgets/regime_card.dart';
import '../widgets/deduction_channel_card.dart';
import '../widgets/disclaimer_banner.dart';

class TaxWizardScreen extends ConsumerWidget {
  const TaxWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxProvider(1500000.0));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Tax Wizard', style: AppTextStyles.subheading),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        backgroundColor: AppColors.cardColor,
        onRefresh: () async => ref.refresh(taxProvider(1500000.0).future),
        child: taxAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (data) {
            final oldRegime = data.oldRegime;
            final newRegime = data.newRegime;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verdict Hero
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryTeal.withOpacity(0.15), AppColors.backgroundColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.primaryTeal, size: 40),
                        const SizedBox(height: 16),
                        const Text('RECOMMENDED REGIME', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(data.verdict, style: AppTextStyles.heading2.copyWith(color: AppColors.primaryTeal)),
                        const SizedBox(height: 16),
                        Text(
                          'You save ${CurrencyFormatter.format(data.totalPotentialSaving)} by switching.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut),

                  const SizedBox(height: 32),

                  const DisclaimerBanner().animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 32),

                  Text('REGIME COMPARISON', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 16),

                  RegimeCard(regime: newRegime, isWinner: data.verdict.contains('New'))
                      .animate(delay: 300.ms).fadeIn().slideX(begin: 0.1, end: 0),
                  RegimeCard(regime: oldRegime, isWinner: data.verdict.contains('Old'))
                      .animate(delay: 400.ms).fadeIn().slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  Text('MAXIMIZE YOUR DEDUCTIONS', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 500.ms).fadeIn(),
                  const SizedBox(height: 16),

                  ...data.channels.asMap().entries.map((entry) {
                    final i = entry.key;
                    final opp = entry.value;
                    return DeductionChannelCard(opportunity: opp)
                        .animate(delay: (600 + i * 100).ms)
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0);
                  }).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/score_provider.dart';
import '../widgets/gauge_painter.dart';
import '../widgets/score_dimension_card.dart';
import '../widgets/artha_says_card.dart';

class HealthScoreScreen extends ConsumerWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(scoreProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Health Score', style: AppTextStyles.subheading),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        backgroundColor: AppColors.cardColor,
        onRefresh: () => ref.refresh(scoreProvider.future),
        child: scoreAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: Text('A', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Couldn't load your score", style: AppTextStyles.subheading),
                  const SizedBox(height: 8),
                  const Text(
                    "Complete onboarding or check your internet connection.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => ref.refresh(scoreProvider.future),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('Tap to retry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            Color gaugeColor;
            if (data.percentage >= 0.8) gaugeColor = AppColors.successGreen;
            else if (data.percentage >= 0.5) gaugeColor = AppColors.warningAmber;
            else gaugeColor = AppColors.dangerRed;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Gauge
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 280,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              CustomPaint(
                                size: const Size(280, 140),
                                painter: GaugePainter(score: data.percentage, activeColor: gaugeColor),
                              ).animate().scale(begin: const Offset(0.8, 0.8), duration: 800.ms, curve: Curves.easeOutBack),
                              Positioned(
                                bottom: -10,
                                child: Text(
                                  data.totalScore.toString(),
                                  style: AppTextStyles.scoreHero.copyWith(color: gaugeColor),
                                ).animate(delay: 400.ms).fadeIn(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: gaugeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            data.gradeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: gaugeColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Artha Says
                  ArthaSaysCard(content: data.arthaInsight)
                      .animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  Text('HEALTH DIMENSIONS', style: AppTextStyles.label.copyWith(letterSpacing: 1.5))
                      .animate(delay: 700.ms).fadeIn(),
                  const SizedBox(height: 16),

                  // Dimensions list
                  ...data.dimensions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final dim = entry.value;
                    return ScoreDimensionCard(dimension: dim)
                        .animate(delay: (800 + i * 100).ms)
                        .fadeIn()
                        .slideX(begin: 0.1, end: 0);
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

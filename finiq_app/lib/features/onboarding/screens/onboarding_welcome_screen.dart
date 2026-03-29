import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../language/providers/language_provider.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Artha Avatar
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryTeal,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('A', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black)),
                    ),
                  ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
                  Positioned(
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isHindi ? 'अर्था ऑनलाइन' : 'ARTHA ONLINE',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Headline
              Text(
                'Meet Artha.',
                style: AppTextStyles.display.copyWith(height: 1.1),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

              Text(
                isHindi ? 'आपका वित्तीय सलाहकार।' : 'Your Financial Architect.',
                style: AppTextStyles.display.copyWith(height: 1.1),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              Text(
                isHindi
                    ? 'बस 12 सवाल, 5 मिनट में अर्था आपकी पूरी वित्तीय तस्वीर बनाएगी।'
                    : 'Answer 12 questions in 5 minutes. Artha will build your complete financial picture — health score, retirement plan, and tax strategy.',
                style: AppTextStyles.body.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ).animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 40),

              // What Artha builds
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'WHAT ARTHA WILL BUILD FOR YOU',
                  style: AppTextStyles.label,
                ),
              ).animate(delay: 450.ms).fadeIn(),

              const SizedBox(height: 12),

              ..._featureCards(isHindi),

              const SizedBox(height: 24),

              // Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    isHindi
                        ? 'बैंक-स्तरीय एन्क्रिप्शन। कोई डेटा साझा नहीं।'
                        : 'Bank-level 256-bit encryption. Your data is never sold.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ).animate(delay: 700.ms).fadeIn(),

              const SizedBox(height: 32),

              // CTA
              ElevatedButton(
                onPressed: () => context.go('/onboarding/chat'),
                child: Text(
                  isHindi ? 'मेरी वित्तीय यात्रा शुरू करें →' : 'Start My Financial Journey →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ).animate(delay: 800.ms).fadeIn(),

              const SizedBox(height: 12),

              Text(
                isHindi ? 'लगभग 5 मिनट लगते हैं' : 'Takes about 5 minutes',
                style: AppTextStyles.caption,
              ).animate(delay: 900.ms).fadeIn(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _featureCards(bool isHindi) {
    final features = [
      {
        'icon': Icons.favorite_rounded,
        'color': AppColors.dangerRed,
        'title': isHindi ? 'आपका वित्तीय स्वास्थ्य स्कोर' : 'Your Financial Health Score',
        'sub': isHindi ? '6 आयामों में स्कोर' : 'Score across 6 financial dimensions',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.warningAmber,
        'title': isHindi ? 'आपका सेवानिवृत्ति रोडमैप' : 'Your Retirement Roadmap',
        'sub': isHindi ? 'FIRE कैलकुलेटर और निवेश पथ' : 'FIRE calculator with investment path',
      },
      {
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.primaryTeal,
        'title': isHindi ? 'आपकी कर बचत योजना' : 'Your Tax Saving Plan',
        'sub': isHindi ? 'पुरानी बनाम नई व्यवस्था विश्लेषण' : 'Old vs New regime analysis + missed deductions',
      },
    ];

    return features.asMap().entries.map((entry) {
      final i = entry.key;
      final f = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (f['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(f['sub'] as String, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ).animate(delay: (500 + i * 100).ms).fadeIn().slideY(begin: 0.1, end: 0),
      );
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_constants.dart';
import '../../language/providers/language_provider.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selected = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(text: 'Fin', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'IQ', style: TextStyle(color: AppColors.primaryTeal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'India ka apna financial mentor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryTeal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 48),

              Text('Choose your\nlanguage', style: AppTextStyles.heading)
                  .animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 8),

              const Text(
                'You can change this anytime in settings',
                style: AppTextStyles.body,
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 32),

              // Language options
              ..._buildLanguageCards(),

              const Spacer(),

              // Continue button
              ElevatedButton(
                onPressed: () async {
                  await UserPrefsService.setString('app_language', _selected);
                  ref.read(languageProvider.notifier).setLanguage(_selected);
                  if (context.mounted) context.go('/onboarding/welcome');
                },
                child: const Text('Continue →'),
              ).animate(delay: 400.ms).fadeIn(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLanguageCards() {
    final languages = [
      {'code': 'en', 'name': 'English', 'badge': 'Default', 'sub': 'Most widely used'},
      {'code': 'hi', 'name': 'हिंदी', 'badge': null, 'sub': 'Most spoken in India'},
      {'code': 'ta', 'name': 'தமிழ்', 'badge': null, 'sub': 'Tamil'},
    ];

    return languages.asMap().entries.map((entry) {
      final i = entry.key;
      final lang = entry.value;
      final isSelected = _selected == lang['code'];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => setState(() => _selected = lang['code']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryTeal.withOpacity(0.08) : AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primaryTeal : AppColors.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
                            ),
                          ),
                          if (lang['badge'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                lang['badge']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(lang['sub']!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primaryTeal : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ).animate(delay: (300 + i * 80).ms).fadeIn().slideY(begin: 0.1, end: 0);
    }).toList();
  }
}

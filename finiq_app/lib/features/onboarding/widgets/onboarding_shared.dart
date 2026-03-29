import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// Shared onboarding header with step indicator and progress bar
Widget onboardingHeader(BuildContext context, int step) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Column(
      children: [
        Row(
          children: [
            if (step > 1)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.go('/onboarding/step${step - 1}'),
              )
            else
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => context.go('/login'),
              ),
            const Spacer(),
            RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'Fin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                TextSpan(text: 'IQ', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Step $step of 5',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / 5,
            backgroundColor: const Color(0xFF1F2937),
            color: AppColors.primaryTeal,
            minHeight: 4,
          ),
        ),
      ],
    ),
  );
}

/// Teal "Continue →" button at bottom of onboarding
Widget onboardingContinueButton(VoidCallback onTap, {String label = 'Continue'}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}

/// Small label above form fields
Widget onboardingLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
  );
}

/// Standard dark input decoration for onboarding forms
InputDecoration onboardingInputDecoration(String hint, {String? prefix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary),
    prefixText: prefix,
    prefixStyle: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dangerRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.dangerRed),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

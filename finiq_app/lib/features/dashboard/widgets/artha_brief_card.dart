import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ArthaBriefCard extends StatelessWidget {
  final String brief;

  const ArthaBriefCard({super.key, required this.brief});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryTeal,
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARTHA SAYS', style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal)),
                const SizedBox(height: 6),
                Text(
                  brief,
                  style: AppTextStyles.arthaQuote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

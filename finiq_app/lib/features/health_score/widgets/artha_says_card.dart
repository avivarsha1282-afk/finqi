import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ArthaSaysCard extends StatelessWidget {
  final String content;

  const ArthaSaysCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTeal,
                ),
                child: const Center(
                  child: Text('A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 12),
              Text('✦ ARTHA ASSESSMENT', style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: AppTextStyles.arthaQuote.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

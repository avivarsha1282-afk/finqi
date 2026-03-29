import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/health_score_model.dart';
import 'package:go_router/go_router.dart';

class PriorityActionCard extends StatelessWidget {
  final PriorityAction action;

  const PriorityActionCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final isCritical = action.severity == 'CRITICAL';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? AppColors.dangerRed.withOpacity(0.5) : AppColors.borderColor,
          width: isCritical ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCritical ? AppColors.dangerRed.withOpacity(0.1) : AppColors.warningAmber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: isCritical ? AppColors.dangerRed : AppColors.warningAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('CRITICAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.dangerRed)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(action.subtitle, style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Navigate to detail
                    context.go('/health/detail/${action.dimension}');
                  },
                  child: Text(
                    'Fix this now →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCritical ? AppColors.dangerRed : AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

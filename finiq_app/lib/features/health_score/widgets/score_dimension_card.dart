import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/health_score_model.dart';
import 'package:go_router/go_router.dart';

class ScoreDimensionCard extends StatelessWidget {
  final DimensionScore dimension;

  const ScoreDimensionCard({super.key, required this.dimension});

  @override
  Widget build(BuildContext context) {
    final isCritical = dimension.status == 'CRITICAL';
    final isDecent = dimension.status == 'DECENT';
    
    Color statusColor;
    if (isCritical) statusColor = AppColors.dangerRed;
    else if (isDecent) statusColor = AppColors.successGreen;
    else statusColor = AppColors.warningAmber;

    IconData getIcon(String name) {
      switch (name.toLowerCase()) {
        case 'emergency fund': return Icons.savings_rounded;
        case 'insurance': return Icons.shield_rounded;
        case 'investment mix': return Icons.trending_up_rounded;
        case 'debt health': return Icons.account_balance_rounded;
        case 'tax efficiency': return Icons.receipt_long_rounded;
        case 'fire progress': return Icons.local_fire_department_rounded;
        default: return Icons.circle_outlined;
      }
    }

    return GestureDetector(
      onTap: () => context.go('/health/detail/${dimension.name}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical ? AppColors.dangerRed.withOpacity(0.3) : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(dimension.name), color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dimension.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${dimension.score}/${dimension.maxScore}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(dimension.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

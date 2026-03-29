import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/fire_plan_model.dart';

class AssetAllocationWidget extends StatelessWidget {
  final List<AssetAllocation> allocation;

  const AssetAllocationWidget({super.key, required this.allocation});

  @override
  Widget build(BuildContext context) {
    if (allocation.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECOMMENDED ASSET ALLOCATION', style: AppTextStyles.label.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 24),
          
          // Progress bar segments
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Row(
                children: allocation.map((a) {
                  return Expanded(
                    flex: a.percentage.toInt(),
                    child: Container(color: _parseColor(a.colorHex)),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          ...allocation.map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _parseColor(a.colorHex)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(a.name, style: AppTextStyles.bodyMedium)),
                  Text('${a.percentage.toInt()}%', style: AppTextStyles.financialSmall),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

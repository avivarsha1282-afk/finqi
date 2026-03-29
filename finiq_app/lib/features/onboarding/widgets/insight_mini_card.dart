import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class InsightMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final Color valueColor;

  const InsightMiniCard({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.valueColor = AppColors.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFamily: 'monospace',
              ),
            ),
            if (subLabel != null)
              Text(subLabel!, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

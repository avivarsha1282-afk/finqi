import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/tax_report_model.dart';
import 'package:go_router/go_router.dart';

class DeductionChannelCard extends StatelessWidget {
  final TaxChannel opportunity;

  const DeductionChannelCard({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(opportunity.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
              Text(
                'Save up to ${CurrencyFormatter.format(opportunity.amount)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(opportunity.subtitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              context.push('/chat'); // Delegate to Artha
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primaryTeal, size: 16),
                  SizedBox(width: 8),
                  Text('Let Artha optimize this', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryTeal)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/tax_report_model.dart';

class RegimeCard extends StatelessWidget {
  final TaxRegimeResult regime;
  final bool isWinner;

  const RegimeCard({super.key, required this.regime, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    final double computedGross = regime.effectiveRate > 0 ? (regime.taxPayable / (regime.effectiveRate / 100)) : 1500000.0;
    final double computedTaxable = computedGross - regime.deductionsApplied;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner ? AppColors.primaryTeal : AppColors.borderColor,
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(regime.label, style: AppTextStyles.subheading2),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'WINNER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Tax', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.format(regime.taxPayable), style: AppTextStyles.financialMedium.copyWith(color: isWinner ? AppColors.primaryTeal : AppColors.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Effective Rate', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text('${regime.effectiveRate}%', style: AppTextStyles.financialMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('Gross Income', CurrencyFormatter.format(computedGross)),
          _buildBreakdownRow('Total Deductions', '-${CurrencyFormatter.format(regime.deductionsApplied)}', color: AppColors.successGreen),
          _buildBreakdownRow('Taxable Income', CurrencyFormatter.format(computedTaxable)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
            fontFamily: 'monospace',
          )),
        ],
      ),
    );
  }
}

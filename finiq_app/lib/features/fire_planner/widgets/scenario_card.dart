import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/fire_plan_model.dart';
import 'package:go_router/go_router.dart';

class ScenarioCard extends StatelessWidget {
  final FireScenario scenario;

  const ScenarioCard({super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scenario.isRecommended ? AppColors.primaryTeal.withOpacity(0.05) : AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scenario.isRecommended ? AppColors.primaryTeal : AppColors.borderColor,
          width: scenario.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${scenario.years} Years', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (scenario.isRecommended)
                const Icon(Icons.star_rounded, color: AppColors.primaryTeal, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(scenario.label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const Spacer(),
          Text(
            CurrencyFormatter.monthly(scenario.monthlySip),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryTeal, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              context.push('/chat'); // Deep link to chat to apply this scenario
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scenario.isRecommended ? AppColors.primaryTeal : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Apply path',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scenario.isRecommended ? Colors.black : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

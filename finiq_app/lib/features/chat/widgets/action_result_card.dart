import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_message_model.dart';

class ActionResultCard extends StatelessWidget {
  final ActionCard action;

  const ActionResultCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 12, right: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(action.value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                  ),
                  child: Text(action.primaryButtonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal)),
                ),
          ],
        ),
      ),
    );
  }
}

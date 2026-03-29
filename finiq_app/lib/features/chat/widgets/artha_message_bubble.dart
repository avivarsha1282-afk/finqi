import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ArthaMessageBubble extends StatelessWidget {
  final String text;
  final bool isLatest;

  const ArthaMessageBubble({super.key, required this.text, this.isLatest = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryTeal),
            child: const Center(
              child: Text('A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 48), // Padding on opposite side
        ],
      ),
    );
  }
}

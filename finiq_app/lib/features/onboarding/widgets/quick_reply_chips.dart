import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuickReplyChips extends StatelessWidget {
  final List<String> chips;
  final void Function(String) onSelected;
  final String? selectedChip;

  const QuickReplyChips({
    super.key,
    required this.chips,
    required this.onSelected,
    this.selectedChip,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final isSelected = chip == selectedChip;
          return GestureDetector(
            onTap: () => onSelected(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : AppColors.borderColor,
                ),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

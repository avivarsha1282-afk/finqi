import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class EmbeddedTableCard extends StatelessWidget {
  final String title;
  final List<List<String>> data;

  const EmbeddedTableCard({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final headers = data.first;
    final rows = data.sublist(1);

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 12, right: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                horizontalMargin: 0,
                columnSpacing: 24,
                columns: headers.map((h) => DataColumn(
                  label: Text(h, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                )).toList(),
                rows: rows.map((row) => DataRow(
                  cells: row.map((cell) => DataCell(
                    Text(cell, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'monospace')),
                  )).toList(),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/fire_plan_model.dart';

class FireChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;

  const FireChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final maxY = data.last.corpus * 1.2;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 20, right: 16, bottom: 10),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: data.last.year.toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.dividerColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 2,
                getTitlesWidget: (val, _) {
                  if (val == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Yr ${val.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (val, _) {
                  if (val == 0) return const SizedBox.shrink();
                  String compact;
                  if (val >= 10000000) compact = '${(val / 10000000).toStringAsFixed(1)}Cr';
                  else if (val >= 100000) compact = '${(val / 100000).toStringAsFixed(0)}L';
                  else compact = val.toStringAsFixed(0);
                  return Text(compact, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary), textAlign: TextAlign.right);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.map((d) => FlSpot(d.year.toDouble(), d.corpus)).toList(),
              isCurved: true,
              color: AppColors.primaryTeal,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryTeal.withOpacity(0.3),
                    AppColors.primaryTeal.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardElevated,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final val = spot.y;
                  String display;
                  if (val >= 10000000) display = '₹${(val / 10000000).toStringAsFixed(2)}Cr';
                  else if (val >= 100000) display = '₹${(val / 100000).toStringAsFixed(2)}L';
                  else display = '₹${val.toStringAsFixed(0)}';
                  return LineTooltipItem(
                    display,
                    const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

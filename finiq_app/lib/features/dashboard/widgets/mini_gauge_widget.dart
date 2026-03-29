import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';

class MiniGaugeWidget extends StatelessWidget {
  final double score; // 0 to 1
  final double size;

  const MiniGaugeWidget({
    super.key,
    required this.score,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    if (score >= 0.8) gaugeColor = AppColors.successGreen;
    else if (score >= 0.5) gaugeColor = AppColors.warningAmber;
    else gaugeColor = AppColors.dangerRed;

    return SizedBox(
      width: size,
      height: size / 1.5,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(size, size / 2),
            painter: _MiniGaugePainter(score: score, color: gaugeColor),
          ),
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(score * 100).toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,  // Always teal, not status color
                    fontFamily: 'monospace',
                  ),
                ),
                const Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _MiniGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = AppColors.surfaceHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Draw background arc
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // Draw foreground arc
    canvas.drawArc(rect, math.pi, math.pi * score, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

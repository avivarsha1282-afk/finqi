import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';

class GaugePainter extends CustomPainter {
  final double score; // 0.0 to 1.0
  final Color activeColor;

  GaugePainter({
    required this.score,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.surfaceHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Active track
    final fgPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Draw background arc (half circle: pi to 2pi, sweeping pi)
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // Draw foreground arc based on score
    canvas.drawArc(rect, math.pi, math.pi * score, false, fgPaint);

    // Draw segmented markers
    _drawMarkers(canvas, center, radius, strokeWidth);
  }

  void _drawMarkers(Canvas canvas, Offset center, double radius, double strokeWidth) {
    final markerPaint = Paint()
      ..color = AppColors.backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw 4 separators to make 5 zones
    for (int i = 1; i <= 4; i++) {
      final angle = math.pi + (math.pi * i / 5);
      
      final innerRadius = radius - strokeWidth;
      final outerRadius = radius;

      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(p1, p2, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.activeColor != activeColor;
  }
}

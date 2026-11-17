import 'dart:math' as math;

import 'package:flutter/material.dart';

class FocusProgressRing extends StatelessWidget {
  const FocusProgressRing({super.key, required this.remainingFraction});

  final double remainingFraction;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(228),
    painter: _FocusProgressPainter(remainingFraction),
  );
}

class _FocusProgressPainter extends CustomPainter {
  const _FocusProgressPainter(this.remainingFraction);

  final double remainingFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 10) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE6EEFF)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );
    final sweep = 2 * math.pi * remainingFraction.clamp(0.0, 1.0);
    if (sweep == 0) return;
    canvas.drawArc(
      bounds,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [Color(0xFF7BBDE8), Color(0xFF0A4174)],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(bounds)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusProgressPainter oldDelegate) =>
      remainingFraction != oldDelegate.remainingFraction;
}

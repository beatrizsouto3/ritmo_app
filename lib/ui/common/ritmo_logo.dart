import 'package:flutter/material.dart';

class RitmoLogo extends StatelessWidget {
  const RitmoLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: const _RitmoLogoPainter()),
  );
}

class _RitmoLogoPainter extends CustomPainter {
  const _RitmoLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final bounds = const Rect.fromLTWH(0, 0, 160, 160);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(38)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF001D39), Color(0xFF0A4174), Color(0xFF4E8EA2)],
          stops: [0, 0.45, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    final mark = Path()
      ..moveTo(42, 116)
      ..lineTo(42, 44)
      ..cubicTo(42, 44, 64, 36, 86, 44)
      ..cubicTo(108, 52, 114, 74, 100, 90)
      ..cubicTo(88, 104, 68, 104, 68, 104)
      ..lineTo(112, 116);
    canvas.drawPath(
      mark,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final accent = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7BBDE8), Color(0xFFBDD8E9)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(bounds);
    canvas.drawCircle(const Offset(116, 46), 10, accent);
    canvas.drawLine(
      const Offset(58, 74),
      const Offset(78, 74),
      accent
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

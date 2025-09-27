import 'dart:math' as math;
import 'package:flutter/material.dart';

class SemiGauge extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String? unit;
  final double? target; // optional target marker
  final Color color;
  const SemiGauge({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.unit,
    this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, c) {
                  return CustomPaint(
                    painter: _SemiGaugePainter(
                      value: v,
                      min: min,
                      max: max,
                      unit: unit,
                      target: target,
                      color: color,
                      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontSize: 20, color: Colors.white),
                      subTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70) ?? const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final String? unit;
  final double? target;
  final Color color;
  final TextStyle textStyle;
  final TextStyle subTextStyle;

  _SemiGaugePainter({
    required this.value,
    required this.min,
    required this.max,
    this.unit,
    this.target,
    required this.color,
    required this.textStyle,
    required this.subTextStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = math.min(size.width, size.height) * 0.9 / 2;
    final startAngle = math.pi;
    final sweep = math.pi;

    final bg = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Background arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweep, false, bg);

    // Foreground arc
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    canvas.drawArc(rect, startAngle, sweep * t, false, fg);

    // Target tick
    if (target != null) {
      final tt = ((target! - min) / (max - min)).clamp(0.0, 1.0);
      final ang = startAngle + sweep * tt;
      final r1 = radius - 10;
      final r2 = radius + 4;
      final p1 = Offset(center.dx + r1 * math.cos(ang), center.dy + r1 * math.sin(ang));
      final p2 = Offset(center.dx + r2 * math.cos(ang), center.dy + r2 * math.sin(ang));
      final tick = Paint()
        ..color = Colors.white70
        ..strokeWidth = 3;
      canvas.drawLine(p1, p2, tick);
    }

    // Value text
    final valueText = TextPainter(
      text: TextSpan(text: unit == '%' ? value.toStringAsFixed(0) : value.toStringAsFixed(2), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final unitText = unit != null
        ? (TextPainter(
            text: TextSpan(text: unit, style: subTextStyle),
            textDirection: TextDirection.ltr,
          )..layout())
        : null;
    final totalW = valueText.width + (unitText != null ? unitText.width + 4 : 0);
    valueText.paint(canvas, Offset(center.dx - totalW / 2, center.dy - 40));
    if (unitText != null) {
      unitText.paint(canvas, Offset(center.dx - totalW / 2 + valueText.width + 4, center.dy - 30));
    }

    // Min/Max labels
    final minTp = TextPainter(text: TextSpan(text: min.toStringAsFixed(2), style: subTextStyle), textDirection: TextDirection.ltr)..layout();
    final maxTp = TextPainter(text: TextSpan(text: max.toStringAsFixed(0), style: subTextStyle), textDirection: TextDirection.ltr)..layout();
    minTp.paint(canvas, Offset(rect.left, center.dy + 4));
    maxTp.paint(canvas, Offset(rect.right - maxTp.width, center.dy + 4));
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.min != min || oldDelegate.max != max || oldDelegate.color != color || oldDelegate.target != target;
}
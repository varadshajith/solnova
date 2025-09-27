import 'package:flutter/material.dart';

class BatteryPack extends StatelessWidget {
  final double soc; // 0-100
  final bool vertical;
  const BatteryPack({super.key, required this.soc, this.vertical = true});

  Color _colorFor(double v) {
    if (v < 30) return Colors.redAccent;
    if (v < 60) return Colors.amber;
    // normal: use blue/green mix
    return Colors.lightGreenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(soc);
    final clamped = soc.clamp(0, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Battery icon shape (vertical)
            SizedBox(
              width: vertical ? 48 : 140,
              height: vertical ? 120 : 48,
              child: CustomPaint(
                painter: _BatteryPainter(fillPct: clamped / 100.0, color: color, vertical: vertical),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Battery State of Charge', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('${clamped.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double fillPct; // 0..1
  final Color color;
  final bool vertical;
  _BatteryPainter({required this.fillPct, required this.color, required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    late Rect bodyRect;
    late Rect tipRect;
    if (vertical) {
      bodyRect = Rect.fromLTWH(0, 8, size.width, size.height - 8);
      tipRect = Rect.fromLTWH(size.width * 0.25, 0, size.width * 0.5, 8);
    } else {
      bodyRect = Rect.fromLTWH(0, 0, size.width - 8, size.height);
      tipRect = Rect.fromLTWH(size.width - 8, size.height * 0.25, 8, size.height * 0.5);
    }

    final borderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgPaint = Paint()..color = Colors.white10;

    // Body
    final r = RRect.fromRectAndRadius(bodyRect, const Radius.circular(8));
    canvas.drawRRect(r, bgPaint);
    canvas.drawRRect(r, borderPaint);

    // Tip
    final tipR = RRect.fromRectAndRadius(tipRect, const Radius.circular(2));
    canvas.drawRRect(tipR, bgPaint);
    canvas.drawRRect(tipR, borderPaint);

    // Fill
    final inner = bodyRect.deflate(4);
    final fillPaint = Paint()..color = color;
    if (vertical) {
      final fillH = inner.height * fillPct;
      final top = inner.bottom - fillH;
      final fillRect = Rect.fromLTWH(inner.left, top, inner.width, fillH);
      final fillR = RRect.fromRectAndRadius(fillRect, const Radius.circular(6));
      canvas.drawRRect(fillR, fillPaint);
    } else {
      final fillW = inner.width * fillPct;
      final fillRect = Rect.fromLTWH(inner.left, inner.top, fillW, inner.height);
      final fillR = RRect.fromRectAndRadius(fillRect, const Radius.circular(6));
      canvas.drawRRect(fillR, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.fillPct != fillPct || oldDelegate.color != color || oldDelegate.vertical != vertical;
}
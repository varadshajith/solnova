import 'package:flutter/material.dart';

class GaugeKpi extends StatelessWidget {
  final String title;
  final double value;
  final String? unit;
  final double min;
  final double max;
  final Color color;
  const GaugeKpi({super.key, required this.title, required this.value, this.unit, required this.min, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final norm = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: norm,
                    strokeWidth: 10,
                    backgroundColor: Colors.white12,
                    color: color,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value.toStringAsFixed(unit == '%' ? 0 : 1), style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
                      if (unit != null) Text(unit!, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}${unit ?? ''}', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final Color accent;
  final IconData icon;
  const KpiCard({super.key, required this.title, required this.value, this.unit, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.labelMedium!.copyWith(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(value, style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
                      if (unit != null) ...[
                        const SizedBox(width: 4),
                        Text(unit!, style: textTheme.labelLarge!.copyWith(color: Colors.white70)),
                      ],
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
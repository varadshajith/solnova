import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MetricOption {
  final String label;
  final String value;
  const MetricOption(this.label, this.value);
}

class PeriodOption {
  final String label;
  final String value;
  const PeriodOption(this.label, this.value);
}

class LineChartPanel extends StatelessWidget {
  final List<FlSpot> points;
  final MetricOption metric;
  final PeriodOption period;
  final ValueChanged<MetricOption> onMetricChanged;
  final ValueChanged<PeriodOption> onPeriodChanged;

  const LineChartPanel({
    super.key,
    required this.points,
    required this.metric,
    required this.period,
    required this.onMetricChanged,
    required this.onPeriodChanged,
  });

  static const metrics = [
    MetricOption('Power Consumption', 'consumption_kW'),
    MetricOption('Power Generation', 'generation_kW'),
    MetricOption('Battery SoC', 'battery_soc'),
  ];

  static const periods = [
    PeriodOption('1H', '1h'),
    PeriodOption('24H', '24h'),
    PeriodOption('7D', '7d'),
    PeriodOption('30D', '30d'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Historical Trends', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<MetricOption>(
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    value: metric,
                    items: metrics.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
                    onChanged: (m) { if (m != null) onMetricChanged(m); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: periods.map((p) {
                final selected = p.value == period.value;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (_) => onPeriodChanged(p),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white12, strokeWidth: 1)),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: Colors.tealAccent,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.tealAccent.withOpacity(0.15)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
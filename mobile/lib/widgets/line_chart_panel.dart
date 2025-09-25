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
  final bool useTimeAxis;
  final String Function(double)? xLabel;
  final double? minX;
  final double? maxX;
  final int targetXTicks;
  final VoidCallback? onRefresh;

  const LineChartPanel({
    super.key,
    required this.points,
    required this.metric,
    required this.period,
    required this.onMetricChanged,
    required this.onPeriodChanged,
    this.useTimeAxis = false,
    this.xLabel,
    this.minX,
    this.maxX,
    this.targetXTicks = 5,
    this.onRefresh,
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
                if (onRefresh != null)
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (v) => FlLine(color: Colors.white12, strokeWidth: 1),
                    getDrawingVerticalLine: (v) => FlLine(color: Colors.white12, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: useTimeAxis,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (!useTimeAxis) return const SizedBox.shrink();
                          final text = (xLabel != null) ? xLabel!(value) : value.toStringAsFixed(0);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          );
                        },
                        interval: () {
if (!useTimeAxis || points.isEmpty) return 1.0;
                          final start = minX ?? points.first.x;
                          final end = maxX ?? points.last.x;
                          final span = (end - start).abs();
                          if (span <= 0) return 1.0;
                          // Aim for ~targetXTicks on screen
                          return span / targetXTicks;
                        }(),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: null),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(),
                  ),
                  minX: minX,
                  maxX: maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: Colors.tealAccent,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
belowBarData: BarAreaData(show: true, color: Colors.tealAccent.withValues(alpha: 0.15)),
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
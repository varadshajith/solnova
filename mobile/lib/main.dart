import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';
import 'widgets/gauge_kpi.dart';
import 'widgets/battery_pack.dart';
import 'widgets/semi_gauge.dart';
import 'widgets/line_chart_panel.dart';
import 'widgets/header.dart';
import 'widgets/alerts_carousel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'screens/microgrid_selection.dart';
import 'screens/alerts_screen.dart';
import 'screens/devices_screen.dart';
import 'providers.dart';
import 'services/cache_store.dart';
import 'services/connectivity_service.dart';
import 'services/push_notifications.dart';
import 'services/push_permissions.dart';

void main() {
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: const [],
      child: const _CacheGate(),
    );
  }
}

class _CacheGate extends ConsumerWidget {
  const _CacheGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(cacheStoreInitProvider);
    return init.when(
      loading: () => const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
      error: (e, _) => MaterialApp(home: Scaffold(body: Center(child: Text('Init error: $e')))),
      data: (cache) => ProviderScope(
        overrides: [cacheStoreProvider.overrideWithValue(cache)],
        child: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off push initialization (non-blocking)
    ref.listen(pushInitProvider, (_, __) {});
    return const SolnovaApp();
  }
}

const _apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000');
final apiBaseUrlProvider = Provider<String>((ref) => _apiBase);
final tokenProvider = StateProvider<String?>((ref) => null);
final selectedGridIdProvider = StateProvider<String?>((ref) => null);

class SolnovaApp extends StatelessWidget {
  const SolnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SOLNOVA',
      theme: buildSolnovaDarkTheme(),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = useTextEditingController(text: 'user');
    final password = useTextEditingController(text: 'password');
    final loading = useState(false);
    final error = useState<String?>(null);

    Future<void> login() async {
      loading.value = true;
      error.value = null;
      final base = ref.read(apiBaseUrlProvider);
      try {
        final resp = await http.post(
          Uri.parse('$base/api/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username.text, 'password': password.text}),
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          ref.read(tokenProvider.notifier).state = body['token'] as String;
          if (context.mounted) {
Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MicrogridSelectionScreen()),
            );
          }
        } else {
          error.value = 'Login failed (${resp.statusCode})';
        }
      } catch (e) {
        error.value = 'Network error';
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SOLNOVA', style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Sign in to your dashboard', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70)),
                  const SizedBox(height: 24),
                  TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                  const SizedBox(height: 16),
                  if (error.value != null) Align(alignment: Alignment.centerLeft, child: Text(error.value!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading.value ? null : login,
                      child: loading.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends HookConsumerWidget {
  final String gridId;
  const DashboardScreen({super.key, required this.gridId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providers
    final summaryAsync = ref.watch(realtimeSummaryProvider(gridId));
    final alertsAsync = ref.watch(alertsProvider(gridId));

    final metric = useState(const MetricOption('Power Generation', 'generation_kW'));
    final period = useState(const PeriodOption('1H', '1h'));
    final histAsync = ref.watch(historicalProvider(HistoricalQuery(gridId, metric.value.value, period.value.value)));
    final histRange = useState(const RangeValues(0.0, 1.0));

    // Reset range on metric/period change
    useEffect(() {
      histRange.value = const RangeValues(0.0, 1.0);
      return null;
    }, [metric.value, period.value]);

    final lastUpdated = useState<DateTime?>(null);
    useEffect(() {
      summaryAsync.whenData((_) => lastUpdated.value = DateTime.now());
      return null;
    }, [summaryAsync]);


    String updatedText() {
      final dt = lastUpdated.value;
      if (dt == null) return 'Last Updated: --';
      return 'Last Updated: ' + dt.toLocal().toString().split('.').first;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(realtimeSummaryProvider(gridId));
          ref.invalidate(alertsProvider(gridId));
          // Invalidate all historical queries by invalidating the provider itself
          ref.invalidate(historicalProvider);
          // Await at least the summary to ensure UI updates
          await ref.read(realtimeSummaryProvider(gridId).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
AppHeader(title: 'Microgrid Command Center — ${gridId}', lastUpdatedText: updatedText(), online: ref.watch(connectivityStreamProvider).maybeWhen(data: (v) => v, orElse: () => null)),
          const SizedBox(height: 12),
// Quick actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DevicesScreen(gridId: gridId)),
                  );
                },
                icon: const Icon(Icons.devices_other_outlined, size: 18),
                label: const Text('Devices'),
              ),
            ],
          ),
          const SizedBox(height: 12),
// Alerts carousel
          Builder(builder: (context) {
            return alertsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Row(
                children: [
                  const Text('Alerts unavailable', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(alertsProvider(gridId)),
                    child: const Text('Retry'),
                  )
                ],
              ),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
final messages = items.map((e) => e.message).toList();
return AlertsCarousel(messages: messages, onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AlertsScreen(gridId: gridId)),
                  );
                });
              },
            );
          }),
          const SizedBox(height: 16),
// Notifications permission banner (Android 13+/iOS)
          Builder(builder: (context) {
            final perm = ref.watch(pushPermissionProvider);
            return perm.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (state) {
                if (state == PushPermissionState.granted) return const SizedBox.shrink();
                return _NotificationPermissionBanner(
                  onEnable: () async {
                    final granted = await ref.read(requestPushPermissionProvider.future);
                    // Refresh permission state
                    ref.invalidate(pushPermissionProvider);
                    return granted;
                  },
                );
              },
            );
          }),
          const SizedBox(height: 12),
// KPI row
          Builder(builder: (context) {
            return summaryAsync.when(
              loading: () => Row(
                children: const [Expanded(child: Card(child: SizedBox(height: 140))), SizedBox(width: 12), Expanded(child: Card(child: SizedBox(height: 140))), SizedBox(width: 12), Expanded(child: Card(child: SizedBox(height: 140)))],
              ),
              error: (e, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: Text('Failed to load KPIs')),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(realtimeSummaryProvider(gridId));
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try again'),
                  ),
                ],
              ),
              data: (sr) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CacheInfoBanner(
                    enabled: sr.fromCache,
                    onRefresh: () {
                      // Invalidate providers to refetch
                      ref.invalidate(realtimeSummaryProvider(gridId));
                      ref.invalidate(alertsProvider(gridId));
                      ref.invalidate(historicalProvider);
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
Expanded(
                        child: SemiGauge(
                          title: 'Consumption',
                          value: sr.data.consumptionKW,
                          unit: 'kW',
                          min: 0,
                          max: 200,
                          target: 140,
                          color: const Color(0xFF2196F3), // blue
                        ),
                      ),
                      const SizedBox(width: 12),
Expanded(
                        child: SemiGauge(
                          title: 'Generation',
                          value: sr.data.generationKW,
                          unit: 'kW',
                          min: 0,
                          max: 200,
                          target: 140,
                          color: const Color(0xFF00E676), // green
                        ),
                      ),
                      const SizedBox(width: 12),
Expanded(
                        child: BatteryPack(soc: sr.data.batterySoc, vertical: true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // More telemetry (collapsed)
                  ExpansionTile(
                    title: const Text('More telemetry'),
                    children: [
                      _TelemetryBar(label: 'DC Bus Voltage', value: sr.data.dcBusVoltageV, unit: 'V', min: 0, max: 1000),
                      _TelemetryBar(label: 'DC Bus Current', value: sr.data.dcBusCurrentA, unit: 'A', min: 0, max: 500),
                      _TelemetryBar(label: 'AC Output Voltage', value: sr.data.acVoltageV, unit: 'V', min: 0, max: 480),
                      _TelemetryBar(label: 'AC Frequency', value: sr.data.acFrequencyHz, unit: 'Hz', min: 0, max: 60),
                      _StatusRow(label: 'Grid-Tie', ok: sr.data.gridTieConnected),
                      _TelemetryBar(label: 'Equipment Temp', value: sr.data.equipmentTempC, unit: '°C', min: 0, max: 100),
                      _TelemetryBar(label: 'Solar Irradiance', value: sr.data.solarIrradiance, unit: 'W/m²', min: 0, max: 1200),
                      _TelemetryBar(label: 'Ambient Temp', value: sr.data.ambientTempC, unit: '°C', min: -10, max: 50),
                      _TelemetryBar(label: 'Humidity', value: sr.data.humidityPct, unit: '%', min: 0, max: 100),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
// Historical chart with tabs
          DefaultTabController(
            length: 3,
            initialIndex: () {
              switch (metric.value.value) {
                case 'consumption_kW':
                  return 0;
                case 'generation_kW':
                  return 1;
                case 'battery_soc':
                default:
                  return 2;
              }
            }(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Consumption'),
                    Tab(text: 'Generation'),
                    Tab(text: 'Battery SoC'),
                  ],
                  onTap: (i) {
                    if (i == 0) metric.value = const MetricOption('Power Consumption', 'consumption_kW');
                    if (i == 1) metric.value = const MetricOption('Power Generation', 'generation_kW');
                    if (i == 2) metric.value = const MetricOption('Battery SoC', 'battery_soc');
                  },
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  return histAsync.when(
                    loading: () => const Card(child: SizedBox(height: 220)),
                    error: (_, __) => const Text('Failed to load historical data'),
                    data: (points) {
                      final spots = [for (final p in points) FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.value)];
                      String fmt(double x) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(x.toInt(), isUtc: false);
                        switch (period.value.value) {
                          case '1h':
                            return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                          case '24h':
                          case '7d':
                          case '30d':
                          default:
                            return '${dt.month}/${dt.day}';
                        }
                      }
                      final minEpoch = points.isNotEmpty ? points.first.time.millisecondsSinceEpoch.toDouble() : 0;
                      final maxEpoch = points.isNotEmpty ? points.last.time.millisecondsSinceEpoch.toDouble() : 1;
                      final span = (maxEpoch - minEpoch).abs();
                      final selMin = minEpoch + span * histRange.value.start;
                      final selMax = minEpoch + span * histRange.value.end;
                      final compactLabels = useState(false);
                      return Column(
                        children: [
                          LineChartPanel(
                            points: spots,
                            metric: metric.value,
                            period: period.value,
                            onMetricChanged: (m) => metric.value = m,
                            onPeriodChanged: (p) => period.value = p,
                            useTimeAxis: true,
                            xLabel: fmt,
                            minX: selMin,
                            maxX: selMax,
                            targetXTicks: compactLabels.value ? 3 : 5,
                            onRefresh: () {
                              ref.invalidate(historicalProvider);
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Range', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              Expanded(
                                child: RangeSlider(
                                  values: histRange.value,
                                  min: 0,
                                  max: 1,
                                  divisions: 20,
                                  labels: RangeLabels('${(histRange.value.start * 100).round()}%', '${(histRange.value.end * 100).round()}%'),
                                  onChanged: (v) => histRange.value = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Compact labels'),
                                selected: compactLabels.value,
                                onSelected: (s) => compactLabels.value = s,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _NotificationPermissionBanner extends HookWidget {
  final Future<bool> Function() onEnable;
  const _NotificationPermissionBanner({required this.onEnable});
  @override
  Widget build(BuildContext context) {
    final busy = useState(false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade700),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Colors.lightBlueAccent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Enable notifications to receive critical alerts in real time.',
              style: TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
          FilledButton(
            onPressed: busy.value
                ? null
                : () async {
                    busy.value = true;
                    try {
                      final ok = await onEnable();
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications enabled')));
                      }
                    } finally {
                      busy.value = false;
                    }
                  },
            child: busy.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enable'),
          )
        ],
      ),
    );
  }
}

class _TelemetryBar extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final double min;
  final double max;
  const _TelemetryBar({required this.label, required this.value, required this.unit, required this.min, required this.max});
  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final norm = ((value! - min) / (max - min)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
              Text('${value!.toStringAsFixed(1)} $unit', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: norm, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool? ok;
  const _StatusRow({required this.label, required this.ok});
  @override
  Widget build(BuildContext context) {
    if (ok == null) return const SizedBox.shrink();
    final color = ok! ? Colors.greenAccent : Colors.redAccent;
    final text = ok! ? 'Connected' : 'Disconnected';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(text, style: TextStyle(color: color)),
          )
        ],
      ),
    );
  }
}

class _CacheInfoBanner extends HookWidget {
  final bool enabled;
  final VoidCallback? onRefresh;
  const _CacheInfoBanner({required this.enabled, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final show = useState(true);
    if (!enabled || !show.value) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.amber.shade800.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
          const SizedBox(width: 8),
          const Expanded(child: Text('Showing cached data — check your connection', style: TextStyle(color: Colors.amberAccent))),
          if (onRefresh != null)
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 14, color: Colors.amberAccent),
              label: const Text('Refresh', style: TextStyle(color: Colors.amberAccent)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 16, color: Colors.amberAccent),
            onPressed: () => show.value = false,
          )
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';
import 'widgets/kpi_card.dart';
import 'widgets/alert_banner.dart';
import 'widgets/line_chart_panel.dart';
import 'widgets/header.dart';
import 'widgets/alerts_carousel.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const ProviderScope(child: SolnovaApp()));
}

const _apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000');
final apiBaseUrlProvider = Provider<String>((ref) => _apiBase);
final tokenProvider = StateProvider<String?>((ref) => null);

class SolnovaApp extends StatelessWidget {
  const SolnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(apiBaseUrlProvider);
    final token = ref.watch(tokenProvider);

    Future<Map<String, dynamic>> fetchRealtime() async {
      final resp = await http.get(
        Uri.parse('$base/api/dashboard/realtime'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );
      if (resp.statusCode != 200) throw Exception('Failed realtime');
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    Future<List<dynamic>> fetchAlerts() async {
      final resp = await http.get(
        Uri.parse('$base/api/dashboard/alerts'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );
      if (resp.statusCode != 200) return [];
      return (jsonDecode(resp.body) as List).cast<dynamic>();
    }

    Future<List<Offset>> fetchHistorical(String metric, String period) async {
      final resp = await http.get(
        Uri.parse('$base/api/dashboard/historical?metric=$metric&period=$period'),
        headers: {'Authorization': 'Bearer ${token ?? ''}'},
      );
      if (resp.statusCode != 200) return [];
      final raw = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      // Map index to x to keep it simple (time ordering assumed)
      return [for (var i = 0; i < raw.length; i++) Offset(i.toDouble(), (raw[i]['value'] as num).toDouble())];
    }

    final realtime = useMemoized(fetchRealtime);
    final alerts = useMemoized(fetchAlerts);

    final metric = useState(const MetricOption('Power Generation', 'generation_kW'));
    final period = useState(const PeriodOption('1H', '1h'));

    final historicalFuture = useMemoized(() => fetchHistorical(metric.value.value, period.value.value), [metric.value, period.value]);

    final lastUpdated = useState<DateTime?>(null);
    useEffect(() {
      // Update timestamp when realtime completes
      realtime.then((_) => lastUpdated.value = DateTime.now());
      // Periodic refresh of realtime and alerts every 10s
      final t = Timer.periodic(const Duration(seconds: 10), (_) {
        // trigger by reassigning futures
        // ignore: unused_local_variable
      });
      return t.cancel;
    }, const []);

    String updatedText() {
      final dt = lastUpdated.value;
      if (dt == null) return 'Last Updated: --';
      return 'Last Updated: ' + dt.toLocal().toString().split('.').first;
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppHeader(title: 'Microgrid Command Center', lastUpdatedText: updatedText()),
          const SizedBox(height: 12),
          // Alerts carousel
          FutureBuilder<List<dynamic>>(
            future: alerts,
            builder: (context, snapshot) {
              final items = (snapshot.data ?? []).cast<Map<String, dynamic>>();
              if (items.isEmpty) return const SizedBox.shrink();
              final messages = items.map((e) => e['message']?.toString() ?? 'Alert').toList();
              return AlertsCarousel(messages: messages, onViewAll: () {});
            },
          ),
          const SizedBox(height: 16),
          // KPI row
          FutureBuilder<Map<String, dynamic>>(
            future: realtime,
            builder: (context, snapshot) {
              final d = snapshot.data;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Live Power Consumption',
                      value: d == null ? '--' : (d['consumption_kW']).toString(),
                      unit: 'kW',
                      accent: Colors.orangeAccent,
                      icon: Icons.bolt_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Live Power Generation',
                      value: d == null ? '--' : (d['generation_kW']).toString(),
                      unit: 'kW',
                      accent: Colors.lightBlueAccent,
                      icon: Icons.solar_power_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Battery State of Charge',
                      value: d == null ? '--' : (d['battery_soc']).toString(),
                      unit: '%',
                      accent: Colors.greenAccent,
                      icon: Icons.battery_charging_full_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Historical chart
          FutureBuilder<List<Offset>>(
            future: historicalFuture,
            builder: (context, snapshot) {
              final pts = (snapshot.data ?? []).map((e) => FlSpot(e.dx, e.dy)).toList();
              return LineChartPanel(
                points: pts,
                metric: metric.value,
                period: period.value,
                onMetricChanged: (m) => metric.value = m,
                onPeriodChanged: (p) => period.value = p,
              );
            },
          ),
        ],
      ),
    );
  }
}

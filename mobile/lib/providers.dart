import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'repositories/dashboard_repository.dart';
import 'models/summary_result.dart';
import 'models/alert.dart';
import 'models/historical_point.dart';
import 'models/device.dart';

// Families parameterized by gridId

final realtimeSummaryProvider = FutureProvider.family<SummaryResult, String>((ref, gridId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchSummary(gridId);
});

final alertsProvider = FutureProvider.family<List<AlertItem>, String>((ref, gridId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchAlerts(gridId, status: 'active');
});

final alertsByStatusProvider = FutureProvider.family.autoDispose<List<AlertItem>, ({String gridId, String status})>((ref, p) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchAlerts(p.gridId, status: p.status);
});

class HistoricalQuery {
  final String gridId;
  final String metric;
  final String period;
  final String? granularity;
  const HistoricalQuery(this.gridId, this.metric, this.period, {this.granularity});
}

final historicalProvider = FutureProvider.family<List<HistoricalPoint>, HistoricalQuery>((ref, q) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchHistorical(q.gridId, q.metric, q.period, granularity: q.granularity);
});

final devicesProvider = FutureProvider.family<List<DeviceItem>, String>((ref, gridId) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchDevices(gridId);
});

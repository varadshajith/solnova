import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api/api_client.dart';
import '../models/realtime_summary.dart';
import '../models/summary_result.dart';
import '../models/alert.dart';
import '../models/historical_point.dart';
import '../models/device.dart';
import '../services/cache_store.dart';
import '../services/retry.dart';

class DashboardRepository {
  final ApiClient api;
  final CacheStore cache;
  const DashboardRepository(this.api, this.cache);

  Future<SummaryResult> fetchSummary(String gridId) async {
    const cacheKeyPrefix = 'summary';
    try {
      // Try production endpoint first
      final json = await retryAsync(() => api.getJson('/api/dashboard/summary/$gridId')); 
      await cache.setJson('$cacheKeyPrefix:$gridId', json);
      return SummaryResult(data: RealtimeSummary.fromJson(json), fromCache: false);
    } catch (_) {
      // Fallback to prototype endpoint
      try {
        final json = await retryAsync(() => api.getJson('/api/dashboard/realtime', {'grid_id': gridId}));
        await cache.setJson('$cacheKeyPrefix:$gridId', json);
        return SummaryResult(data: RealtimeSummary.fromJson(json), fromCache: false);
      } catch (e) {
        // Try cache as last-known-good
        final cached = await cache.getJson('$cacheKeyPrefix:$gridId');
        if (cached != null) {
          return SummaryResult(data: RealtimeSummary.fromJson(cached), fromCache: true);
        }
        rethrow;
      }
    }
  }

  Future<List<AlertItem>> fetchAlerts(String gridId, {String status = 'active'}) async {
    final cacheKey = 'alerts:$gridId:$status';
    try {
      final list = await retryAsync(() => api.getJsonList('/api/alerts/$gridId', {'status': status}));
      final mapped = list.map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
      await cache.setJsonList(cacheKey, list);
      return mapped;
    } catch (_) {
      final cached = await cache.getJsonList(cacheKey);
      if (cached != null) {
        return cached.map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  Future<List<HistoricalPoint>> fetchHistorical(String gridId, String metric, String period, {String? granularity}) async {
    final query = {
      'period': period,
      if (granularity != null) 'granularity': granularity,
    };
    final cacheKey = 'historical:$gridId:$metric:$period:${granularity ?? ''}';
    try {
      final list = await retryAsync(() => api.getJsonList('/api/historical/$gridId/$metric', query));
      await cache.setJsonList(cacheKey, list);
      return list.map((e) => HistoricalPoint.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final cached = await cache.getJsonList(cacheKey);
      if (cached != null) {
        return cached.map((e) => HistoricalPoint.fromJson(e as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  Future<bool> acknowledgeAlert(String alertId, {String? operator}) async {
    return retryAsync(() => api.put('/api/alerts/$alertId/acknowledge', body: {
      if (operator != null) 'operator': operator,
    }));
  }

  Future<List<DeviceItem>> fetchDevices(String gridId) async {
    final cacheKey = 'devices:$gridId';
    try {
      final list = await retryAsync(() => api.getJsonList('/api/device/$gridId/list'));
      await cache.setJsonList(cacheKey, list);
      return list.map((e) => DeviceItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final cached = await cache.getJsonList(cacheKey);
      if (cached != null) {
        return cached.map((e) => DeviceItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  Future<DeviceItem> fetchDeviceDetail(String deviceId) async {
    final json = await retryAsync(() => api.getJson('/api/device/$deviceId/detail'));
    return DeviceItem.fromJson(json);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final cache = ref.watch(cacheStoreProvider);
  return DashboardRepository(api, cache);
});

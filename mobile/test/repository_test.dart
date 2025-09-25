import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solnova_mobile/api/api_client.dart';
import 'package:solnova_mobile/models/summary_result.dart';
import 'package:solnova_mobile/repositories/dashboard_repository.dart';
import 'package:solnova_mobile/services/cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardRepository.fetchSummary', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses production endpoint when available', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/dashboard/summary/grid-1')) {
          return http.Response(jsonEncode({
            'consumption_kW': 10.0,
            'generation_kW': 9.0,
            'battery_soc': 70
          }), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: client), CacheStore(prefs));

      final res = await repo.fetchSummary('grid-1');
      expect(res, isA<SummaryResult>());
      expect(res.fromCache, isFalse);
      expect(res.data.consumptionKW, 10.0);
    });

    test('falls back to prototype endpoint when production fails', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/dashboard/summary/grid-1')) {
          return http.Response('err', 500);
        }
        if (request.url.path.endsWith('/api/dashboard/realtime')) {
          return http.Response(jsonEncode({
            'consumption_kW': 11.0,
            'generation_kW': 8.5,
            'battery_soc': 65
          }), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: client), CacheStore(prefs));

      final res = await repo.fetchSummary('grid-1');
      expect(res.fromCache, isFalse);
      expect(res.data.generationKW, 8.5);
    });

    test('returns cached data when network fails', () async {
      // First, seed cache by successful production call
      final seedClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/dashboard/summary/grid-1')) {
          return http.Response(jsonEncode({
            'consumption_kW': 12.3,
            'generation_kW': 7.8,
            'battery_soc': 55
          }), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final api1 = ApiClient(baseUrl: 'http://host', token: null, client: seedClient);
      final repo1 = DashboardRepository(api1, cache);
      final seed = await repo1.fetchSummary('grid-1');
      expect(seed.fromCache, isFalse);

      // Now switch client to always fail; should return cached
      final failClient = MockClient((_) async => http.Response('boom', 500));
      final repo2 = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: failClient), cache);
      final res = await repo2.fetchSummary('grid-1');
      expect(res.fromCache, isTrue);
      expect(res.data.consumptionKW, 12.3);
    });
  });
}

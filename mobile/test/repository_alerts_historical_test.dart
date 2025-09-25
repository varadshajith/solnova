import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solnova_mobile/api/api_client.dart';
import 'package:solnova_mobile/repositories/dashboard_repository.dart';
import 'package:solnova_mobile/services/cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardRepository Alerts & Historical', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('fetchAlerts caches and returns on failure', () async {
      // Seed with a successful response
      final seedClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/alerts/grid-9')) {
          return http.Response(jsonEncode([
            {"id": "a1", "message": "High temp", "severity": "warning"}
          ]), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final repo1 = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: seedClient), cache);
      final alerts1 = await repo1.fetchAlerts('grid-9');
      expect(alerts1, isNotEmpty);

      // Fail next: should use cache
      final failClient = MockClient((_) async => http.Response('boom', 500));
      final repo2 = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: failClient), cache);
      final alerts2 = await repo2.fetchAlerts('grid-9');
      expect(alerts2.length, alerts1.length);
      expect(alerts2.first.message, 'High temp');
    });

    test('fetchHistorical caches and returns on failure', () async {
      // Seed with a successful response
      final seedClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/historical/grid-9/consumption_kW')) {
          return http.Response(jsonEncode([
            {"time": DateTime.now().toIso8601String(), "value": 10.1},
            {"time": DateTime.now().toIso8601String(), "value": 10.2}
          ]), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final repo1 = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: seedClient), cache);
      final hist1 = await repo1.fetchHistorical('grid-9', 'consumption_kW', '1h');
      expect(hist1, isNotEmpty);

      // Fail next: should use cache
      final failClient = MockClient((_) async => http.Response('boom', 500));
      final repo2 = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: failClient), cache);
      final hist2 = await repo2.fetchHistorical('grid-9', 'consumption_kW', '1h');
      expect(hist2.length, hist1.length);
    });

    test('acknowledgeAlert success true', () async {
      final client = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path.contains('/api/alerts/a1/acknowledge')) {
          return http.Response('', 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final repo = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: client), cache);
      final ok = await repo.acknowledgeAlert('a1');
      expect(ok, isTrue);
    });
  });
}

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

  group('Repository extras', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('acknowledgeAlert returns false on non-2xx', () async {
      final client = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path.contains('/api/alerts/a1/acknowledge')) {
          return http.Response('', 500);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final repo = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: client), cache);
      final ok = await repo.acknowledgeAlert('a1');
      expect(ok, isFalse);
    });

    test('historical request includes granularity parameter', () async {
      late Uri captured;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/historical/grid-5/consumption_kW')) {
          captured = request.url;
          return http.Response(jsonEncode([
            {"time": DateTime.now().toIso8601String(), "value": 9.9}
          ]), 200);
        }
        return http.Response('not found', 404);
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheStore(prefs);
      final repo = DashboardRepository(ApiClient(baseUrl: 'http://host', token: null, client: client), cache);

      await repo.fetchHistorical('grid-5', 'consumption_kW', '1h', granularity: '5m');
      expect(captured.queryParameters['granularity'], '5m');
    });
  });
}

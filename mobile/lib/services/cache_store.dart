import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CacheStore {
  final SharedPreferences prefs;
  const CacheStore(this.prefs);

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await prefs.setString(key, jsonEncode({'ts': DateTime.now().toIso8601String(), 'data': value}));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return (decoded['data'] as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> setJsonList(String key, List<dynamic> list) async {
    await prefs.setString(key, jsonEncode({'ts': DateTime.now().toIso8601String(), 'data': list}));
  }

  Future<List<dynamic>?> getJsonList(String key) async {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<dynamic>();
    } catch (_) {
      return null;
    }
  }
}

final cacheStoreProvider = Provider<CacheStore>((ref) => throw UnimplementedError('Override in main ProviderScope if needed'));

final cacheStoreInitProvider = FutureProvider<CacheStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CacheStore(prefs);
});

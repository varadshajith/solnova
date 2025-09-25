import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../main.dart';

class ApiClient {
  final String baseUrl;
  final String? token;
  final http.Client client;
  ApiClient({required this.baseUrl, required this.token, http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> getJson(String path, [Map<String, String>? query]) async {
    final resp = await client.get(_uri(path, query), headers: _headers());
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET $path failed (${resp.statusCode})');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getJsonList(String path, [Map<String, String>? query]) async {
    final resp = await client.get(_uri(path, query), headers: _headers());
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('GET $path failed (${resp.statusCode})');
    }
    return (jsonDecode(resp.body) as List).cast<dynamic>();
  }

  Future<bool> put(String path, {Map<String, String>? query, Map<String, dynamic>? body}) async {
    final resp = await client.put(_uri(path, query), headers: _headers(), body: body == null ? null : jsonEncode(body));
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  final tok = ref.watch(tokenProvider);
  return ApiClient(baseUrl: base, token: tok);
});

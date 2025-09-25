import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class Microgrid {
  final String id;
  final String name;
  const Microgrid({required this.id, required this.name});

  factory Microgrid.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? 'unknown';
    final name = (j['name']?.toString() ?? 'Microgrid $id').trim();
    return Microgrid(id: id, name: name.isEmpty ? 'Microgrid $id' : name);
  }
}

class MicrogridSelectionScreen extends HookConsumerWidget {
  const MicrogridSelectionScreen({super.key});

  Future<List<Microgrid>> _fetchMicrogrids(BuildContext context, WidgetRef ref) async {
    final base = ref.read(apiBaseUrlProvider);
    final token = ref.read(tokenProvider);
    try {
      // Try a production-style endpoint first
      final resp = await http.get(
        Uri.parse('$base/api/microgrids'),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
        return list.map((e) => Microgrid.fromJson(e)).toList();
      }
    } catch (_) {
      // fall through to stub
    }
    // Fallback stub list to keep UX functional pre-backend
    return const [
      Microgrid(id: 'grid-001', name: 'Community A'),
      Microgrid(id: 'grid-002', name: 'Community B'),
      Microgrid(id: 'grid-003', name: 'Community C'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = useMemoized(() => _fetchMicrogrids(context, ref));
    return Scaffold(
      appBar: AppBar(title: const Text('Select Microgrid')),
      body: FutureBuilder<List<Microgrid>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <Microgrid>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No microgrids available'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = items[i];
              return Card(
                child: ListTile(
                  title: Text(m.name),
                  subtitle: Text('ID: ${m.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selectedGridIdProvider.notifier).state = m.id;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(gridId: m.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends ConsumerWidget {
  final String gridId;
  const DevicesScreen({super.key, required this.gridId});

  Color _statusColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'connected':
        return Colors.greenAccent;
      case 'disconnected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devicesProvider(gridId));
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load devices: $e'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => ref.invalidate(devicesProvider(gridId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No devices'));
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(devicesProvider(gridId));
              await ref.read(devicesProvider(gridId).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = items[i];
                return Card(
                  child: ListTile(
                    title: Text(d.name.isEmpty ? d.id : d.name),
                    subtitle: Text('ID: ${d.id}${d.lastSeen != null ? ' • ${d.lastSeen!.toLocal()}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: _statusColor(d.status), size: 12),
                        const SizedBox(width: 6),
                        Text(d.status ?? 'unknown', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: d.id, gridId: gridId, item: d)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
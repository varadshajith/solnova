import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../repositories/dashboard_repository.dart';
import '../models/device.dart';

class DeviceDetailScreen extends HookConsumerWidget {
  final String gridId;
  final String deviceId;
  final DeviceItem item;
  const DeviceDetailScreen({super.key, required this.gridId, required this.deviceId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
final future = useMemoized<Future<DeviceItem>>(() async => item.type == null && item.firmware == null
        ? await ref.read(dashboardRepositoryProvider).fetchDeviceDetail(deviceId)
        : item);
    return Scaffold(
      appBar: AppBar(title: const Text('Device Details')),
      body: FutureBuilder<DeviceItem>(
        future: future,
        builder: (context, snap) {
          final d = snap.data ?? item;
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name.isEmpty ? d.id : d.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _RowKV('ID', d.id),
                if (d.type != null) _RowKV('Type', d.type!),
                if (d.firmware != null) _RowKV('Firmware', d.firmware!),
                if (d.status != null) _RowKV('Status', d.status!),
                if (d.lastSeen != null) _RowKV('Last seen', d.lastSeen!.toLocal().toString()),
                const SizedBox(height: 24),
                const Text('Telemetry', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Coming soon: per-device telemetry and commands.'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RowKV extends StatelessWidget {
  final String k;
  final String v;
  const _RowKV(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(k, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white70))),
          Expanded(child: Text(v, style: Theme.of(context).textTheme.labelLarge)),
        ],
      ),
    );
  }
}

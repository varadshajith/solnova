import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers.dart';
import '../models/alert.dart';
import '../repositories/dashboard_repository.dart';

class AlertsScreen extends HookConsumerWidget {
  final String gridId;
  const AlertsScreen({super.key, required this.gridId});

  Color _severityColor(String? sev) {
    switch ((sev ?? '').toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF3B30);
      case 'warning':
        return const Color(0xFFFF9500);
      case 'info':
        return const Color(0xFF5AC8FA);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState('active');
    final alertsAsync = ref.watch(alertsByStatusProvider((gridId: gridId, status: status.value)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          PopupMenuButton<String>(
            initialValue: status.value,
            onSelected: (v) => status.value = v,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'active', child: Text('Active')),
              PopupMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
          )
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load alerts: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No alerts'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = items[i];
              final color = _severityColor(a.severity);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.warning_amber_rounded, color: Colors.white)),
                  title: Text(a.message),
                  subtitle: Text('ID: ${a.id}${a.timestamp != null ? ' • ${a.timestamp!.toLocal()}' : ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AlertDetailScreen(gridId: gridId, alert: a)),
                    );
                    // Refresh after returning
                    ref.invalidate(alertsByStatusProvider((gridId: gridId, status: status.value)));
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

class AlertDetailScreen extends HookConsumerWidget {
  final String gridId;
  final AlertItem alert;
  const AlertDetailScreen({super.key, required this.gridId, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    final busy = useState(false);
    Future<void> acknowledge() async {
      busy.value = true;
      try {
        final ok = await repo.acknowledgeAlert(alert.id);
        if (!context.mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert acknowledged')));
          // Invalidate alert lists (active/resolved) to refresh UI after ack
          ref.invalidate(alertsByStatusProvider((gridId: gridId, status: 'active')));
          ref.invalidate(alertsByStatusProvider((gridId: gridId, status: 'resolved')));
          Navigator.of(context).maybePop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to acknowledge')));
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Severity: ${alert.severity ?? 'unknown'}'),
            if (alert.timestamp != null) Text('Time: ${alert.timestamp!.toLocal()}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy.value ? null : acknowledge,
                icon: const Icon(Icons.check_circle_outline),
                label: busy.value ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Acknowledge'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

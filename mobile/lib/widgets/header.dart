import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String lastUpdatedText;
  final bool? online;
  const AppHeader({super.key, required this.title, required this.lastUpdatedText, this.online});

  @override
  Widget build(BuildContext context) {
    final onlineChip = online == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (online! ? Colors.green : Colors.red).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(online! ? Icons.wifi : Icons.wifi_off, size: 14, color: online! ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(width: 6),
                Text(online! ? 'Online' : 'Offline', style: TextStyle(fontSize: 12, color: online! ? Colors.greenAccent : Colors.redAccent)),
              ],
            ),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800))),
                      if (onlineChip != null) onlineChip,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(lastUpdatedText, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.account_circle_outlined)
          ],
        ),
      ),
    );
  }
}

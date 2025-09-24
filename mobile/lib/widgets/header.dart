import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String lastUpdatedText;
  const AppHeader({super.key, required this.title, required this.lastUpdatedText});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
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
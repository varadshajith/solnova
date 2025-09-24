import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onViewAll;
  const AlertBanner({super.key, required this.message, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A3D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.white.withOpacity(0.2)),
            onPressed: onViewAll,
            child: const Text('VIEW ALL'),
          )
        ],
      ),
    );
  }
}
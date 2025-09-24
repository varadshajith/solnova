import 'dart:async';
import 'package:flutter/material.dart';

class AlertsCarousel extends StatefulWidget {
  final List<String> messages;
  final VoidCallback? onViewAll;
  const AlertsCarousel({super.key, required this.messages, this.onViewAll});

  @override
  State<AlertsCarousel> createState() => _AlertsCarouselState();
}

class _AlertsCarouselState extends State<AlertsCarousel> {
  late final PageController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    if (widget.messages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        final next = (_controller.page?.round() ?? 0) + 1;
        _controller.animateToPage(next % widget.messages.length, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.messages.length,
        itemBuilder: (context, i) {
          final msg = widget.messages[i];
          return Container(
            decoration: BoxDecoration(color: const Color(0xFFFF6A3D), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.white.withOpacity(0.2)),
                  child: const Text('VIEW ALL'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
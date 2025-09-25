import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushService {
  Future<void> init(WidgetRef ref) async {
    // Initialize Firebase (no-op if already initialized)
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // If google-services.json is missing, this may fail; ignore to keep app running
      return;
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permissions (Android 13+ and Apple). We’ll also expose a UI prompt in Dashboard.
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    // Subscribe to a topic for critical alerts
    try {
      await FirebaseMessaging.instance.subscribeToTopic('critical-alerts');
    } catch (_) {}

    // Foreground handling: Show a basic SnackBar for demo purposes
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && message.notification != null) {
        final notif = message.notification!;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(notif.title ?? notif.body ?? 'New alert')),
        );
      }
    });
  }
}

final navigatorKey = GlobalKey<NavigatorState>();

final pushInitProvider = FutureProvider<void>((ref) async {
  final svc = PushService();
  await svc.init(ref as WidgetRef);
});
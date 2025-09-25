import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum PushPermissionState { granted, denied, restricted, unknown }

final pushPermissionProvider = FutureProvider<PushPermissionState>((ref) async {
  // On platforms without runtime permission (older Android), treat as granted
  if (!Platform.isAndroid && !Platform.isIOS) return PushPermissionState.granted;
  // Using firebase_messaging as primary, fallback to permission_handler for Android 13+
  try {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PushPermissionState.granted;
      case AuthorizationStatus.denied:
        return PushPermissionState.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermissionState.unknown;
    }
  } catch (_) {}
  // Fallback check via permission_handler
  final status = await Permission.notification.status;
  if (status.isGranted) return PushPermissionState.granted;
  if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) return PushPermissionState.denied;
  return PushPermissionState.unknown;
});

final requestPushPermissionProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Permission.notification.request();
    return result.isGranted;
  } catch (_) {
    return false;
  }
});
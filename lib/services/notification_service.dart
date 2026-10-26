import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:chat_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level so it can run in its own isolate.
/// Register in main(): FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');

  if (message.data.containsKey('badge_count')) {
    await FirebaseNotificationService.updateBadge(message.data['badge_count']);
  }
}

class FirebaseNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _saveTokenToFirestore();

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen(
        (newToken) => _saveTokenToFirestore(token: newToken),
        onError: (e) => debugPrint('Token refresh error: $e'),
      );
    }

    _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      if (message.data.containsKey('badge_count')) {
        updateBadge(message.data['badge_count']);
      }
    });

    await _initPushNotifications();
  }

  Future<void> _saveTokenToFirestore({String? token}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // iOS needs the APNS token before an FCM token is available.
      if (token == null && !kIsWeb && Platform.isIOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint('APNS token not ready yet');
          return;
        }
      }

      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Call on logout so the device stops receiving the old user's pushes.
  Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
    await _messaging.deleteToken();
  }

  static Future<void> updateBadge(dynamic badgeData) async {
    try {
      final count = int.tryParse(badgeData.toString()) ?? 0;
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (e) {
      debugPrint('Failed to update badge: $e');
    }
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'senderId': message.data['senderId'],
        'receiverId': message.data['receiverId'],
      },
    );
  }

  Future<void> _initPushNotifications() async {
    final initial = await _messaging.getInitialMessage();
    handleMessage(initial);

    _onOpenedSub?.cancel();
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
  }
}

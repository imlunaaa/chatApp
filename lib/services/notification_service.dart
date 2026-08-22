import 'package:chat_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.notification?.title}');
      // Handle the message and show a notification if needed
    });

    final FCMToken = await _firebaseMessaging.getToken();
    print('FCM Token: $FCMToken');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    initPushNotifications();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling a background message: ${message.notification?.title}');
    // Handle the background message and show a notification if needed
  }

  void handleMessage(RemoteMessage? message) {
    if (message != null) {
      return;
    }

    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'senderId': message!.data['senderId'],
        'receiverId': message.data['receiverId'],
      },
    );
  }

  Future initPushNotifications() async {
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}

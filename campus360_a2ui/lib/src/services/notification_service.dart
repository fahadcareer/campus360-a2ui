import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("DEBUG FCM: Handling a background message: ${message.messageId}");
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground push messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          showNotification(
            title: message.notification!.title ?? "Notification",
            body: message.notification!.body ?? "",
          );
        }
      });

      print("DEBUG FCM: Firebase initialized with background and foreground handlers.");
    } catch (e) {
      print("DEBUG FCM: Firebase initialization failed: $e");
    }

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: const DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("DEBUG NOTIFICATION: Notification clicked with payload: ${response.payload}");
      },
    );
  }

  static Future<String?> getFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      print("DEBUG FCM: Got FCM Token: $token");
      return token;
    } catch (e) {
      print("DEBUG FCM: Error getting FCM token: $e");
      return null;
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        "a2ui_notifications",
        "A2UI Bot Notifications",
        channelDescription: "Notifications from A2UI Bot",
        importance: Importance.max,
        priority: Priority.high,
        ticker: "ticker",
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

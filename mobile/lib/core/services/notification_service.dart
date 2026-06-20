import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission (Required for iOS and Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Setup Local Notifications for foreground messages
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    // FIX 1: Gunakan Named Argument di sini
    await _localNotifications.initialize(settings: initSettings);

    // Create Notification Channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      sendTokenToServer(newToken);
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> sendTokenToServer([String? token]) async {
    try {
      final fcmToken = token ?? await getToken();
      if (fcmToken == null) return;

      final prefs = EncryptedSharedPreferences();
      final authToken = await prefs.getString('auth_token');

      if (authToken.isEmpty) return;

      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      await dio.post('/fcm-token', data: {'fcm_token': fcmToken});
    } catch (e) {
      // Ignore errors silently for now
    }
  }

  static Future<void> deleteTokenFromServer() async {
    try {
      final prefs = EncryptedSharedPreferences();
      final authToken = await prefs.getString('auth_token');

      if (authToken.isEmpty) return;

      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      await dio.delete('/fcm-token');
    } catch (e) {
      // Ignore errors silently for now
    }
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/loan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 타임존 초기화
    tz.initializeTimeZones();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await _initializeLocalNotifications();

    NotificationSettings settings = await messaging.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
    debugPrint('settings: ${settings.authorizationStatus}');
    // 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 앱이 종료된 상태에서 알림을 탭하여 앱이 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: $message');
      _handleMessage(message, isFromBackground: true);
    });

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('onMessage: $message');
      _handleMessage(message, isFromBackground: false);
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('onBackgroundMessage: $message');

    // 백그라운드에서 알림 표시
    await _showNotification(
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      "@mipmap/ic_launcher",
    );
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true, // iOS에서 기본적으로 알림 표시
      defaultPresentBadge: true, // iOS에서 기본적으로 배지 표시
      defaultPresentSound: true, // iOS에서 기본적으로 소리 재생
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _localNotifications.initialize(settings);
  }

  static void _handleMessage(
    RemoteMessage message, {
    required bool isFromBackground,
  }) {
    if (message.notification != null) {
      // 포그라운드에서 알림 표시
      if (!isFromBackground) {
        _showNotification(
          title: message.notification?.title ?? '알림',
          body: message.notification?.body ?? '',
          payload: message.data.toString(),
        );
      }
    }
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          '기본 채널',
          channelDescription: '기본 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      badgeNumber: 1,
      presentAlert: true, // iOS에서 알림 표시
      presentBadge: true, // iOS에서 배지 표시
      presentSound: true, // iOS에서 소리 재생
      interruptionLevel: InterruptionLevel.active, // iOS 15+ 알림 우선순위
      categoryIdentifier: 'default', // 알림 카테고리
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // 고유한 알림 ID
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint('Local notification shown successfully');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }
}

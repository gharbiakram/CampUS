import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'smartcampus_updates';
  static const String _channelName = 'SmartCampus Updates';
  static const String _channelDescription = 'Simple alerts for the SmartCampus app';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await _requestNotificationPermission();

    _initialized = true;
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;

    try {
      await Permission.notification.request();
    } catch (_) {
      // Keep notifications best-effort; the app should still work if permission is unavailable.
    }
  }

  Future<void> showEventCreatedNotification({
    required int id,
    required String title,
  }) async {
    await showUpdateNotification(
      id: id,
      title: 'New event added',
      body: title,
    );
  }

  Future<void> showTestNotification() async {
    await initialize();

    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      1,
      'SmartCampus',
      'This is a test notification.',
      notificationDetails,
    );
  }

  Future<void> showUpdateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, notificationDetails);
  }
}

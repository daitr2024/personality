import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../config/routes/app_router.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap — navigate to home screen
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Navigate to home screen where the task/event can be viewed
    // Payload format: "task_{id}" or "event_{id}"
    debugPrint(
      'NotificationService: Notification tapped with payload: $payload',
    );
    router.go('/home');
  }

  /// Request notification permissions (iOS and Android 13+)
  Future<bool> requestPermissions() async {
    // iOS permissions
    final bool? iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    bool androidResult = true;
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final bool? granted = await androidPlugin
            .requestNotificationsPermission();
        androidResult = granted ?? false;

        // Check/Request exact alarm permission for Android 12+
        final bool? canScheduleExact = await androidPlugin
            .canScheduleExactNotifications();
        if (canScheduleExact == false) {
          debugPrint(
            'NotificationService: Exact alarm permission not granted, requesting...',
          );
          // This usually requires an intent to settings, but some plugins have a request method
          // In flutter_local_notifications 17+, you can use:
          await androidPlugin.requestExactAlarmsPermission();
        }
      }
    }

    return (iosResult ?? true) && androidResult;
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      debugPrint(
        'NotificationService: Scheduling notification ID $id at $scheduledDate',
      );

      // On Android, check for exact alarm permission if possible
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final bool? canScheduleExact = await androidPlugin
              .canScheduleExactNotifications();
          debugPrint(
            'NotificationService: Can schedule exact notifications: $canScheduleExact',
          );
        }
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Hatırlatıcılar',
            channelDescription: 'Görev ve etkinlik hatırlatıcıları',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      // Notification scheduling failed (e.g. past date or missing permissions)
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Hatırlatıcılar',
          channelDescription: 'Görev ve etkinlik hatırlatıcıları',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

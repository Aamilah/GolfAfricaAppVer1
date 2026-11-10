import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class NotiService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    await notificationPlugin.initialize(initSettings);

    const AndroidNotificationChannel notificationChannel =
        AndroidNotificationChannel(
          'daily_channel_id',
          'Daily Notification',
          description: 'Daily Notification Channel',
          importance: Importance.max,
        );

    await notificationPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(notificationChannel);

    await notificationPlugin.initialize(initSettings);
    await requestNotificationPermission();

    _isInitialized = true;
    print("Notification Initialized!");
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  NotificationDetails notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_channel_id',
          'Daily Notification',
          channelDescription: 'Daily Notification Channel',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('mysound'),
          playSound: true,
        );

    return const NotificationDetails(android: androidDetails);
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? expandedBody, // Add expandedBody parameter
  }) async {
    // Use BigTextStyleInformation for expanding the body in notifications
    var androidDetails = AndroidNotificationDetails(
      'daily_channel_id',
      'Daily Notification',
      channelDescription: 'Daily Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('mysound'),
      playSound: true,
      styleInformation:
          expandedBody != null
              ? BigTextStyleInformation(
                expandedBody,
                contentTitle: title,
                summaryText: body,
              )
              : null, // Only add BigTextStyleInformation if expandedBody is not null
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await notificationPlugin.show(id, title, body, notificationDetails);
  }

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    String? expandedBody,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    print("Current time: $now");
    print("Scheduled time: $scheduleDate");

    var androidDetails = AndroidNotificationDetails(
      'daily_channel_id',
      'Daily Notification',
      channelDescription: 'Daily Notification Channel',
      styleInformation: BigTextStyleInformation(
        expandedBody ?? body,
        contentTitle: title,
        summaryText: body,
      ),
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('mysound'), // Custom sound
      playSound: true,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("Scheduled Notification at: $scheduleDate");
  }

  Future<void> cancelAllNotifications() async {
    await notificationPlugin.cancelAll();
  }
}

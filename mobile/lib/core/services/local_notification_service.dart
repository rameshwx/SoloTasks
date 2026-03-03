import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../logic/reminder_rules.dart';
import '../models/app_models.dart';
import '../models/remote_models.dart';

final localNotificationService = LocalNotificationService();

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription =
      'Notifications for scheduled task reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _attemptedExactAlarmPermission = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> syncTaskReminders({
    required TaskViewModel task,
    required List<ReminderItem> reminders,
  }) async {
    if (kIsWeb) return;
    await initialize();
    for (final reminder in reminders) {
      await scheduleReminder(task: task, reminder: reminder);
    }
  }

  Future<void> scheduleReminder({
    required TaskViewModel task,
    required ReminderItem reminder,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final scheduledAtUtc =
        resolveReminderScheduleUtc(task: task, reminder: reminder);
    if (scheduledAtUtc == null) {
      await cancelReminder(reminder.id);
      return;
    }

    final androidScheduleMode = await _androidScheduleMode();

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _notificationIdFor(reminder.id),
      'Kronos Reminder',
      _notificationBody(task, reminder),
      tz.TZDateTime.from(scheduledAtUtc, tz.UTC),
      details,
      androidScheduleMode: androidScheduleMode,
      payload: task.id,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(_notificationIdFor(reminderId));
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final canExact = await android.canScheduleExactNotifications();
    if (canExact == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    if (!_attemptedExactAlarmPermission) {
      _attemptedExactAlarmPermission = true;
      try {
        final granted = await android.requestExactAlarmsPermission();
        if (granted == true) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      } catch (_) {
        // Fall back to inexact scheduling if exact alarms aren't granted.
      }
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  String _notificationBody(TaskViewModel task, ReminderItem reminder) {
    if (reminder.isRelative) {
      final minutes = reminder.offsetMinFromTaskStart;
      return minutes == null
          ? task.title
          : '${task.title} starts in $minutes minutes.';
    }
    return 'Reminder for ${task.title}.';
  }

  int _notificationIdFor(String reminderId) {
    var hash = 0x811C9DC5;
    for (final codeUnit in reminderId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

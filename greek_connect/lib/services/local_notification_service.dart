import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum gcReminderScheduleResult {
  scheduledExact,
  scheduledInexact,
  skippedWeb,
  skippedTooSoon,
  skippedNoPermission,
}

class gcLocalNotificationService {
  gcLocalNotificationService._();

  static final gcLocalNotificationService instance = gcLocalNotificationService
      ._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<gcReminderScheduleResult> scheduleRsvpReminder({
    required String eventId,
    required String title,
    required DateTime eventStartLocal,
  }) async {
    if (kIsWeb) return gcReminderScheduleResult.skippedWeb;
    if (!_initialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsEnabled = await androidPlugin?.areNotificationsEnabled();
    if (notificationsEnabled == false) {
      debugPrint('Notifications disabled at OS level; reminder not scheduled.');
      return gcReminderScheduleResult.skippedNoPermission;
    }

    final reminderAt = eventStartLocal.subtract(const Duration(hours: 1));
    if (!reminderAt.isAfter(DateTime.now())) {
      debugPrint(
        'Reminder skipped because event is less than 1 hour away: $eventId',
      );
      return gcReminderScheduleResult.skippedTooSoon;
    }

    final notificationId = _stableNotificationId(eventId);

    final scheduled = tz.TZDateTime.from(reminderAt, tz.local);

    try {
      await _notifications.zonedSchedule(
        id: notificationId,
        title: 'Event Reminder',
        body: '$title starts in 1 hour',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Event Reminders',
            channelDescription: 'Reminder notifications for RSVP events',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: eventId,
      );
      debugPrint('Reminder scheduled in exact mode for $eventId at $scheduled');
      return gcReminderScheduleResult.scheduledExact;
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;

      // Fall back on inexact alarms when user/device disallows exact alarms.
      await _notifications.zonedSchedule(
        id: notificationId,
        title: 'Event Reminder',
        body: '$title starts in 1 hour',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Event Reminders',
            channelDescription: 'Reminder notifications for RSVP events',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: eventId,
      );
      debugPrint(
        'Reminder scheduled in inexact mode for $eventId at $scheduled',
      );
      return gcReminderScheduleResult.scheduledInexact;
    }
  }

  Future<void> cancelRsvpReminder(String eventId) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    await _notifications.cancel(id: _stableNotificationId(eventId));
  }

  Future<gcReminderScheduleResult> scheduleTestNotification() async {
    if (kIsWeb) return gcReminderScheduleResult.skippedWeb;
    if (!_initialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsEnabled = await androidPlugin?.areNotificationsEnabled();
    if (notificationsEnabled == false) {
      debugPrint('Notifications disabled at OS level; test not scheduled.');
      return gcReminderScheduleResult.skippedNoPermission;
    }

    final testTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    try {
      await _notifications.zonedSchedule(
        id: _stableNotificationId('gc_test_notification'),
        title: 'Greek Connect Test',
        body: 'If you see this, local notifications are working.',
        scheduledDate: testTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Event Reminders',
            channelDescription: 'Reminder notifications for RSVP events',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'gc_test_notification',
      );
      debugPrint('Test notification scheduled in exact mode at $testTime');
      return gcReminderScheduleResult.scheduledExact;
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;

      await _notifications.zonedSchedule(
        id: _stableNotificationId('gc_test_notification'),
        title: 'Greek Connect Test',
        body: 'If you see this, local notifications are working.',
        scheduledDate: testTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Event Reminders',
            channelDescription: 'Reminder notifications for RSVP events',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'gc_test_notification',
      );
      debugPrint('Test notification scheduled in inexact mode at $testTime');
      return gcReminderScheduleResult.scheduledInexact;
    }
  }

  int _stableNotificationId(String input) {
    var hash = 2166136261;
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}

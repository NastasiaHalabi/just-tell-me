import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../contracts.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<LocalNotificationScheduler> create() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Beirut'));
    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    return LocalNotificationScheduler(plugin);
  }

  @override
  Future<PermissionOutcome> ensurePermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) {
        return const PermissionOutcome(
          granted: false,
          message: 'Notifications are off. I saved the reminder on this device, but I cannot alert you until you allow notifications.',
        );
      }
      return const PermissionOutcome(granted: true, message: 'Notifications allowed.');
    } catch (_) {
      return const PermissionOutcome(
        granted: false,
        message: 'This device cannot schedule notifications yet. The reminder is still saved locally.',
      );
    }
  }

  @override
  Future<bool> schedule({
    required String id,
    required String title,
    required DateTime when,
    String? body,
  }) async {
    if (!when.isAfter(DateTime.now())) {
      return false;
    }
    try {
      await _plugin.zonedSchedule(
        id.hashCode,
        title,
        body ?? title,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'just_tell_me_reminders',
            'Reminders',
            channelDescription: 'Local reminders created by Just Tell Me',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

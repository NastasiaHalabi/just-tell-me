import 'package:flutter/material.dart';

import 'core/api/client.dart';
import 'features/command/command_screen.dart';
import 'integrations/calendar/native_calendar.dart';
import 'integrations/contacts/device_contacts.dart';
import 'integrations/contracts.dart';
import 'integrations/notifications/local_notifications.dart';
import 'integrations/speech/speech_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationScheduler? notifications;
  try {
    notifications = await LocalNotificationScheduler.create();
  } catch (_) {
    notifications = null;
  }
    final api = this.api ?? JustTellMeApi();
  await api.loadSavedUrl();
  runApp(JustTellMeApp(notifications: notifications, api: api));
}

class JustTellMeApp extends StatelessWidget {
  const JustTellMeApp({super.key, this.notifications, this.api});

  final NotificationScheduler? notifications;
  final JustTellMeApi? api;

  @override
  Widget build(BuildContext context) {
    final api = this.api ?? JustTellMeApi();
    return MaterialApp(
      title: 'Just Tell Me',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: CommandScreen(
        api: api,
        notifications: notifications,
        contacts: DeviceContactDirectory(),
        calendar: NativeCalendarAdapter(),
        speech: DeviceSpeechToTextProvider(),
      ),
    );
  }
}

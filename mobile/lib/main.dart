import 'package:flutter/material.dart';

import 'core/api/client.dart';
import 'features/command/command_screen.dart';
import 'integrations/calendar/native_calendar.dart';
import 'integrations/contacts/device_contacts.dart';
import 'integrations/contracts.dart';
import 'integrations/notifications/local_notifications.dart';
import 'integrations/speech/speech_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationScheduler? notifications;
  try {
    notifications = await LocalNotificationScheduler.create();
  } catch (_) {
    notifications = null;
  }
  final api = JustTellMeApi();
  await api.loadSavedUrl();
  runApp(JustTellMeApp(notifications: notifications, api: api));
}

class JustTellMeApp extends StatefulWidget {
  const JustTellMeApp({super.key, this.notifications, this.api, this.themeController});

  final NotificationScheduler? notifications;
  final JustTellMeApi? api;
  final ThemeController? themeController;

  @override
  State<JustTellMeApp> createState() => _JustTellMeAppState();
}

class _JustTellMeAppState extends State<JustTellMeApp> {
  late final ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.themeController ?? ThemeController();
    _theme.load();
  }

  @override
  void dispose() {
    if (widget.themeController == null) {
      _theme.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.api ?? JustTellMeApi();
    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'Just Tell Me',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: _theme.mode,
          home: CommandScreen(
            api: client,
            notifications: widget.notifications,
            contacts: DeviceContactDirectory(),
            calendar: NativeCalendarAdapter(),
            speech: DeviceSpeechToTextProvider(),
            themeController: _theme,
          ),
        );
      },
    );
  }
}

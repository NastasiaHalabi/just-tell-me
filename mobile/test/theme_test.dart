import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_tell_me/theme/app_theme.dart';
import 'package:just_tell_me/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('theme defaults to dark and persists light', () async {
    final controller = ThemeController();
    await controller.load();
    expect(controller.mode, ThemeMode.dark);

    await controller.setDark(false);
    expect(controller.mode, ThemeMode.light);

    final again = ThemeController();
    await again.load();
    expect(again.mode, ThemeMode.light);
  });

  test('light and dark palettes keep the lime accent', () {
    expect(AppPalette.dark.bubbleMine, limeAccent);
    expect(AppPalette.light.bubbleMine, limeAccent);
    expect(buildDarkTheme().brightness, Brightness.dark);
    expect(buildLightTheme().brightness, Brightness.light);
    expect(buildDarkTheme().scaffoldBackgroundColor, AppPalette.dark.background);
    expect(buildLightTheme().scaffoldBackgroundColor, AppPalette.light.background);
  });
}

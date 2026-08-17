import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_tell_me/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows command UI', (WidgetTester tester) async {
    await tester.pumpWidget(const JustTellMeApp());
    await tester.pump();
    expect(find.text('Just Tell Me'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('theme toggle switches to light', (WidgetTester tester) async {
    await tester.pumpWidget(const JustTellMeApp());
    await tester.pump();
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
  });
}


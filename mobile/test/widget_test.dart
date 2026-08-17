import 'dart:convert';

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

  testWidgets('long press upcoming task can delete it', (WidgetTester tester) async {
    final due = DateTime.now().add(const Duration(hours: 2));
    SharedPreferences.setMockInitialValues({
      'local_tasks': [
        jsonEncode({
          'id': 'task-1',
          'title': 'Message Maya',
          'due_at': due.toIso8601String(),
          'reminder_at': due.toIso8601String(),
          'status': 'open',
        }),
      ],
    });
    await tester.pumpWidget(const JustTellMeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Message Maya'), findsOneWidget);
    await tester.longPress(find.text('Message Maya'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Message Maya'), findsNothing);
  });
}


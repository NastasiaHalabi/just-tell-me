import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:just_tell_me/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('home screen shows command UI', (WidgetTester tester) async {
    await tester.pumpWidget(const JustTellMeApp());
    await tester.pump();
    expect(find.text('Just Tell Me'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lexicode_app/main.dart';
import 'package:lexicode_app/core/providers/app_provider.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const LexiCodeApp(),
      ),
    );

    // Verify splash screen shows
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

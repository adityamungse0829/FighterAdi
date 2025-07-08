// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fighter/main.dart';
import 'package:fighter/screens/auth_screen.dart';
import 'package:provider/provider.dart';
import 'package:fighter/screens/task_provider.dart';
import 'package:fighter/screens/user_provider.dart';

void main() {
  testWidgets('App smoke test: App launches and shows AuthScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // The main() function in main.dart wraps the app in MultiProvider.
    // We need to replicate that setup here for the test to work correctly.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const FighterApp(),
      ),
    );

    // Wait for widgets to settle, especially after async operations like theme loading.
    await tester.pumpAndSettle();

    // In a default test environment, the user is not authenticated,
    // so we expect the AuthScreen to be displayed.
    expect(find.byType(AuthScreen), findsOneWidget);

    // Verify key widgets on the AuthScreen are present.
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}

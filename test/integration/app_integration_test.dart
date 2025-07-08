import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/main.dart';
import 'package:fighter/screens/auth_screen.dart';
import 'package:fighter/screens/tasks_screen.dart';
import 'package:fighter/screens/calendar_screen.dart';
import 'package:fighter/screens/settings_screen.dart';
import 'package:fighter/widgets/main_shell.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';

// Helper function to pump the app with providers
Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const FighterApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('App Integration Tests', () {
    testWidgets('IT_001: Complete user authentication flow', (WidgetTester tester) async {
      await pumpApp(tester);
      debugDumpApp();
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Integration Test User');
      await tester.ensureVisible(find.text('Continue with Name'));
      debugDumpApp();
      await tester.tap(find.text('Continue with Name'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(TasksScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('IT_002: Complete task management workflow', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Task Test User');
      await tester.ensureVisible(find.text('Continue with Name'));
      debugDumpApp();
      await tester.tap(find.text('Continue with Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'My Test Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('My Test Task'), findsOneWidget);
      // Complete the task (simulate tap on checkbox or leading icon)
      // You may need to adjust this depending on your UI
      final checkIcon = find.byIcon(Icons.check_circle_outline).first;
      await tester.tap(checkIcon);
      await tester.pumpAndSettle();
      // Delete the task by swiping
      await tester.drag(find.text('My Test Task'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
      expect(find.text('My Test Task'), findsNothing);
    });

    testWidgets('IT_003: Data persistence across app restarts', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Persistence Test User');
      await tester.ensureVisible(find.text('Continue with Name'));
      debugDumpApp();
      await tester.tap(find.text('Continue with Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Persistent Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Simulate app restart
      await pumpApp(tester);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Persistent Task'), findsOneWidget);
    });

    testWidgets('IT_006: Guest user functionality', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.ensureVisible(find.text('Continue as Guest'));
      debugDumpApp();
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(TasksScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Guest Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Guest Task'), findsOneWidget);
    });

    testWidgets('IT_007: Navigation between screens', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Navigation Test User');
      await tester.ensureVisible(find.text('Continue with Name'));
      debugDumpApp();
      await tester.tap(find.text('Continue with Name'));
      await tester.pumpAndSettle();
      expect(find.byType(TasksScreen), findsOneWidget);
      // Navigate to calendar (use correct icon)
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsOneWidget);
      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
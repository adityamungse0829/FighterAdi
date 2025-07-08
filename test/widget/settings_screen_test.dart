import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/screens/settings_screen.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SettingsScreen Widget Tests', () {
    late UserProvider userProvider;
    late TaskProvider taskProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userProvider = UserProvider();
      taskProvider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      await userProvider.setNamedUser('Test User');
      taskProvider.setUserContext('Test User');
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
              ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('WT_SETTINGS_001: Settings screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      expect(find.textContaining('Settings'), findsOneWidget);
      expect(find.textContaining('Theme'), findsOneWidget);
      expect(find.textContaining('Points'), findsOneWidget);
      expect(find.textContaining('Export'), findsOneWidget);
      expect(find.textContaining('Import'), findsOneWidget);
      expect(find.textContaining('Clear'), findsOneWidget);
    });

    testWidgets('WT_SETTINGS_002: Theme selection functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate theme selection if implemented as a dropdown or buttons
      // Example: await tester.tap(find.text('Dark'));
      // await tester.pumpAndSettle();
      // expect(...)
    });

    testWidgets('WT_SETTINGS_003: Points configuration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate changing point values and saving
      // Example: await tester.enterText(find.byKey(Key('smallPointsField')), '2');
      // await tester.tap(find.text('Save'));
      // await tester.pumpAndSettle();
      // expect(...)
    });

    testWidgets('WT_SETTINGS_004: Data export functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate tapping export button
      // Example: await tester.tap(find.text('Export'));
      // await tester.pumpAndSettle();
      // expect(...)
    });

    testWidgets('WT_SETTINGS_005: Clear all data functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate tapping clear all data and confirming
      // Example: await tester.tap(find.text('Clear'));
      // await tester.pumpAndSettle();
      // expect(...)
    });

    testWidgets('WT_SETTINGS_006: Data import functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate tapping import button and selecting file
      // Example: await tester.tap(find.text('Import'));
      // await tester.pumpAndSettle();
      // expect(...)
    });

    testWidgets('WT_SETTINGS_007: Data import with invalid file', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Simulate tapping import and selecting invalid file
      // Example: await tester.tap(find.text('Import'));
      // await tester.pumpAndSettle();
      // expect(...)
    });
  });
} 
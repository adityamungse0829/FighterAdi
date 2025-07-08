
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fighter/main.dart'; // Adjust this import if your main entry point is different
import 'package:fighter/screens/launcher_screen.dart';
import 'package:fighter/screens/tasks_screen.dart';
import 'package:fighter/screens/calendar_screen.dart';
import 'package:fighter/widgets/main_shell.dart';

void main() {
  // Test Case 1: App Launch Test
  testWidgets('1. App should launch and display the launcher screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the LauncherScreen is present.
    expect(find.byType(LauncherScreen), findsOneWidget);

    // Verify that the app name or a key piece of text is visible.
    expect(find.text('Fighter'), findsOneWidget);
    expect(find.text('Worship Strength Only.'), findsOneWidget);
  });

  // Test Case 2: Guest Login Navigation
  testWidgets('2. Tapping "Continue as Guest" should navigate to TasksScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Find the "Continue as Guest" button and tap it.
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle(); // Wait for the navigation animation to complete.

    // Verify that TasksScreen is now visible.
    expect(find.byType(TasksScreen), findsOneWidget);
    // Verify the main shell with the floating navigation is also there.
    expect(find.byType(MainShell), findsOneWidget);
  });

  // Test Case 3: Tasks Screen UI Verification
  testWidgets('3. TasksScreen should display initial UI elements', (WidgetTester tester) async {
    // Navigate directly to the TasksScreen for this test.
    await tester.pumpWidget(MaterialApp(home: TasksScreen()));

    // Verify the progress widget is displayed.
    // Note: This assumes a widget or text like 'points' is part of your progress view.
    // You might need to adjust the finder based on your actual implementation.
    expect(find.textContaining('points', findRichText: true), findsOneWidget);

    // Verify the "Add new task" button is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  // Test Case 4: Add Task Action
  testWidgets('4. Tapping the add task button should show a dialog or input field', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TasksScreen()));

    // Tap the add task button.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // Rebuild the widget after the tap.

    // Verify that a dialog or a text field for the new task appears.
    // This is a common pattern. Adjust if your UI behaves differently.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Enter task name...'), findsOneWidget);
  });

  // Test Case 5: Floating Navigation
  testWidgets('5. Floating navigation should switch to the Calendar screen', (WidgetTester tester) async {
    // Build the app starting at the main shell.
    await tester.pumpWidget(const MyApp());
    
    // Navigate past the launcher screen.
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    // Verify we are on the Tasks screen initially.
    expect(find.byType(TasksScreen), findsOneWidget);

    // Find the calendar icon in the floating navigation and tap it.
    await tester.tap(find.byIcon(Icons.calendar_today)); // Use the correct icon for the calendar.
    await tester.pumpAndSettle(); // Wait for the screen transition.

    // Verify that the CalendarScreen is now active.
    expect(find.byType(CalendarScreen), findsOneWidget);
    // Verify that the TasksScreen is no longer active.
    expect(find.byType(TasksScreen), findsNothing);
  });
}

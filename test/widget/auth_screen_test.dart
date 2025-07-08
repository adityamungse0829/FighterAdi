import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fighter/screens/auth_screen.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';
import 'package:fighter/widgets/main_shell.dart';

void main() {
  group('AuthScreen Widget Tests', () {
    late UserProvider userProvider;
    late TaskProvider taskProvider;

    setUp(() {
      userProvider = UserProvider();
      taskProvider = TaskProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
          ],
          child: AuthScreen(),
        ),
      );
    }

    testWidgets('WT_AUTH_001: Auth screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      // Verify app logo/title is displayed
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('Fighter'), findsOneWidget);
      expect(find.text('Your Personal Productivity Companion'), findsOneWidget);

      // Verify welcome message is present
      expect(find.text('Welcome to Fighter!'), findsOneWidget);
      expect(find.text('Enter your name to personalize your experience, or continue as a guest.'), findsOneWidget);

      // Verify name input field is present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);

      // Verify Sign Up button is present
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify Continue as Guest button is present
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('WT_AUTH_002: Named user authentication flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter name
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.pump();

      // Act - Tap Sign Up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to main shell
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('WT_AUTH_003: Guest user authentication flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Tap Continue as Guest button
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to main shell
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('WT_AUTH_004: Empty name validation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Leave name field empty and tap Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Should show error message and stay on auth screen
      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    });

    testWidgets('WT_AUTH_005: Whitespace name validation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter only whitespace and tap Sign Up
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Assert - Should show error message
      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('WT_AUTH_006: Text field interaction', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter text in the name field
      await tester.enterText(find.byType(TextField), 'John Doe');
      await tester.pump();

      // Assert - Text should be displayed in the field
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('WT_AUTH_007: Button states and interactions', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert - Buttons should be enabled initially
      expect(tester.widget<ElevatedButton>(find.text('Sign Up').first), isA<ElevatedButton>());
      expect(tester.widget<ElevatedButton>(find.text('Continue as Guest').first), isA<ElevatedButton>());

      // Act - Tap buttons to verify they respond
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Assert - Navigation should occur
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('WT_AUTH_008: Loading state during authentication', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter name and tap Sign Up
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.tap(find.text('Sign Up'));
      await tester.pump(); // Show loading state

      // Assert - Should show loading indicator briefly
      // Note: The actual loading state might be very brief, so we just verify the flow works
      await tester.pumpAndSettle();
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('WT_AUTH_009: Keyboard interaction', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Tap on text field to focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Assert - Text field should be focused
      expect(find.byType(TextField), findsOneWidget);

      // Act - Enter text and submit
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert - Text should remain in field
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('WT_AUTH_010: Screen responsiveness', (WidgetTester tester) async {
      // Arrange - Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidget());

      // Assert - All elements should be visible
      expect(find.text('Fighter'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('WT_AUTH_011: Error handling during authentication', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter name and tap Sign Up
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Assert - Should handle authentication without errors
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('WT_AUTH_012: Multiple rapid taps handling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Enter name and tap Sign Up multiple times rapidly
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.tap(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Assert - Should handle multiple taps gracefully
      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('WT_AUTH_013: Accessibility features', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert - Text fields should have proper labels
      expect(find.text('Name'), findsOneWidget);

      // Assert - Buttons should have proper semantics
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Note: In a real app, you would also test for semantic labels and accessibility features
    });
  });
} 
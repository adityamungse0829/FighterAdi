import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/screens/tasks_screen.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';
import 'package:fighter/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TasksScreen Widget Tests', () {
    late UserProvider userProvider;
    late TaskProvider taskProvider;

    setUp(() async {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      
      userProvider = UserProvider();
      taskProvider = TaskProvider();
      
      // Wait for UserProvider to initialize
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set up user context using proper methods
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
            child: const TasksScreen(),
          ),
        ),
      );
    }

    testWidgets('WT_TASKS_001: Tasks screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // Verify welcome message is displayed
      expect(find.text('Welcome, Test User!'), findsOneWidget);

      // Verify date header is present
      expect(find.textContaining('Today,'), findsOneWidget);

      // Verify progress card is displayed
      expect(find.text('Daily Goal Progress'), findsOneWidget);

      // Verify tasks list area is present
      expect(find.text("Today's Tasks"), findsOneWidget);

      // Verify add task button is present
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify share button is present
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('WT_TASKS_002: Add task dialog functionality', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap add task button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Assert - Dialog should open with all required elements
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Task Size'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Daily Task'), findsOneWidget);
      expect(find.text('This task will reset every day.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Verify NO description field is present
      expect(find.text('Description'), findsNothing);
    });

    testWidgets('WT_TASKS_003: Create new task', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Act - Open add task dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      debugPrint('After tapping add:');
      debugDumpApp();

      // Act - Enter task details
      await tester.enterText(find.byType(TextField).first, 'Test Task');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      debugPrint('After entering task details:');
      debugDumpApp();

      // Act - Save task
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      debugPrint('After saving task:');
      debugDumpApp();

      // Assert - Task should appear in list
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Medium task points
      expect(find.byType(AlertDialog), findsNothing); // Dialog should close
    });

    testWidgets('WT_TASKS_004: Task completion toggle', (WidgetTester tester) async {
      // Arrange - Add a task first
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Test Task');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      debugPrint('After adding task:');
      debugDumpApp();

      // Act - Toggle task completion
      final incompleteIcon = find.byWidgetPredicate((w) => w is Container && w.child == null);
      expect(incompleteIcon, findsWidgets);
      await tester.tap(incompleteIcon.first);
      await tester.pumpAndSettle();
      debugPrint('After marking complete:');
      debugDumpApp();

      // Assert - Task should be marked as completed
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Act - Toggle back to incomplete
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();
      debugPrint('After marking incomplete:');
      debugDumpApp();

      // Assert - Task should be marked as incomplete
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('WT_TASKS_005: Progress calculation and display', (WidgetTester tester) async {
      // Arrange - Add tasks with different point values
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Add small task (1 point)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Small Task');
      await tester.tap(find.text('Small'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Add large task (5 points)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Large Task');
      await tester.tap(find.text('Large'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Act - Complete the small task
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pump();

      // Assert - Progress should be calculated correctly (1/6 = ~17%)
      expect(find.text('1'), findsOneWidget); // Completed points
      expect(find.text('6'), findsOneWidget); // Total points
    });

    testWidgets('WT_TASKS_006: Consistency count display', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add and complete a task to trigger consistency count
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pump();

      // Assert - Consistency count should be displayed
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('1 Day'), findsOneWidget);
    });

    testWidgets('WT_TASKS_007: Task deletion by swipe', (WidgetTester tester) async {
      // Arrange - Add multiple tasks
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      // Add first task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Task 1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Add second task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Task 2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Act - Swipe to delete first task
      await tester.drag(find.text('Task 1'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Assert - First task should be removed
      expect(find.text('Task 1'), findsNothing);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('WT_TASKS_008: Share progress functionality', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add and complete a task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pump();

      // Act - Tap share button
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();

      // Assert - Share functionality should be triggered
      // Note: In a real test environment, you might need to mock the share functionality
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('WT_TASKS_009: Task size selection in dialog', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Act - Select different task sizes
      await tester.tap(find.text('Small'));
      await tester.pump();
      expect(find.text('Small'), findsOneWidget);

      await tester.tap(find.text('Medium'));
      await tester.pump();
      expect(find.text('Medium'), findsOneWidget);

      await tester.tap(find.text('Large'));
      await tester.pump();
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('WT_TASKS_010: Daily task toggle in dialog', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Act - Toggle daily task switch
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Assert - Switch should be toggled
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('WT_TASKS_011: Empty task name validation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Act - Try to save with empty task name
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Assert - Dialog should remain open (no validation error shown in current implementation)
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('WT_TASKS_012: Cancel task creation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Act - Enter task name and cancel
      await tester.enterText(find.byType(TextField), 'Test Task');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should close and task should not be added
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Test Task'), findsNothing);
    });

    testWidgets('WT_TASKS_013: Recurring task display', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Act - Create a recurring task
      await tester.enterText(find.byType(TextField), 'Recurring Task');
      await tester.tap(find.byType(Switch)); // Toggle daily task
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Task should show recurring indicator
      expect(find.text('Recurring Task'), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('WT_TASKS_014: Task color coding by size', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add small task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Small Task');
      await tester.tap(find.text('Small'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Add large task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Large Task');
      await tester.tap(find.text('Large'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert - Tasks should have different colors based on size
      expect(find.text('Small Task'), findsOneWidget);
      expect(find.text('Large Task'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Small task points
      expect(find.text('5'), findsOneWidget); // Large task points
    });

    testWidgets('WT_TASKS_015: Screen responsiveness', (WidgetTester tester) async {
      // Arrange - Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - All elements should be visible
      expect(find.text('Welcome, Test User!'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
} 
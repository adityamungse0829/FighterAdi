import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/screens/calendar_screen.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';
import 'package:fighter/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CalendarScreen Widget Tests', () {
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
            child: const CalendarScreen(),
          ),
        ),
      );
    }

    testWidgets('WT_CAL_001: Calendar screen displays correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Assert
      // Verify month/year header is displayed
      expect(find.textContaining('2024'), findsOneWidget); // Current year
      expect(find.textContaining('January'), findsOneWidget); // Current month

      // Verify navigation arrows are present
      expect(find.byIcon(Icons.chevron_left), findsOneWidget); // Previous month
      expect(find.byIcon(Icons.chevron_right), findsOneWidget); // Next month

      // Verify calendar grid is displayed
      expect(find.byType(Table), findsOneWidget); // Calendar grid

      // Verify today's date is highlighted
      final today = DateTime.now();
      final todayText = today.day.toString();
      expect(find.text(todayText), findsOneWidget);
    });

    testWidgets('WT_CAL_002: Calendar navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Note current month
      final initialMonth = find.textContaining('January');
      expect(initialMonth, findsOneWidget);

      // Act - Navigate to next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      debugPrint('After next month:');
      debugDumpApp();

      // Assert - Month should change
      expect(find.textContaining('February'), findsOneWidget);

      // Act - Navigate to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      debugPrint('After previous month:');
      debugDumpApp();

      // Assert - Month should change back
      expect(find.textContaining('January'), findsOneWidget);
    });

    testWidgets('WT_CAL_003: Day color coding', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Create tasks for specific dates
      final today = DateTime.now();
      final task1 = Task(
        id: 'task1',
        title: 'Task 1',
        dueDate: today,
        points: 3,
        size: 'medium',
        isRecurring: false,
      );
      final task2 = Task(
        id: 'task2',
        title: 'Task 2',
        dueDate: today.add(const Duration(days: 1)),
        points: 5,
        size: 'large',
        isRecurring: false,
      );

      // Add tasks to provider
      taskProvider.addTask(task1);
      taskProvider.addTask(task2);
      await tester.pumpAndSettle();
      debugPrint('After adding tasks:');
      debugDumpApp();

      // Complete some tasks
      taskProvider.toggleTask(0); // Complete first task
      await tester.pumpAndSettle();
      debugPrint('After completing task:');
      debugDumpApp();

      // Assert - Days with tasks should be colored
      // Note: The actual color coding implementation would need to be verified
      // based on how the CalendarScreen displays task completion
      expect(find.text('1'), findsOneWidget); // Today's date
      expect(find.text('2'), findsOneWidget); // Tomorrow's date

      // Verify color intensity matches completion percentage
      // This would depend on the specific implementation of color coding
      // in the CalendarScreen
    });

    testWidgets('WT_CAL_004: Day tap functionality', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Create tasks for a specific date
      final today = DateTime.now();
      final task1 = Task(
        id: 'task1',
        title: 'Task 1',
        dueDate: today,
        points: 3,
        size: 'medium',
        isRecurring: false,
      );
      final task2 = Task(
        id: 'task2',
        title: 'Task 2',
        dueDate: today,
        points: 5,
        size: 'large',
        isRecurring: false,
      );

      // Add tasks to provider
      taskProvider.addTask(task1);
      taskProvider.addTask(task2);
      await tester.pumpAndSettle();
      debugPrint('After adding tasks:');
      debugDumpApp();

      // Act - Tap on a day with tasks
      final todayText = today.day.toString();
      await tester.tap(find.text(todayText));
      await tester.pumpAndSettle();
      debugPrint('After tapping day:');
      debugDumpApp();

      // Assert - Task details dialog should appear
      // Note: The actual implementation would depend on how the CalendarScreen
      // handles day taps and displays task details
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('WT_CAL_005: Empty calendar display', (WidgetTester tester) async {
      // Arrange - Calendar with no tasks
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Assert - Calendar should display correctly even with no tasks
      expect(find.byType(Table), findsOneWidget); // Calendar grid
      expect(find.byIcon(Icons.chevron_left), findsOneWidget); // Navigation
      expect(find.byIcon(Icons.chevron_right), findsOneWidget); // Navigation
    });

    testWidgets('WT_CAL_006: Month boundary navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Navigate to December
      for (int i = 0; i < 11; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
      }
      debugPrint('After navigating to December:');
      debugDumpApp();

      // Assert - Should be in December
      expect(find.textContaining('December'), findsOneWidget);

      // Navigate to January of next year
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      debugPrint('After navigating to next year:');
      debugDumpApp();

      // Assert - Should be in January of next year
      expect(find.textContaining('January'), findsOneWidget);
      expect(find.textContaining('2025'), findsOneWidget);
    });

    testWidgets('WT_CAL_007: Recurring tasks display', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Create a recurring task
      final today = DateTime.now();
      final recurringTask = Task(
        id: 'recurring_task',
        title: 'Daily Task',
        dueDate: today,
        points: 1,
        size: 'small',
        isRecurring: true,
      );

      // Add recurring task to provider
      taskProvider.addTask(recurringTask);
      await tester.pumpAndSettle();
      debugPrint('After adding recurring task:');
      debugDumpApp();

      // Assert - Recurring task should be displayed
      // Note: The actual implementation would depend on how recurring tasks
      // are displayed in the calendar
      expect(find.text('Daily Task'), findsOneWidget);
    });

    testWidgets('WT_CAL_008: Task completion status in calendar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Create tasks for today
      final today = DateTime.now();
      final task1 = Task(
        id: 'task1',
        title: 'Completed Task',
        dueDate: today,
        points: 3,
        size: 'medium',
        isRecurring: false,
      );
      final task2 = Task(
        id: 'task2',
        title: 'Pending Task',
        dueDate: today,
        points: 5,
        size: 'large',
        isRecurring: false,
      );

      // Add tasks to provider
      taskProvider.addTask(task1);
      taskProvider.addTask(task2);
      await tester.pumpAndSettle();
      debugPrint('After adding tasks:');
      debugDumpApp();

      // Complete one task
      taskProvider.toggleTask(0);
      await tester.pumpAndSettle();
      debugPrint('After completing task:');
      debugDumpApp();

      // Tap on today to see task details
      final todayText = today.day.toString();
      await tester.tap(find.text(todayText));
      await tester.pumpAndSettle();
      debugPrint('After tapping today:');
      debugDumpApp();

      // Assert - Both tasks should be visible with completion status
      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.text('Pending Task'), findsOneWidget);
    });

    testWidgets('WT_CAL_009: Calendar accessibility', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Assert - Calendar should be accessible
      expect(find.byType(Table), findsOneWidget); // Calendar grid
      expect(find.byIcon(Icons.chevron_left), findsOneWidget); // Navigation
      expect(find.byIcon(Icons.chevron_right), findsOneWidget); // Navigation

      // Verify navigation buttons are tappable
      expect(tester.getSemantics(find.byIcon(Icons.chevron_left)), isNotNull);
      expect(tester.getSemantics(find.byIcon(Icons.chevron_right)), isNotNull);
    });

    testWidgets('WT_CAL_010: Calendar performance', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();

      // Create many tasks across different dates
      final today = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final task = Task(
          id: 'task_$i',
          title: 'Task $i',
          dueDate: today.add(Duration(days: i)),
          points: (i % 3) + 1, // 1, 2, or 3 points
          size: ['small', 'medium', 'large'][i % 3],
          isRecurring: i % 5 == 0, // Every 5th task is recurring
        );
        taskProvider.addTask(task);
      }
      await tester.pumpAndSettle();
      debugPrint('After adding many tasks:');
      debugDumpApp();

      // Navigate through months
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
      }
      debugPrint('After navigating through months:');
      debugDumpApp();

      // Assert - Calendar should still be responsive
      expect(find.byType(Table), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });
} 
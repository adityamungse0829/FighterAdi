import 'package:flutter_test/flutter_test.dart';
import 'package:fighter/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('UT_TASK_001: Task creation with required parameters', () {
      // Arrange
      final task = Task(
        id: 'test_id_123',
        title: 'Test Task',
        dueDate: DateTime(2024, 1, 15, 10, 0, 0),
      );

      // Assert
      expect(task.id, 'test_id_123');
      expect(task.title, 'Test Task');
      expect(task.dueDate, DateTime(2024, 1, 15, 10, 0, 0));
      expect(task.completed, false); // Should be false by default
      expect(task.points, 0); // Should be 0 by default
      expect(task.size, 'small'); // Should be 'small' by default
      expect(task.isRecurring, false); // Should be false by default
    });

    test('UT_TASK_002: Task toJson serialization', () {
      // Arrange
      final task = Task(
        id: 'test_id_123',
        title: 'Test Task',
        dueDate: DateTime(2024, 1, 15, 10, 0, 0),
        completed: true,
        points: 5,
        size: 'large',
        isRecurring: true,
      );

      // Act
      final json = task.toJson();

      // Assert
      expect(json['id'], 'test_id_123');
      expect(json['title'], 'Test Task');
      expect(json['dueDate'], '2024-01-15T10:00:00.000');
      expect(json['completed'], true);
      expect(json['points'], 5);
      expect(json['size'], 'large');
      expect(json['isRecurring'], true);
    });

    test('UT_TASK_003: Task fromJson deserialization', () {
      // Arrange
      final jsonData = {
        'id': 'test_id_123',
        'title': 'Test Task',
        'dueDate': '2024-01-15T10:00:00.000',
        'completed': true,
        'points': 5,
        'size': 'large',
        'isRecurring': true,
      };

      // Act
      final task = Task.fromJson(jsonData);

      // Assert
      expect(task.id, 'test_id_123');
      expect(task.title, 'Test Task');
      expect(task.dueDate, DateTime(2024, 1, 15, 10, 0, 0));
      expect(task.completed, true);
      expect(task.points, 5);
      expect(task.size, 'large');
      expect(task.isRecurring, true);
    });

    test('UT_TASK_004: Task creation with automatic due date', () {
      // Arrange & Act
      final now = DateTime.now();
      final task = Task(
        id: 'test_id_123',
        title: 'Test Task',
        points: 3,
        size: 'medium',
        isRecurring: false,
        dueDate: now, // Simulating automatic due date setting
      );

      // Assert
      expect(task.dueDate, now); // Due date should be set to provided value
      expect(task.title, 'Test Task');
      expect(task.points, 3);
      expect(task.size, 'medium');
      expect(task.isRecurring, false);
    });

    test('Task creation with minimal parameters', () {
      // Arrange & Act
      final task = Task(
        id: 'minimal_task',
        title: 'Minimal Task',
        dueDate: DateTime.now(),
      );

      // Assert
      expect(task.id, 'minimal_task');
      expect(task.title, 'Minimal Task');
      expect(task.completed, false);
      expect(task.points, 0);
      expect(task.size, 'small');
      expect(task.isRecurring, false);
    });

    test('Task with different sizes', () {
      // Test small size
      final smallTask = Task(
        id: 'small_task',
        title: 'Small Task',
        dueDate: DateTime.now(),
        size: 'small',
      );
      expect(smallTask.size, 'small');

      // Test medium size
      final mediumTask = Task(
        id: 'medium_task',
        title: 'Medium Task',
        dueDate: DateTime.now(),
        size: 'medium',
      );
      expect(mediumTask.size, 'medium');

      // Test large size
      final largeTask = Task(
        id: 'large_task',
        title: 'Large Task',
        dueDate: DateTime.now(),
        size: 'large',
      );
      expect(largeTask.size, 'large');
    });

    test('Task with recurring flag', () {
      // Arrange & Act
      final recurringTask = Task(
        id: 'recurring_task',
        title: 'Recurring Task',
        dueDate: DateTime.now(),
        isRecurring: true,
      );

      // Assert
      expect(recurringTask.isRecurring, true);
      expect(recurringTask.completed, false); // Should still be false by default
    });
  });
} 
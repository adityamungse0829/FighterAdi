import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String? _currentUserContext;
  int _consistencyCount = 0;
  String? _lastConsistencyUpdate;
  bool _isInitialized = false;

  List<Task> get tasks => List.unmodifiable(getVisibleTasks());
  int get consistencyCount => _consistencyCount;
  bool get isInitialized => _isInitialized;

  // Get all tasks including archived ones (for history and reports)
  List<Task> get allTasks => List.unmodifiable(_tasks);
  
  // Get archived tasks (for history)
  List<Task> get archivedTasks => List.unmodifiable(_tasks.where((task) => task.archived));

  TaskProvider() {
    // Don't load tasks in constructor
  }

  void setUserContext(String? userName) async {
    _currentUserContext = userName;
    await _initializeStorage();
  }

  String get _storageKey => 'tasks_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';
  String get _consistencyCountKey => 'consistency_count_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';
  String get _lastConsistencyUpdateKey => 'last_consistency_update_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';

  Future<void> _initializeStorage() async {
    if (_currentUserContext == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load consistency count
      _consistencyCount = prefs.getInt(_consistencyCountKey) ?? 0;
      _lastConsistencyUpdate = prefs.getString(_lastConsistencyUpdateKey);

      // Load tasks from storage
      final tasksJson = prefs.getString(_storageKey);
      if (tasksJson != null) {
        try {
          final List<dynamic> decodedData = jsonDecode(tasksJson);
          _tasks = decodedData.map((item) => Task.fromJson(item)).toList();
          print('✅ Loaded ${_tasks.length} tasks for user: $_currentUserContext');
        } catch (e) {
          print('❌ Error loading tasks: $e');
          _tasks = [];
        }
      } else {
        _tasks = [];
        print('📝 No tasks found for user: $_currentUserContext');
      }

      // Check if we need to reset recurring tasks (only at midnight)
      await _checkAndResetRecurringTasks();
      
      _isInitialized = true;
      notifyListeners();
      
    } catch (e) {
      print('❌ Error initializing storage: $e');
      _tasks = [];
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _checkAndResetRecurringTasks() async {
    if (_currentUserContext == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String lastOpenedKey = 'last_opened_${_currentUserContext!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final String? lastOpenedDateString = prefs.getString(lastOpenedKey);
      
      final DateTime now = DateTime.now();
      final String todayString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      print('📅 Last opened: $lastOpenedDateString, Today: $todayString');
      
      // Only reset if it's actually a new day
      if (lastOpenedDateString != todayString) {
        print('🔄 New day detected, processing tasks at midnight');
        
        // Reset completion status of recurring tasks (keep original due date)
        int resetCount = 0;
        for (var task in _tasks) {
          if (task.isRecurring) {
            task.completed = false;
            task.completionDate = null; // Clear completion date
            // DON'T change dueDate - keep it as the original creation date
            // This ensures daily tasks remain clickable and properly categorized
            resetCount++;
            print('🔄 Reset daily task: ${task.title} - Kept original due date: ${task.dueDate}');
          }
        }
        print('🔄 Reset $resetCount recurring tasks');
        
        // Archive non-daily tasks (remove from main list but preserve for history)
        int archivedCount = 0;
        for (var task in _tasks) {
          if (!task.isRecurring) {
            task.archived = true; // Mark as archived
            archivedCount++;
            print('📦 Archived non-daily task: ${task.title} (preserved for history)');
          }
        }
        print('📦 Archived $archivedCount non-daily tasks (preserved for history)');
        
        // Update the last opened date
        await prefs.setString(lastOpenedKey, todayString);
        
        // Save the updated tasks
        await _saveTasksInternal();
      } else {
        print('✅ Same day, no need to process tasks');
      }
    } catch (e) {
      print('❌ Error processing tasks: $e');
    }
  }

  Future<void> _saveTasksInternal() async {
    if (_currentUserContext == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
      
      // Also save a backup
      final String backupKey = '${_storageKey}_backup_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(backupKey, jsonString);
      
      print('💾 Saved ${_tasks.length} tasks for user: $_currentUserContext');
      
      // Clean up old backups (keep only last 3)
      final keys = prefs.getKeys();
      final backupKeys = keys.where((key) => key.startsWith('${_storageKey}_backup_')).toList();
      if (backupKeys.length > 3) {
        backupKeys.sort();
        for (int i = 0; i < backupKeys.length - 3; i++) {
          await prefs.remove(backupKeys[i]);
        }
      }
    } catch (e) {
      print('❌ Error saving tasks: $e');
    }
  }

  // Public method to save tasks
  Future<void> saveTasks() async {
    await _saveTasksInternal();
  }

  // Force save tasks - useful for app lifecycle events
  Future<void> forceSaveTasks() async {
    print('🚀 Force saving tasks...');
    await _saveTasksInternal();
  }

  Future<void> _saveConsistencyData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_consistencyCountKey, _consistencyCount);
    if (_lastConsistencyUpdate != null) {
      await prefs.setString(_lastConsistencyUpdateKey, _lastConsistencyUpdate!);
    }
  }

  void addTask(Task task) {
    _tasks.add(task);
    print('➕ Added task: ${task.title}');
    _saveTasksInternal(); // Save immediately
    notifyListeners();
  }

  void updateTask(int index, Task task) {
    _tasks[index] = task;
    print('✏️ Updated task: ${task.title}');
    _saveTasksInternal(); // Save immediately
    notifyListeners();
  }

  void removeTask(int index) {
    // Get the visible tasks (what the UI is actually showing)
    final visibleTasks = getVisibleTasks();
    
    // Check if index is valid
    if (index < 0 || index >= visibleTasks.length) {
      print('❌ Invalid index for removal: $index (visible tasks: ${visibleTasks.length})');
      return;
    }
    
    // Get the task to remove from visible list
    final taskToRemove = visibleTasks[index];
    final taskTitle = taskToRemove.title;
    
    // Find the actual index in the main _tasks list
    final actualIndex = _tasks.indexWhere((task) => task.id == taskToRemove.id);
    
    if (actualIndex != -1) {
      _tasks.removeAt(actualIndex);
      print('🗑️ Removed task: $taskTitle (ID: ${taskToRemove.id})');
      _saveTasksInternal(); // Save immediately
      notifyListeners();
    } else {
      print('❌ Task not found in main list: $taskTitle');
    }
  }

  void toggleTask(int index) async {
    _tasks[index].completed = !_tasks[index].completed;
    final status = _tasks[index].completed ? 'completed' : 'uncompleted';
    print('🔄 Toggled task: ${_tasks[index].title} -> $status');
    
    // Set or clear completion date
    if (_tasks[index].completed) {
      _tasks[index].completionDate = DateTime.now();
      print('📅 Set completion date: ${_tasks[index].completionDate}');
    } else {
      _tasks[index].completionDate = null;
      print('📅 Cleared completion date');
    }
    
    // Notify listeners immediately for instant UI update
    notifyListeners();

    // Update consistency count
    if (_tasks[index].completed) {
      final DateTime now = DateTime.now();
      final String todayString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (_lastConsistencyUpdate != todayString) {
        if (_lastConsistencyUpdate != null) {
          final lastUpdateDate = DateTime.parse(_lastConsistencyUpdate!);
          if (now.difference(lastUpdateDate).inDays == 1) {
            _consistencyCount++;
          } else {
            _consistencyCount = 1;
          }
        } else {
          _consistencyCount = 1;
        }
        _lastConsistencyUpdate = todayString;
        await _saveConsistencyData();
      }
    }
    
    // Save tasks after all processing is done
    await _saveTasksInternal();
  }

  void clearAllTasks() async {
    _tasks.clear();
    print('🧹 Cleared all tasks');
    if (_currentUserContext != null) {
      await _saveTasksInternal();
    }
    notifyListeners();
  }

  void setTasks(List<Task> newTasks) {
    _tasks = newTasks;
    print('📋 Set ${newTasks.length} tasks');
    _saveTasksInternal(); // Save immediately
    notifyListeners();
  }

  // Section-based progress calculation methods
  Map<String, double> getSectionProgress() {
    final sections = ['Physical', 'Mental', 'Financial', 'Emotional'];
    final Map<String, double> sectionProgress = {};
    
    for (String section in sections) {
      final sectionTasks = _tasks.where((task) => task.section == section).toList();
      if (sectionTasks.isEmpty) {
        sectionProgress[section] = 0.0;
      } else {
        final completedTasks = sectionTasks.where((task) => task.completed).length;
        sectionProgress[section] = (completedTasks / sectionTasks.length) * 100;
      }
    }
    
    return sectionProgress;
  }

  Map<String, int> getSectionTaskCounts() {
    final sections = ['Physical', 'Mental', 'Financial', 'Emotional'];
    final Map<String, int> sectionCounts = {};
    
    for (String section in sections) {
      final sectionTasks = _tasks.where((task) => task.section == section).toList();
      sectionCounts[section] = sectionTasks.length;
    }
    
    return sectionCounts;
  }

  Map<String, int> getSectionCompletedCounts() {
    final sections = ['Physical', 'Mental', 'Financial', 'Emotional'];
    final Map<String, int> sectionCompletedCounts = {};
    
    for (String section in sections) {
      final sectionTasks = _tasks.where((task) => task.section == section).toList();
      final completedTasks = sectionTasks.where((task) => task.completed).length;
      sectionCompletedCounts[section] = completedTasks;
    }
    
    return sectionCompletedCounts;
  }

  double getOverallProgress() {
    if (_tasks.isEmpty) return 0.0;
    final completedTasks = _tasks.where((task) => task.completed).length;
    return (completedTasks / _tasks.length) * 100;
  }

  List<String> getSections() {
    return ['Physical', 'Mental', 'Financial', 'Emotional'];
  }

  // Get tasks for a specific date (completed tasks by completion date, pending tasks by due date)
  List<Task> getTasksForDate(DateTime date) {
    return allTasks.where((task) {
      // For completed tasks, use completion date
      if (task.completed && task.completionDate != null) {
        return task.completionDate!.year == date.year && 
               task.completionDate!.month == date.month && 
               task.completionDate!.day == date.day;
      }
      // For pending tasks, use due date
      // Also include daily tasks that were created on or before this date
      if (task.isRecurring) {
        // Daily tasks: show if created on or before this date
        return task.dueDate.year <= date.year && 
               (task.dueDate.year < date.year || task.dueDate.month <= date.month) &&
               (task.dueDate.year < date.year || task.dueDate.month < date.month || task.dueDate.day <= date.day);
      } else {
        // Non-daily tasks: show if due on this exact date
        return task.dueDate.year == date.year && 
               task.dueDate.month == date.month && 
               task.dueDate.day == date.day;
      }
    }).toList();
  }

  // Get completed tasks for a specific date
  List<Task> getCompletedTasksForDate(DateTime date) {
    return allTasks.where((task) {
      return task.completed && 
             task.completionDate != null &&
             task.completionDate!.year == date.year && 
             task.completionDate!.month == date.month && 
             task.completionDate!.day == date.day;
    }).toList();
  }

  // Get pending tasks for a specific date
  List<Task> getPendingTasksForDate(DateTime date) {
    return allTasks.where((task) {
      if (!task.completed) {
        if (task.isRecurring) {
          // Daily tasks: show if created on or before this date
          return task.dueDate.year <= date.year && 
                 (task.dueDate.year < date.year || task.dueDate.month <= date.month) &&
                 (task.dueDate.year < date.year || task.dueDate.month < date.month || task.dueDate.day <= date.day);
        } else {
          // Non-daily tasks: show if due on this exact date
          return task.dueDate.year == date.year && 
                 task.dueDate.month == date.month && 
                 task.dueDate.day == date.day;
        }
      }
      return false;
    }).toList();
  }

  // Get all completed tasks (historical data)
  List<Task> getAllCompletedTasks() {
    return allTasks.where((task) => task.completed).toList();
  }

  // Get tasks that should be visible on the main task list
  // This includes: non-archived tasks + daily tasks (which should never be archived)
  List<Task> getVisibleTasks() {
    return allTasks.where((task) {
      // Show non-archived tasks
      if (!task.archived) return true;
      
      // Daily tasks should NEVER be archived, but just in case, show them anyway
      if (task.isRecurring) {
        print('⚠️ Daily task ${task.title} was archived - this shouldn\'t happen!');
        return true;
      }
      
      return false;
    }).toList();
  }

  // Get tasks for a date range (useful for historical reports)
  List<Task> getTasksForDateRange(DateTime startDate, DateTime endDate) {
    return allTasks.where((task) {
      DateTime taskDate;
      
      // For completed tasks, use completion date
      if (task.completed && task.completionDate != null) {
        taskDate = task.completionDate!;
      } else {
        // For pending tasks, use due date
        taskDate = task.dueDate;
      }
      
      return taskDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
             taskDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get historical progress for a specific date range
  Map<String, dynamic> getHistoricalProgress(DateTime startDate, DateTime endDate) {
    final tasksInRange = getTasksForDateRange(startDate, endDate);
    final completedTasks = tasksInRange.where((task) => task.completed).toList();
    final pendingTasks = tasksInRange.where((task) => !task.completed).toList();
    
    final totalPoints = tasksInRange.fold(0, (sum, task) => sum + task.points);
    final completedPoints = completedTasks.fold(0, (sum, task) => sum + task.points);
    
    return {
      'totalTasks': tasksInRange.length,
      'completedTasks': completedTasks.length,
      'pendingTasks': pendingTasks.length,
      'totalPoints': totalPoints,
      'completedPoints': completedPoints,
      'progressPercentage': totalPoints > 0 ? (completedPoints / totalPoints) * 100 : 0.0,
      'tasks': tasksInRange,
    };
  }

  // Get complete task history (all tasks ever created)
  List<Task> getCompleteTaskHistory() {
    return allTasks;
  }

  // Get task statistics
  Map<String, dynamic> getTaskStatistics() {
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((task) => task.completed).length;
    final pendingTasks = allTasks.where((task) => !task.completed).length;
    final dailyTasks = allTasks.where((task) => task.isRecurring).length;
    final nonDailyTasks = allTasks.where((task) => !task.isRecurring).length;
    
    final totalPoints = allTasks.fold(0, (sum, task) => sum + task.points);
    final completedPoints = allTasks.fold(0, (sum, task) => sum + (task.completed ? task.points : 0));
    
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
      'dailyTasks': dailyTasks,
      'nonDailyTasks': nonDailyTasks,
      'totalPoints': totalPoints,
      'completedPoints': completedPoints,
      'overallProgress': totalPoints > 0 ? (completedPoints / totalPoints) * 100 : 0.0,
    };
  }
}  
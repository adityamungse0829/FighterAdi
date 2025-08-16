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

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get consistencyCount => _consistencyCount;
  bool get isInitialized => _isInitialized;

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
        print('🔄 New day detected, resetting recurring tasks');
        int resetCount = 0;
        
        for (var task in _tasks) {
          if (task.isRecurring) {
            task.completed = false;
            resetCount++;
          }
        }
        
        print('🔄 Reset $resetCount recurring tasks');
        
        // Update the last opened date
        await prefs.setString(lastOpenedKey, todayString);
        
        // Save the updated tasks
        await _saveTasksInternal();
      } else {
        print('✅ Same day, no need to reset tasks');
      }
    } catch (e) {
      print('❌ Error checking recurring tasks: $e');
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
    final taskTitle = _tasks[index].title;
    _tasks.removeAt(index);
    print('🗑️ Removed task: $taskTitle');
    _saveTasksInternal(); // Save immediately
    notifyListeners();
  }

  void toggleTask(int index) async {
    _tasks[index].completed = !_tasks[index].completed;
    final status = _tasks[index].completed ? 'completed' : 'uncompleted';
    print('🔄 Toggled task: ${_tasks[index].title} -> $status');
    
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
}  
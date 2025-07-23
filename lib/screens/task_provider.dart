import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String? _currentUserContext;
  int _consistencyCount = 0;
  String? _lastConsistencyUpdate;

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get consistencyCount => _consistencyCount;

  TaskProvider() {
    // Will be initialized when user context is set
  }

  void setUserContext(String? userName) {
    _currentUserContext = userName;
    loadTasks();
  }

  String get _storageKey => 'tasks_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';
  String get _consistencyCountKey => 'consistency_count_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';
  String get _lastConsistencyUpdateKey => 'last_consistency_update_${_currentUserContext?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'guest'}';

  Future<void> loadTasks() async {
    if (_currentUserContext == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Load consistency count
    _consistencyCount = prefs.getInt(_consistencyCountKey) ?? 0;
    _lastConsistencyUpdate = prefs.getString(_lastConsistencyUpdateKey);

    // Get today's date and the last opened date
    final String lastOpenedKey = 'last_opened_${_currentUserContext!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final String? lastOpenedDateString = prefs.getString(lastOpenedKey);
    final DateTime now = DateTime.now();
    final String todayString = "${now.year}-${now.month}-${now.day}";

    // Check for broken streak
    if (_lastConsistencyUpdate != null) {
      final lastUpdateDate = DateTime.parse(_lastConsistencyUpdate!);
      if (now.difference(lastUpdateDate).inDays > 1) {
        _consistencyCount = 0;
        await prefs.setInt(_consistencyCountKey, _consistencyCount);
      }
    }

    // Load tasks from storage
    final tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decodedData = jsonDecode(tasksJson);
      _tasks = decodedData.map((item) => Task.fromJson(item)).toList();

      // If it's a new day, reset the completion status of recurring tasks only
      if (lastOpenedDateString != todayString) {
        for (var task in _tasks) {
          if (task.isRecurring) {
            task.completed = false;
          }
        }
        // After processing, save the updated list of tasks
        await saveTasks();
      }
    } else {
      _tasks = [];
    }

    // Update the last opened date to today
    await prefs.setString(lastOpenedKey, todayString);

    notifyListeners();
  }

  Future<void> saveTasks() async {
    if (_currentUserContext == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
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
    saveTasks();
    notifyListeners();
  }

  void updateTask(int index, Task task) {
    _tasks[index] = task;
    saveTasks();
    notifyListeners();
  }

  void removeTask(int index) {
    _tasks.removeAt(index);
    saveTasks();
    notifyListeners();
  }

  void toggleTask(int index) async {
    _tasks[index].completed = !_tasks[index].completed;

    if (_tasks[index].completed) {
      final DateTime now = DateTime.now();
      final String todayString = "${now.year}-${now.month}-${now.day}";

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
    
    saveTasks();
    notifyListeners();
  }

  void clearAllTasks() async {
    _tasks.clear();
    if (_currentUserContext != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    }
    notifyListeners();
  }

  void setTasks(List<Task> newTasks) {
    _tasks = newTasks;
    saveTasks();
    notifyListeners();
  }
}  
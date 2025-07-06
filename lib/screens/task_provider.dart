import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String? _currentUserContext;

  List<Task> get tasks => List.unmodifiable(_tasks);

  TaskProvider() {
    // Will be initialized when user context is set
  }

  void setUserContext(String? userName) {
    _currentUserContext = userName;
    loadTasks();
  }

  String get _storageKey {
    if (_currentUserContext == null) {
      return 'tasks_guest';
    }
    return 'tasks_${_currentUserContext!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
  }

  Future<void> loadTasks() async {
    if (_currentUserContext == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Get today's date and the last opened date
    final String lastOpenedKey = 'last_opened_${_currentUserContext!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final String? lastOpenedDateString = prefs.getString(lastOpenedKey);
    final DateTime now = DateTime.now();
    final String todayString = "${now.year}-${now.month}-${now.day}";

    // Load tasks from storage
    final tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decodedData = jsonDecode(tasksJson);
      _tasks = decodedData.map((item) => Task.fromJson(item)).toList();

      // If it's a new day, reset the completion status of all tasks
      if (lastOpenedDateString != todayString) {
        // Create a new list to hold the tasks for the new day
        List<Task> tasksForNewDay = [];

        for (var task in _tasks) {
          if (task.isRecurring) {
            // If the task is recurring, reset its completion status
            task.completed = false;
            tasksForNewDay.add(task);
          } else if (!task.completed) {
            // If the task is a one-time task and not completed, carry it over
            tasksForNewDay.add(task);
          }
          // Completed one-time tasks are automatically removed by not adding them
        }
        
        _tasks = tasksForNewDay;
        
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

  void toggleTask(int index) {
    _tasks[index].completed = !_tasks[index].completed;
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
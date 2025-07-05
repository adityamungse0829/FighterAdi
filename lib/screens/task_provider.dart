import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    _tasks = tasksJson.map((e) => _decodeTask(e)).toList();
    notifyListeners();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((e) => _encodeTask(e)).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void addTask(Map<String, dynamic> task) {
    _tasks.add(task);
    saveTasks();
    notifyListeners();
  }

  void updateTask(int index, Map<String, dynamic> task) {
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
    _tasks[index]['completed'] = !(_tasks[index]['completed'] as bool);
    saveTasks();
    notifyListeners();
  }

  void clearAllTasks() async {
    _tasks.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks');
    notifyListeners();
  }

  Map<String, dynamic> _decodeTask(String s) {
    final map = Map<String, dynamic>.from(Uri.splitQueryString(s));
    map['points'] = int.tryParse(map['points'] ?? '0') ?? 0;
    map['completed'] = map['completed'] == 'true';
    if (map['date'] != null) {
      map['date'] = map['date'];
    }
    return map;
  }

  String _encodeTask(Map<String, dynamic> t) => t.map((k, v) => MapEntry(k, v.toString())).entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
} 
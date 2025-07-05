import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    _tasks = tasksJson.map((e) => _decodeTaskForPrefs(e)).toList();
    notifyListeners();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((e) => _encodeTaskForPrefs(e)).toList();
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

  Map<String, dynamic> _decodeTaskForPrefs(String s) {
    final map = Map<String, dynamic>.from(Uri.splitQueryString(s));
    map['points'] = int.tryParse(map['points'] ?? '0') ?? 0;
    map['completed'] = map['completed'] == 'true';
    return map;
  }

  String _encodeTaskForPrefs(Map<String, dynamic> t) => t.map((k, v) => MapEntry(k, v.toString())).entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');

  // Methods for file backup/restore
  List<Map<String, dynamic>> decodeTasksFromFile(String jsonString) {
    final List<dynamic> decodedList = jsonDecode(jsonString);
    return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  String encodeTasksToFile(List<Map<String, dynamic>> tasks) {
    return jsonEncode(tasks);
  }
} 
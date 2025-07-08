import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

class UserProvider extends ChangeNotifier {
  String? _userName;
  bool _isGuest = false;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  String? get userName => _userName;
  bool get isGuest => _isGuest;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isInitialized && (_userName != null || _isGuest);
  Future<void> get initializationFuture => _initCompleter.future;

  UserProvider({SharedPreferences? prefs}) {
    _loadUserData(prefs);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName');
    _isGuest = prefs.getBool('isGuest') ?? false;
    _isInitialized = true;
    _initCompleter.complete();
    notifyListeners();
  }

  Future<void> setNamedUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setBool('isGuest', false);
    
    _userName = name;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> setGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.setBool('isGuest', true);
    
    _userName = null;
    _isGuest = true;
    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('isGuest');
    
    _userName = null;
    _isGuest = false;
    // Keep _isInitialized as true so the app can show the auth screen
    notifyListeners();
  }

  String get displayName {
    if (_isGuest) return 'Guest';
    return _userName ?? 'User';
  }

  String get welcomeMessage {
    if (_isGuest) return 'Welcome, Guest!';
    return 'Welcome, $_userName!';
  }
} 
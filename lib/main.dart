import 'package:flutter/material.dart';
import 'screens/launcher_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/floating_nav.dart';

void main() {
  runApp(const FighterApp());
}

class FighterApp extends StatefulWidget {
  const FighterApp({Key? key}) : super(key: key);

  @override
  State<FighterApp> createState() => _FighterAppState();
}

class _FighterAppState extends State<FighterApp> {
  String _theme = 'default';

  ThemeData get _currentTheme {
    switch (_theme) {
      case 'dark':
        return ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: const Color(0xFF111827),
          fontFamily: 'SF Pro Display',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111827)),
        );
      case 'mint':
        return ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFE6FFFA),
          fontFamily: 'SF Pro Display',
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFE6FFFA)),
        );
      default:
        return ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'SF Pro Display',
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        );
    }
  }

  void _setTheme(String theme) {
    setState(() {
      _theme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fighter',
      theme: _currentTheme,
      home: LauncherScreen(onThemeChanged: _setTheme, currentTheme: _theme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  final void Function(String)? onThemeChanged;
  final String? currentTheme;
  const MainShell({Key? key, this.onThemeChanged, this.currentTheme}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const TasksScreen(),
      const CalendarScreen(),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        currentTheme: widget.currentTheme,
      ),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: FloatingNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

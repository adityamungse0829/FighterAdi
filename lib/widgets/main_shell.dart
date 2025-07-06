import 'package:flutter/material.dart';
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
import 'floating_nav.dart';

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
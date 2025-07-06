import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/task_provider.dart';
import 'screens/user_provider.dart';
import 'screens/auth_screen.dart';
import 'widgets/main_shell.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const FighterApp(),
    ),
  );
}

class FighterApp extends StatefulWidget {
  const FighterApp({Key? key}) : super(key: key);

  @override
  State<FighterApp> createState() => _FighterAppState();
}

class _FighterAppState extends State<FighterApp> {
  String _theme = 'default';
  bool _isThemeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('selected_theme') ?? 'default';
    setState(() {
      _theme = savedTheme;
      _isThemeLoaded = true;
    });
  }

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

  void _setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
    setState(() {
      _theme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isThemeLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Fighter',
      theme: _currentTheme,
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!userProvider.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (userProvider.isAuthenticated) {
            // Set the user context for TaskProvider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              taskProvider.setUserContext(userProvider.userName);
            });
            
            return MainShell(
              onThemeChanged: _setTheme,
              currentTheme: _theme,
            );
          }
          
          return AuthScreen(
            onThemeChanged: _setTheme,
            currentTheme: _theme,
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

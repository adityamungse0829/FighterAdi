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

class _FighterAppState extends State<FighterApp> with WidgetsBindingObserver {
  String _theme = 'default';
  bool _isThemeLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Save tasks when app goes to background or is closed
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // Save tasks immediately when app goes to background
      Future.delayed(const Duration(milliseconds: 50), () {
        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            final taskProvider = Provider.of<TaskProvider>(context, listen: false);
            taskProvider.forceSaveTasks();
            print('Tasks saved on app lifecycle change: $state');
          }
        } catch (e) {
          // Handle error gracefully
          print('Error saving tasks on app lifecycle change: $e');
        }
      });
    }
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

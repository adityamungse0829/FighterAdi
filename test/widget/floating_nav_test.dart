import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/widgets/floating_nav.dart';
import 'package:fighter/screens/user_provider.dart';
import 'package:fighter/screens/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FloatingNav Widget Tests', () {
    late UserProvider userProvider;
    late TaskProvider taskProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userProvider = UserProvider();
      taskProvider = TaskProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      await userProvider.setNamedUser('Test User');
      taskProvider.setUserContext('Test User');
    });

    Widget createTestWidget({int selectedIndex = 0, void Function(int)? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
              ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
            ],
            child: Column(
              children: [
                Expanded(child: Container()),
                FloatingNav(
                  selectedIndex: selectedIndex,
                  onTap: onTap ?? (_) {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('WT_NAV_001: Floating navigation displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectedIndex: 0));
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget); // Tasks
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget); // Calendar
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget); // Settings
    });

    testWidgets('WT_NAV_002: Navigation between screens', (WidgetTester tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(createTestWidget(
        selectedIndex: 0,
        onTap: (index) {
          tappedIndex = index;
        },
      ));
      await tester.pumpAndSettle();
      debugPrint('After initial pump:');
      debugDumpApp();
      // Tap Calendar icon
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();
      expect(tappedIndex, 1);
      // Tap Settings icon
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);
      // Tap Tasks icon
      await tester.tap(find.byIcon(Icons.checklist_rounded));
      await tester.pumpAndSettle();
      expect(tappedIndex, 0);
    });
  });
} 
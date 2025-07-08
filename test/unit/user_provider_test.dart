import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fighter/screens/user_provider.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;
  late UserProvider userProvider;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    // Mock SharedPreferences.getInstance() to return our mockPrefs
    SharedPreferences.setMockInitialValues({}); // Clear any previous mock values
    when(mockPrefs.getString('userName')).thenReturn(null);
    when(mockPrefs.getBool('isGuest')).thenReturn(false);

    // Provide the mock SharedPreferences instance to the UserProvider
    // This is a bit tricky as SharedPreferences.getInstance() is static.
    // We'll rely on setMockInitialValues for the actual instance returned.
    // For direct mocking, we'd typically inject it, but for this setup,
    // setMockInitialValues is the intended way.
    userProvider = UserProvider();
  });

  group('UserProvider Tests', () {
    test('UT_UP_001: UserProvider initialization', () async {
      // Initial state should be unauthenticated and not guest until loaded
      expect(userProvider.isInitialized, isFalse); // Should be false initially

      // Wait for the async _loadUserData to complete
      await userProvider.initializationFuture;

      expect(userProvider.isInitialized, isTrue);
      expect(userProvider.userName, isNull);
      expect(userProvider.isGuest, isFalse);
      expect(userProvider.isAuthenticated, isFalse);
      expect(userProvider.displayName, 'User');
      expect(userProvider.welcomeMessage, 'Welcome, User!');
    });

    test('UT_UP_002: Set named user functionality', () async {
      // Mock SharedPreferences behavior for setNamedUser
      when(mockPrefs.setString('userName', any)).thenAnswer((_) async => true);
      when(mockPrefs.setBool('isGuest', any)).thenAnswer((_) async => true);

      await userProvider.setNamedUser('John Doe');

      expect(userProvider.userName, 'John Doe');
      expect(userProvider.isGuest, isFalse);
      expect(userProvider.isAuthenticated, isTrue);
      expect(userProvider.displayName, 'John Doe');
      expect(userProvider.welcomeMessage, 'Welcome, John Doe!');

      verify(mockPrefs.setString('userName', 'John Doe')).called(1);
      verify(mockPrefs.setBool('isGuest', false)).called(1);
    });

    test('UT_UP_003: Set guest user functionality', () async {
      // Mock SharedPreferences behavior for setGuestUser
      when(mockPrefs.remove('userName')).thenAnswer((_) async => true);
      when(mockPrefs.setBool('isGuest', any)).thenAnswer((_) async => true);

      await userProvider.setGuestUser();

      expect(userProvider.userName, isNull);
      expect(userProvider.isGuest, isTrue);
      expect(userProvider.isAuthenticated, isTrue);
      expect(userProvider.displayName, 'Guest');
      expect(userProvider.welcomeMessage, 'Welcome, Guest!');

      verify(mockPrefs.remove('userName')).called(1);
      verify(mockPrefs.setBool('isGuest', true)).called(1);
    });

    test('UT_UP_004: Display name generation', () async {
      // Test named user
      when(mockPrefs.getString('userName')).thenReturn('Alice');
      when(mockPrefs.getBool('isGuest')).thenReturn(false);
      userProvider = UserProvider(); // Re-initialize to load mocked data
      await userProvider.initializationFuture;
      expect(userProvider.displayName, 'Alice');

      // Test guest user
      when(mockPrefs.getString('userName')).thenReturn(null);
      when(mockPrefs.getBool('isGuest')).thenReturn(true);
      userProvider = UserProvider(); // Re-initialize to load mocked data
      await userProvider.initializationFuture;
      expect(userProvider.displayName, 'Guest');

      // Test null user (neither named nor guest, should default to 'User')
      when(mockPrefs.getString('userName')).thenReturn(null);
      when(mockPrefs.getBool('isGuest')).thenReturn(false);
      userProvider = UserProvider(); // Re-initialize to load mocked data
      await userProvider.initializationFuture;
      expect(userProvider.displayName, 'User');
    });

    test('UT_UP_005: Welcome message generation', () async {
      // Test named user
      when(mockPrefs.getString('userName')).thenReturn('Bob');
      when(mockPrefs.getBool('isGuest')).thenReturn(false);
      userProvider = UserProvider(); // Re-initialize to load mocked data
      await userProvider.initializationFuture;
      expect(userProvider.welcomeMessage, 'Welcome, Bob!');

      // Test guest user
      when(mockPrefs.getString('userName')).thenReturn(null);
      when(mockPrefs.getBool('isGuest')).thenReturn(true);
      userProvider = UserProvider(); // Re-initialize to load mocked data
      await userProvider.initializationFuture;
      expect(userProvider.welcomeMessage, 'Welcome, Guest!');
    });

    test('Clear user data functionality', () async {
      // Arrange: Set up a named user first
      when(mockPrefs.setString('userName', any)).thenAnswer((_) async => true);
      when(mockPrefs.setBool('isGuest', any)).thenAnswer((_) async => true);
      await userProvider.setNamedUser('User To Clear');
      expect(userProvider.isAuthenticated, isTrue);

      // Mock SharedPreferences behavior for clearUserData
      when(mockPrefs.remove('userName')).thenAnswer((_) async => true);
      when(mockPrefs.remove('isGuest')).thenAnswer((_) async => true);

      // Act
      await userProvider.clearUserData();

      // Assert
      expect(userProvider.userName, isNull);
      expect(userProvider.isGuest, isFalse);
      expect(userProvider.isAuthenticated, isFalse);

      verify(mockPrefs.remove('userName')).called(1);
      verify(mockPrefs.remove('isGuest')).called(1);
    });
  });
}
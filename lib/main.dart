import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
import 'models/transaction_model.dart';
import 'models/family_model.dart';
import 'models/family_member_model.dart';
import 'models/notification_model.dart';
import 'utils/app_theme.dart';

// Global flag to prevent multiple Firebase initializations
bool _firebaseInitialized = false;

// Global flag to prevent multiple app starts
bool _appStarted = false;

void main() {
  // Prevent multiple calls to main()
  if (_appStarted) {
    return;
  }
  _appStarted = true;
  
  WidgetsFlutterBinding.ensureInitialized();
  _initializeApp();
}

void _initializeApp() async {
  try {
    print('📱 Starting app...');
    
    // Initialize Firebase - ONLY ONCE
    print('🔥 Initializing Firebase...');
    
    if (!_firebaseInitialized) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC2PqPJ9E1VJj2lPtM06qYwD7xGZ5kR9nQ",
          authDomain: "family-finance-manager.firebaseapp.com",
          projectId: "family-finance-manager",
          storageBucket: "family-finance-manager.appspot.com",
          messagingSenderId: "808843357815",
          appId: "1:808843357815:android:8edf9e5b7c6a4d2f",
        ),
      );
      _firebaseInitialized = true;
      print('✅ Firebase initialized');
    } else {
      print('⚠️ Firebase already initialized, skipping');
    }

    // Initialize Hive
    print('💾 Initializing Hive...');
    await Hive.initFlutter();
    print('✅ Hive initialized');
    
    // Register Hive adapters with try-catch
    print('📦 Registering Hive adapters...');
    _registerAdapter(() => Hive.registerAdapter(UserProfileAdapter()));
    _registerAdapter(() => Hive.registerAdapter(TransactionModelAdapter()));
    _registerAdapter(() => Hive.registerAdapter(TransactionTypeAdapter()));
    _registerAdapter(() => Hive.registerAdapter(TransactionCategoryAdapter()));
    _registerAdapter(() => Hive.registerAdapter(FamilyModelAdapter()));
    _registerAdapter(() => Hive.registerAdapter(FamilyMemberModelAdapter()));
    _registerAdapter(() => Hive.registerAdapter(NotificationModelAdapter()));
    _registerAdapter(() => Hive.registerAdapter(NotificationTypeAdapter()));
    print('✅ Hive adapters registered');
    
    // Open Hive boxes with try-catch
    print('📂 Opening Hive boxes...');
    await _openBox<UserProfile>('userProfile');
    await _openBox<TransactionModel>('transactions');
    await _openBox<FamilyModel>('families');
    await _openBox<FamilyMemberModel>('familyMembers');
    await _openBox<NotificationModel>('notifications');
    await _openBox<dynamic>('appSettings');
    print('✅ Hive boxes opened');

    print('🚀 Starting app...');
    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ ERROR: $e');
    print(stack);
    _showErrorScreen(e);
  }
}

void _registerAdapter(void Function() register) {
  try {
    register();
  } catch (e) {
    print('⚠️ Adapter already registered: $e');
  }
}

Future<void> _openBox<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
  } catch (e) {
    print('⚠️ Box "$boxName" already open: $e');
  }
}

void _showErrorScreen(dynamic error) {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app process
                    _appStarted = false;
                    _firebaseInitialized = false;
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Family Finance Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: true,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/reports': (context) => const ReportsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/transaction-details') {
            final transactionId = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transactionId: transactionId,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      authService.signOut();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

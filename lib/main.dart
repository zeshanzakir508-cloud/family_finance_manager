import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/mode_provider.dart';
import 'providers/family_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/mode_selection/mode_selection_screen.dart';
import 'screens/dashboard/financial_dashboard.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/transfer_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/family/add_member_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/backup/backup_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/goals/goals_screen.dart';
import 'services/auth_service.dart';
import 'services/remote_config_service.dart';
import 'models/user_model.dart';
import 'models/transaction_model.dart';
import 'models/family_model.dart';
import 'models/transfer_model.dart';
import 'models/notification_model.dart';
import 'models/backup_model.dart';
import 'models/goal_model.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'utils/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // STEP 1: Initialize Firebase FIRST
    if (Firebase.apps.isEmpty) {
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
    }

    // STEP 2: Load Remote Config
    await RemoteConfigService.init();

    // STEP 3: Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(FamilyModelAdapter());
    Hive.registerAdapter(TransferModelAdapter());
    Hive.registerAdapter(NotificationModelAdapter());
    Hive.registerAdapter(BackupModelAdapter());
    Hive.registerAdapter(GoalModelAdapter());
    
    // Open boxes
    await Hive.openBox<UserModel>(Constants.usersBox);
    await Hive.openBox<TransactionModel>(Constants.transactionsBox);
    await Hive.openBox<FamilyModel>(Constants.familiesBox);
    await Hive.openBox<TransferModel>(Constants.transfersBox);
    await Hive.openBox<NotificationModel>(Constants.notificationsBox);
    await Hive.openBox<BackupModel>(Constants.backupsBox);
    await Hive.openBox<GoalModel>(Constants.goalsBox);
    await Hive.openBox<dynamic>(Constants.settingsBox);

    // STEP 4: Request permissions (AFTER Firebase)
    await _requestPermissions();

    // STEP 5: Run main app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('INITIALIZATION ERROR: $e');
    print('STACK TRACE: $stackTrace');
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(error: e.toString()),
      ),
    );
  }
}

// Request all permissions
Future<void> _requestPermissions() async {
  // Android 13+ uses different storage permissions
  if (await Permission.storage.isRestricted) {
    // For Android 13+ (API 33+)
    await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
  } else {
    // For Android 12 and below
    await Permission.storage.request();
  }

  // Request other permissions
  await [
    Permission.camera,
    Permission.contacts,
    Permission.notification,
    Permission.location,
  ].request();
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              'FinFam',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Family Finance Manager',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        ChangeNotifierProvider(
          create: (_) => ModeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FamilyProvider(),
        ),
      ],
      child: MaterialApp(
        title: Constants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/mode-selection': (context) => const ModeSelectionScreen(),
          '/financial-dashboard': (context) => const FinancialDashboard(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/transfer': (context) => const TransferScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/add-member': (context) => const AddMemberScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/backup': (context) => const BackupScreen(),
          '/owner-dashboard': (context) => const OwnerDashboard(),
          '/goals': (context) => const GoalsScreen(),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        authService.signOut();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const FinancialDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}

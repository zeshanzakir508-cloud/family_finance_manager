import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/mode_provider.dart';
import 'providers/family_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/mode_selection/mode_selection_screen.dart';
import 'screens/dashboard/personal_dashboard.dart';
import 'screens/dashboard/family_dashboard.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/transfer_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/family/add_member_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/backup/backup_screen.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'models/transaction_model.dart';
import 'models/family_model.dart';
import 'models/transfer_model.dart';
import 'models/notification_model.dart';
import 'models/backup_model.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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

    await Hive.initFlutter();
    
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(FamilyModelAdapter());
    Hive.registerAdapter(TransferModelAdapter());
    Hive.registerAdapter(NotificationModelAdapter());
    Hive.registerAdapter(BackupModelAdapter());
    
    await Hive.openBox<UserModel>('users');
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<FamilyModel>('families');
    await Hive.openBox<TransferModel>('transfers');
    await Hive.openBox<NotificationModel>('notifications');
    await Hive.openBox<BackupModel>('backups');
    await Hive.openBox<dynamic>('appSettings');

    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
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
                    'Error: $e',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
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
          '/personal-dashboard': (context) => const PersonalDashboard(),
          '/family-dashboard': (context) => const FamilyDashboard(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/transfer': (context) => const TransferScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/add-member': (context) => const AddMemberScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/backup': (context) => const BackupScreen(),
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
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const ModeSelectionScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

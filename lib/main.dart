import 'package:flutter/material.dart';
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
import 'screens/transactions/transaction_details_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';
import 'models/transaction_model.dart';
import 'models/family_model.dart';
import 'models/notification_model.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB8kZxPq5l9cG7dE6fH3jK2mN4oP5qR6sT7uV8wX9yZ",
      authDomain: "family-finance-manager.firebaseapp.com",
      projectId: "family-finance-manager",
      storageBucket: "family-finance-manager.appspot.com",
      messagingSenderId: "123456789012",
      appId: "1:123456789012:android:abcdef1234567890",
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(FamilyModelAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  
  // Open Hive boxes
  await Hive.openBox<UserProfile>('userProfile');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<FamilyModel>('families');
  await Hive.openBox<NotificationModel>('notifications');
  await Hive.openBox<dynamic>('appSettings');

  runApp(const MyApp());
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
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/transaction-details': (context) => const TransactionDetailsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/reports': (context) => const ReportsScreen(),
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

    return StreamBuilder<dynamic>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

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
import 'screens/transactions/add_income_screen.dart';
import 'screens/transactions/add_expense_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'screens/transactions/edit_transaction_screen.dart';
import 'screens/transactions/transfer_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/family/family_creation_screen.dart';
import 'screens/family/add_member_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/currency_settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/security_settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/backup/backup_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/remote_config_service.dart';
import 'services/notification_service.dart';
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
    // ✅ CORRECT Firebase config from google-services.json
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCqtTXPsJFw1kGsL83KQWVxSMuTKJTxDW4",
          authDomain: "family-finance-manager-92dc9.firebaseapp.com",
          projectId: "family-finance-manager-92dc9",
          storageBucket: "family-finance-manager-92dc9.firebasestorage.app",
          messagingSenderId: "939621300884",
          appId: "1:939621300884:android:ddc013394d763393f91281",
        ),
      );
    }

    await RemoteConfigService.init();
    await Hive.initFlutter();
    
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(FamilyModelAdapter());
    Hive.registerAdapter(TransferModelAdapter());
    Hive.registerAdapter(NotificationModelAdapter());
    Hive.registerAdapter(BackupModelAdapter());
    Hive.registerAdapter(GoalModelAdapter());
    
    await Hive.openBox<UserModel>(Constants.usersBox);
    await Hive.openBox<TransactionModel>(Constants.transactionsBox);
    await Hive.openBox<FamilyModel>(Constants.familiesBox);
    await Hive.openBox<TransferModel>(Constants.transfersBox);
    await Hive.openBox<NotificationModel>(Constants.notificationsBox);
    await Hive.openBox<BackupModel>(Constants.backupsBox);
    await Hive.openBox<GoalModel>(Constants.goalsBox);
    await Hive.openBox<dynamic>(Constants.settingsBox);

    await NotificationService.init();
    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('App Initialization Failed'),
                  const SizedBox(height: 8),
                  Text('Error: $e', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => main(), child: const Text('Retry')),
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
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: MaterialApp(
        title: Constants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/mode-selection': (context) => const ModeSelectionScreen(),
          '/personal-dashboard': (context) => const PersonalDashboard(),
          '/family-dashboard': (context) => const FamilyDashboard(),
          '/add-income': (context) => const AddIncomeScreen(),
          '/add-expense': (context) => const AddExpenseScreen(),
          '/transaction-detail': (context) => const TransactionDetailScreen(),
          '/edit-transaction': (context) => const EditTransactionScreen(),
          '/transfer': (context) => const TransferScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/family-create': (context) => const FamilyCreationScreen(),
          '/add-member': (context) => const AddMemberScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/currency-settings': (context) => const CurrencySettingsScreen(),
          '/theme-settings': (context) => const ThemeSettingsScreen(),
          '/notification-settings': (context) => const NotificationSettingsScreen(),
          '/security-settings': (context) => const SecuritySettingsScreen(),
          '/about': (context) => const AboutScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/backup': (context) => const BackupScreen(),
          '/owner-dashboard': (context) => const OwnerDashboard(),
          '/goals': (context) => const GoalsScreen(),
        },
      ),
    );
  }
}

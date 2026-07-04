// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/mode_provider.dart';
import 'providers/family_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/splash_screen.dart'; // ✅ ADDED
import 'screens/onboarding/onboarding_screen.dart'; // ✅ ADDED
import 'screens/mode_selection/mode_selection_screen.dart';
import 'screens/dashboard/personal_dashboard.dart';
import 'screens/dashboard/family_dashboard.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/settings/currency_settings_screen.dart';
import 'screens/settings/security_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/goals_screen.dart'; // ✅ ADDED
import 'screens/transactions/add_income_screen.dart';
import 'screens/transactions/add_expense_screen.dart';
import 'screens/transactions/transfer_screen.dart';
import 'screens/transactions/edit_transaction_screen.dart'; // ✅ ADDED
import 'screens/transactions/transaction_detail_screen.dart'; // ✅ ADDED
import 'screens/family/family_management_screen.dart';
import 'screens/family/family_creation_screen.dart'; // ✅ ADDED
import 'screens/family/add_member_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/backup/backup_screen.dart';
import 'screens/profile/profile_screen.dart'; // ✅ ADDED
import 'utils/app_theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        // DatabaseService as a service (not a provider)
      ],
      child: MaterialApp(
        title: 'FinFam - Family Finance Manager',
        debugShowCheckedModeBanner: false,
        theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        initialRoute: '/splash', // ✅ CHANGED: Start with splash screen
        routes: {
          // Auth
          '/splash': (context) => const SplashScreen(), // ✅ ADDED
          '/onboarding': (context) => const OnboardingScreen(), // ✅ ADDED
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          
          // Mode Selection
          '/mode-selection': (context) => const ModeSelectionScreen(),
          
          // Dashboards
          '/personal-dashboard': (context) => const PersonalDashboard(),
          '/family-dashboard': (context) => const FamilyDashboard(),
          
          // Settings
          '/settings': (context) => const SettingsScreen(),
          '/theme-settings': (context) => const ThemeSettingsScreen(),
          '/currency-settings': (context) => const CurrencySettingsScreen(),
          '/security-settings': (context) => const SecuritySettingsScreen(),
          '/notification-settings': (context) => const NotificationSettingsScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/about': (context) => const AboutScreen(),
          '/profile': (context) => const ProfileScreen(), // ✅ ADDED
          
          // Transactions
          '/add-income': (context) => const AddIncomeScreen(),
          '/add-expense': (context) => const AddExpenseScreen(),
          '/transfer': (context) => const TransferScreen(),
          '/edit-transaction': (context) => const EditTransactionScreen(), // ✅ ADDED
          '/transaction-detail': (context) => const TransactionDetailScreen(), // ✅ ADDED
          
          // Reports
          '/reports': (context) => const ReportsScreen(),
          '/goals': (context) => const GoalsScreen(), // ✅ ADDED
          
          // Family
          '/family-management': (context) => const FamilyManagementScreen(),
          '/family-creation': (context) => const FamilyCreationScreen(), // ✅ ADDED
          '/add-member': (context) => const AddMemberScreen(),
          
          // Owner
          '/owner-dashboard': (context) => const OwnerDashboard(),
          
          // Backup
          '/backup': (context) => const BackupScreen(),
        },
        // Handle unknown routes
        onGenerateRoute: (settings) {
          // If route doesn't exist, go to splash
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          );
        },
      ),
    );
  }
}

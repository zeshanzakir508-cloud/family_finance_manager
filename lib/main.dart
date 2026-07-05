// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/mode_provider.dart';
import 'providers/family_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
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
import 'screens/transactions/add_income_screen.dart';
import 'screens/transactions/add_expense_screen.dart';
import 'screens/transactions/transfer_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/family/add_member_screen.dart';
import 'screens/family/family_creation_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/backup/backup_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/transactions/edit_transaction_screen.dart';
import 'screens/transactions/transaction_detail_screen.dart';
import 'utils/app_theme.dart';
import 'utils/helpers.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await Helpers.initCurrency();
  await _requestPermissions();
  
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final permissionsAsked = prefs.getBool('permissions_asked') ?? false;
    
    if (permissionsAsked) {
      final storageStatus = await Permission.storage.status;
      final cameraStatus = await Permission.camera.status;
      
      if (storageStatus.isGranted && cameraStatus.isGranted) {
        return;
      }
    }

    await [
      Permission.storage,
      Permission.camera,
      Permission.notifications,
    ].request();

    await prefs.setBool('permissions_asked', true);
    
    print('✅ Permissions requested');
  } catch (e) {
    print('❌ Permission error: $e');
  }
}

Future<bool> arePermissionsGranted() async {
  try {
    final storageStatus = await Permission.storage.status;
    final cameraStatus = await Permission.camera.status;
    
    return storageStatus.isGranted && cameraStatus.isGranted;
  } catch (e) {
    return false;
  }
}

Future<void> showPermissionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Permissions Required'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FinFam needs the following permissions:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('📁 Storage - To save backups and reports'),
          Text('📷 Camera - To scan receipts and documents'),
          Text('🔔 Notifications - To send reminders and alerts'),
          SizedBox(height: 12),
          Text(
            'Please allow these permissions to use the app.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
          child: const Text('Open Settings'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _requestPermissions();
            if (await arePermissionsGranted()) {
              // Proceed
            } else {
              showPermissionDialog(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = themeMode == 'dark'
          ? ThemeMode.dark
          : themeMode == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  void refreshTheme() {
    _loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: MaterialApp(
        title: 'FinFam - Family Finance Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        initialRoute: '/splash',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/mode-selection': (context) => const ModeSelectionScreen(),
          '/personal-dashboard': (context) => const PersonalDashboard(),
          '/family-dashboard': (context) => const FamilyDashboard(),
          '/settings': (context) => const SettingsScreen(),
          '/theme-settings': (context) => ThemeSettingsScreen(
              onThemeChanged: refreshTheme,
            ),
          '/currency-settings': (context) => const CurrencySettingsScreen(),
          '/security-settings': (context) => const SecuritySettingsScreen(),
          '/notification-settings': (context) => const NotificationSettingsScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/about': (context) => const AboutScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/add-income': (context) => const AddIncomeScreen(),
          '/add-expense': (context) => const AddExpenseScreen(),
          '/transfer': (context) => const TransferScreen(),
          '/edit-transaction': (context) => const EditTransactionScreen(),
          '/transaction-detail': (context) => const TransactionDetailScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/family-management': (context) => const FamilyManagementScreen(),
          '/add-member': (context) => const AddMemberScreen(),
          '/family-creation': (context) => const FamilyCreationScreen(),
          '/goals': (context) => const GoalsScreen(),
          '/owner-dashboard': (context) => const OwnerDashboard(),
          '/backup': (context) => const BackupScreen(),
        },
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          );
        },
      ),
    );
  }
}

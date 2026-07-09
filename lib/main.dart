// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/app_config.dart';
import 'config/firebase_config.dart';
import 'config/route_config.dart';
import 'config/theme_config.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/family_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/report_provider.dart';
import 'providers/category_provider.dart';
import 'providers/mode_provider.dart';

// Services
import 'services/notification_service.dart';
import 'services/biometric_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Local Storage (Hive)
  await LocalStorageService.init();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Request Permissions
  await _requestPermissions();
  
  // Run App
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CurrencyProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BiometricService()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  // Request all required permissions
  final permissions = [
    Permission.notification,
    Permission.camera,
    Permission.storage,
    Permission.contacts,
  ];
  
  // Request permissions
  for (var permission in permissions) {
    final status = await permission.request();
    if (status.isDenied) {
      debugPrint('⚠️ Permission ${permission.toString()} denied');
    } else if (status.isGranted) {
      debugPrint('✅ Permission ${permission.toString()} granted');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set status bar and navigation bar colors
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // Routes
          initialRoute: RouteConfig.splash,
          routes: RouteConfig.routes,
          onGenerateRoute: RouteConfig.onGenerateRoute,
          
          // Localization
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ur', 'PK'),
            Locale('ar', 'SA'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          // Uncomment when localization is ready
          // localizationsDelegates: [
          //   AppLocalizations.delegate,
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          // ],
        );
      },
    );
  }
}

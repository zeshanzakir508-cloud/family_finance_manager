// lib/config/route_config.dart
import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/biometric_auth_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/mode_selection/mode_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard/personal_dashboard.dart';
import '../screens/dashboard/family_dashboard.dart';
import '../screens/transactions/add_income_screen.dart';
import '../screens/transactions/add_expense_screen.dart';
import '../screens/transactions/transaction_list_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/transactions/edit_transaction_screen.dart';
import '../screens/transactions/search_transactions_screen.dart';
import '../screens/transactions/recurring_transactions_screen.dart';
import '../screens/transactions/split_transaction_screen.dart';
import '../screens/transactions/transfer_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/budget/add_budget_screen.dart';
import '../screens/budget/budget_detail_screen.dart';
import '../screens/budget/budget_rollover_screen.dart';
import '../screens/budget/budget_templates_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/goals/add_goal_screen.dart';
import '../screens/goals/goal_detail_screen.dart';
import '../screens/goals/goal_contribution_screen.dart';
import '../screens/family/family_management_screen.dart';
import '../screens/family/family_setup_screen.dart';
import '../screens/family/join_family_screen.dart';
import '../screens/family/invite_family_screen.dart';
import '../screens/family/family_members_screen.dart';
import '../screens/family/add_member_screen.dart';
import '../screens/family/family_creation_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/report_detail_screen.dart';
import '../screens/reports/spending_breakdown_screen.dart';
import '../screens/reports/income_expense_screen.dart';
import '../screens/reports/cash_flow_screen.dart';
import '../screens/reports/year_over_year_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/currency_settings_screen.dart';
import '../screens/settings/theme_settings_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/settings/security_settings_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/backup_restore_screen.dart';
import '../screens/settings/export_data_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/owner/owner_dashboard.dart';

class RouteConfig {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot_password';
  static const String verifyEmail = '/verify_email';
  static const String biometricAuth = '/biometric_auth';
  static const String modeSelection = '/mode_selection';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String personalDashboard = '/personal_dashboard';
  static const String familyDashboard = '/family_dashboard';

  // Transactions
  static const String addIncome = '/add_income';
  static const String addExpense = '/add_expense';
  static const String transactionList = '/transactions';
  static const String transactionDetail = '/transaction_detail';
  static const String editTransaction = '/edit_transaction';
  static const String searchTransactions = '/search_transactions';
  static const String recurringTransactions = '/recurring_transactions';
  static const String splitTransaction = '/split_transaction';
  static const String transfer = '/transfer';

  // Budget
  static const String budget = '/budget';
  static const String addBudget = '/add_budget';
  static const String budgetDetail = '/budget_detail';
  static const String budgetRollover = '/budget_rollover';
  static const String budgetTemplates = '/budget_templates';

  // Goals
  static const String goals = '/goals';
  static const String addGoal = '/add_goal';
  static const String goalDetail = '/goal_detail';
  static const String goalContribution = '/goal_contribution';

  // Family
  static const String familyManagement = '/family_management';
  static const String familySetup = '/family_setup';
  static const String joinFamily = '/join_family';
  static const String inviteFamily = '/invite_family';
  static const String familyMembers = '/family_members';
  static const String addMember = '/add_member';
  static const String familyCreation = '/family_creation';

  // Reports
  static const String reports = '/reports';
  static const String reportDetail = '/report_detail';
  static const String spendingBreakdown = '/spending_breakdown';
  static const String incomeExpense = '/income_expense';
  static const String cashFlow = '/cash_flow';
  static const String yearOverYear = '/year_over_year';

  // Settings
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/edit_profile';
  static const String currencySettings = '/currency_settings';
  static const String themeSettings = '/theme_settings';
  static const String notificationSettings = '/notification_settings';
  static const String languageSettings = '/language_settings';
  static const String securitySettings = '/security_settings';
  static const String changePassword = '/change_password';
  static const String backupRestore = '/backup_restore';
  static const String exportData = '/export_data';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy_policy';

  // Notifications
  static const String notifications = '/notifications';

  // Owner
  static const String ownerDashboard = '/owner_dashboard';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      verifyEmail: (context) => const VerifyEmailScreen(),
      biometricAuth: (context) => const BiometricAuthScreen(),
      modeSelection: (context) => const ModeSelectionScreen(),
      home: (context) => const HomeScreen(),
      personalDashboard: (context) => const PersonalDashboard(),
      familyDashboard: (context) => const FamilyDashboard(),

      // Transactions
      addIncome: (context) => const AddIncomeScreen(),
      addExpense: (context) => const AddExpenseScreen(),
      transactionList: (context) => const TransactionListScreen(),
      transactionDetail: (context) => const TransactionDetailScreen(),
      editTransaction: (context) => const EditTransactionScreen(),
      searchTransactions: (context) => const SearchTransactionsScreen(),
      recurringTransactions: (context) => const RecurringTransactionsScreen(),
      splitTransaction: (context) => const SplitTransactionScreen(),
      transfer: (context) => const TransferScreen(),

      // Budget
      budget: (context) => const BudgetScreen(),
      addBudget: (context) => const AddBudgetScreen(),
      budgetDetail: (context) => const BudgetDetailScreen(),
      budgetRollover: (context) => const BudgetRolloverScreen(),
      budgetTemplates: (context) => const BudgetTemplatesScreen(),

      // Goals
      goals: (context) => const GoalsScreen(),
      addGoal: (context) => const AddGoalScreen(),
      goalDetail: (context) => const GoalDetailScreen(),
      goalContribution: (context) => const GoalContributionScreen(),

      // Family
      familyManagement: (context) => const FamilyManagementScreen(),
      familySetup: (context) => const FamilySetupScreen(),
      joinFamily: (context) => const JoinFamilyScreen(),
      inviteFamily: (context) => const InviteFamilyScreen(),
      familyMembers: (context) => const FamilyMembersScreen(),
      addMember: (context) => const AddMemberScreen(),
      familyCreation: (context) => const FamilyCreationScreen(),

      // Reports
      reports: (context) => const ReportsScreen(),
      reportDetail: (context) => const ReportDetailScreen(),
      spendingBreakdown: (context) => const SpendingBreakdownScreen(),
      incomeExpense: (context) => const IncomeExpenseScreen(),
      cashFlow: (context) => const CashFlowScreen(),
      yearOverYear: (context) => const YearOverYearScreen(),

      // Settings
      settings: (context) => const SettingsScreen(),
      profile: (context) => const ProfileScreen(),
      editProfile: (context) => const EditProfileScreen(),
      currencySettings: (context) => const CurrencySettingsScreen(),
      themeSettings: (context) => const ThemeSettingsScreen(),
      notificationSettings: (context) => const NotificationSettingsScreen(),
      languageSettings: (context) => const LanguageSettingsScreen(),
      securitySettings: (context) => const SecuritySettingsScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      backupRestore: (context) => const BackupRestoreScreen(),
      exportData: (context) => const ExportDataScreen(),
      about: (context) => const AboutScreen(),
      privacyPolicy: (context) => const PrivacyPolicyScreen(),

      // Notifications
      notifications: (context) => const NotificationsScreen(),

      // Owner
      ownerDashboard: (context) => const OwnerDashboard(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle routes with arguments
    
    // ✅ FIXED: Added proper route handling with arguments
    if (settings.name == transactionDetail) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transactionId: args ?? ''),
      );
    }
    
    if (settings.name == editTransaction) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transactionId: args ?? ''),
      );
    }
    
    if (settings.name == budgetDetail) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => BudgetDetailScreen(budgetId: args ?? ''),
      );
    }
    
    if (settings.name == budgetRollover) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => BudgetRolloverScreen(budgetId: args ?? ''),
      );
    }
    
    if (settings.name == goalDetail) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goalId: args ?? ''),
      );
    }
    
    if (settings.name == reportDetail) {
      final args = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => ReportDetailScreen(reportId: args ?? ''),
      );
    }
    
    return null;
  }
}

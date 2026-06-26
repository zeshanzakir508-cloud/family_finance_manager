class Constants {
  static const String appName = 'Family Finance Manager';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String usersBox = 'users';
  static const String transactionsBox = 'transactions';
  static const String familiesBox = 'families';
  static const String transfersBox = 'transfers';
  static const String notificationsBox = 'notifications';
  static const String backupsBox = 'backups';
  static const String settingsBox = 'appSettings';

  // SharedPreferences Keys
  static const String rememberModeKey = 'remember_mode';
  static const String selectedModeKey = 'selected_mode';
  static const String darkModeKey = 'dark_mode';
  static const String currencyKey = 'currency';
  static const String fingerprintKey = 'fingerprint';
  static const String notificationsKey = 'notifications';

  // Currencies
  static const List<String> currencies = [
    'USD', 'EUR', 'GBP', 'PKR', 'INR', 'AED', 'SAR', 'CAD', 'AUD', 'JPY'
  ];

  // Transaction Categories
  static const List<String> incomeCategories = [
    'Salary', 'Investment', 'Gift', 'Rental', 'Business', 'Freelance', 'Other Income'
  ];

  static const List<String> expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Entertainment', 'Utilities', 'Rent',
    'Healthcare', 'Education', 'Travel', 'Insurance', 'Groceries', 'Dining',
    'Clothing', 'Electronics', 'Other Expense'
  ];

  // Family Limits
  static const int maxFamilyMembers = 15;

  // Transfer Status
  static const String transferPending = 'pending';
  static const String transferApproved = 'approved';
  static const String transferRejected = 'rejected';
  static const String transferCompleted = 'completed';

  // Modes
  static const String modePersonal = 'personal';
  static const String modeFamily = 'family';
}

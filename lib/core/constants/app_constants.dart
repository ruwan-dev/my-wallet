/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ExpenseTracker';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String categoriesCollection = 'categories';
  static const String budgetsCollection = 'budgets';

  // Hive Boxes
  static const String expenseBox = 'expenses_box'; // legacy, keeping for fallback if needed
  static const String transactionsBox = 'transactions_box';
  static const String accountsBox = 'accounts_box';
  static const String categoriesBox = 'categories_box';
  static const String settingsBox = 'settings_box';
  static const String userBox = 'user_box';

  // SharedPreferences Keys
  static const String themeKey = 'theme_mode';
  static const String currencyKey = 'currency';
  static const String onboardingKey = 'onboarding_complete';
  static const String lastSweepMonthKey = 'last_sweep_month';

  // Default Values
  static const String defaultCurrency = 'USD';
  static const String defaultCurrencySymbol = 'Rs ';

  // Pagination
  static const int pageSize = 20;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

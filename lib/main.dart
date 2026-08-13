import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/data/models/category_model.dart';
import 'features/expenses/data/models/account_model.dart';
import 'features/expenses/data/models/transaction_model.dart';
import 'features/expenses/presentation/bloc/account_cubit.dart';
import 'features/expenses/presentation/bloc/transaction_cubit.dart';
import 'features/expenses/presentation/bloc/category_cubit.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/expenses/presentation/bloc/budget_cubit.dart';
import 'features/expenses/presentation/bloc/monthly_budget_cubit.dart';
import 'features/budgets/presentation/bloc/custom_budget_cubit.dart';
import 'core/bloc/settings_cubit.dart';
import 'features/expenses/data/services/data_migration_service.dart';
import 'features/debts/data/models/debt_model.dart';
import 'features/debts/presentation/bloc/debt_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialise Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(DebtModelAdapter());
  
  // Open Boxes
  await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
  await Hive.openBox<AccountModel>(AppConstants.accountsBox);
  await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
  await Hive.openBox<DebtModel>(AppConstants.debtsBox);
  await Hive.openBox(AppConstants.settingsBox);

  // Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialise Dependency Injection
  await configureDependencies();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: sl<AccountCubit>(),
        ),
        BlocProvider.value(
          value: sl<TransactionCubit>(),
        ),
        BlocProvider.value(
          value: sl<CategoryCubit>(),
        ),
        BlocProvider.value(
          value: sl<AuthCubit>(),
        ),
        BlocProvider.value(
          value: sl<BudgetCubit>(),
        ),
        BlocProvider.value(
          value: sl<DebtCubit>(),
        ),
        BlocProvider.value(
          value: sl<MonthlyBudgetCubit>(),
        ),
        BlocProvider.value(
          value: sl<CustomBudgetCubit>(),
        ),
        BlocProvider.value(
          value: sl<SettingsCubit>(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            appRouter.go('/login');
          } else if (state is AuthAuthenticated) {
            if (state.user.isPremium) {
              // Automatically try to migrate once (service checks SharedPreferences to avoid duplicate)
              sl<DataMigrationService>().migrateLocalToFirebase(state.user.id);
            }
            if (state.user.forceSync) {
              // Force migrate when requested by admin, ignoring the SharedPreferences check
              sl<DataMigrationService>().migrateLocalToFirebase(state.user.id, force: true);
              FirebaseFirestore.instance.collection('users').doc(state.user.id).update({'forceSync': false}).catchError((e) {
                print('Failed to reset forceSync flag: $e');
              });
            }
            context.read<AccountCubit>().loadAccounts();
            context.read<TransactionCubit>().loadTransactions();
            context.read<CategoryCubit>().loadCategories();
            context.read<BudgetCubit>().loadBudgetsForMonth(DateTime.now());
            context.read<MonthlyBudgetCubit>().init(state.user.id);
            context.read<DebtCubit>().loadDebts(state.user.id);
            appRouter.go('/');
          }
        },
        child: MaterialApp.router(
          title: 'ExpenseTracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/data/models/category_model.dart';
import 'features/expenses/presentation/bloc/account_cubit.dart';
import 'features/expenses/presentation/bloc/transaction_cubit.dart';
import 'features/expenses/presentation/bloc/category_cubit.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/expenses/presentation/bloc/budget_cubit.dart';
import 'features/expenses/presentation/bloc/monthly_budget_cubit.dart';
import 'features/budgets/presentation/bloc/custom_budget_cubit.dart';

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
  
  // Open Boxes
  await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
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
          value: sl<MonthlyBudgetCubit>(),
        ),
        BlocProvider.value(
          value: sl<CustomBudgetCubit>(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            appRouter.go('/login');
          } else if (state is AuthAuthenticated) {
            context.read<AccountCubit>().loadAccounts();
            context.read<TransactionCubit>().loadTransactions();
            context.read<CategoryCubit>().loadCategories();
            context.read<BudgetCubit>().loadBudgetsForMonth(DateTime.now());
            context.read<MonthlyBudgetCubit>().init(state.userId);
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

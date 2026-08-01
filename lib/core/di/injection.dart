import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../../features/expenses/data/datasources/account_remote_datasource.dart';
import '../../features/expenses/data/datasources/transaction_remote_datasource.dart';
import '../../features/expenses/data/models/account_model.dart';
import '../../features/expenses/data/models/transaction_model.dart';
import '../../features/expenses/data/repositories/account_repository_impl.dart';
import '../../features/expenses/data/repositories/transaction_repository_impl.dart';
import '../../features/expenses/data/repositories/category_repository_impl.dart';
import '../../features/expenses/domain/repositories/account_repository.dart';
import '../../features/expenses/domain/repositories/transaction_repository.dart';
import '../../features/expenses/domain/repositories/category_repository.dart';
import '../../features/expenses/data/datasources/category_local_datasource.dart';
import '../../features/expenses/data/datasources/category_remote_datasource.dart';
import '../../features/expenses/data/models/category_model.dart';
import '../../features/expenses/presentation/bloc/category_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/expenses/domain/usecases/add_account.dart';
import '../../features/expenses/domain/usecases/update_account.dart';
import '../../features/expenses/domain/usecases/delete_account.dart';
import '../../features/expenses/domain/usecases/add_transaction.dart';
import '../../features/expenses/domain/usecases/delete_transaction.dart';
import '../../features/expenses/domain/usecases/get_transactions.dart';
import '../../features/expenses/domain/usecases/update_transaction.dart';
import '../../features/expenses/domain/usecases/watch_accounts.dart';
import '../../features/expenses/domain/usecases/watch_transactions.dart';
import '../../features/expenses/presentation/bloc/account_cubit.dart';
import '../../features/expenses/presentation/bloc/transaction_cubit.dart';

import '../../features/expenses/data/datasources/budget_remote_datasource.dart';
import '../../features/expenses/data/repositories/budget_repository_impl.dart';
import '../../features/expenses/domain/repositories/budget_repository.dart';
import '../../features/expenses/presentation/bloc/budget_cubit.dart';
import '../../features/expenses/domain/repositories/monthly_budget_repository.dart';
import '../../features/expenses/data/repositories/monthly_budget_repository_impl.dart';
import '../../features/expenses/presentation/bloc/monthly_budget_cubit.dart';

import '../../features/budgets/domain/repositories/custom_budget_repository.dart';
import '../../features/budgets/data/repositories/custom_budget_repository_impl.dart';
import '../../features/budgets/presentation/bloc/custom_budget_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- External / Hive ---
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  
  final categoriesBox   = Hive.box<CategoryModel>(AppConstants.categoriesBox);

  // --- Datasources ---
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => FirestoreAccountRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => FirestoreTransactionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<CategoryLocalDatasource>(
    () => HiveCategoryLocalDatasource(categoriesBox),
  );
  sl.registerLazySingleton<CategoryRemoteDatasource>(
    () => FirestoreCategoryRemoteDatasource(sl()),
  );
  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(sl()),
  );

  // --- Repositories ---
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MonthlyBudgetRepository>(
    () => MonthlyBudgetRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CustomBudgetRepository>(
    () => CustomBudgetRepositoryImpl(sl()),
  );

  // --- UseCases ---
  sl.registerLazySingleton(() => AddAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => WatchAccountsUseCase(sl()));

  sl.registerLazySingleton(() => AddTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => WatchTransactionsUseCase(sl()));

  // --- BLoC / Cubit ---
  sl.registerLazySingleton(
    () => AccountCubit(
      watchAccounts: sl(),
      addAccount: sl(),
      updateAccount: sl(),
      deleteAccount: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => TransactionCubit(
      watchTransactions: sl(),
      addTransaction: sl(),
      updateTransaction: sl(),
      deleteTransaction: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => CategoryCubit(repository: sl(), authRepository: sl()),
  );

  sl.registerLazySingleton(
    () => AuthCubit(
      repository: sl(),
      firebaseAuth: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => BudgetCubit(
      budgetRepository: sl(),
      transactionCubit: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => MonthlyBudgetCubit(repository: sl()),
  );

  sl.registerLazySingleton(
    () => CustomBudgetCubit(
      repository: sl(),
      authCubit: sl(),
    ),
  );
}

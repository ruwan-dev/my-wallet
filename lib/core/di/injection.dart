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
import '../../features/expenses/data/models/category_model.dart';
import '../../features/expenses/presentation/bloc/category_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/expenses/domain/usecases/add_account.dart';
import '../../features/expenses/domain/usecases/delete_account.dart';
import '../../features/expenses/domain/usecases/add_transaction.dart';
import '../../features/expenses/domain/usecases/delete_transaction.dart';
import '../../features/expenses/domain/usecases/get_transactions.dart';
import '../../features/expenses/domain/usecases/update_transaction.dart';
import '../../features/expenses/domain/usecases/watch_accounts.dart';
import '../../features/expenses/domain/usecases/watch_transactions.dart';
import '../../features/expenses/presentation/bloc/account_cubit.dart';
import '../../features/expenses/presentation/bloc/transaction_cubit.dart';

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

  // --- Repositories ---
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepositoryImpl(sl()),
  );

  // --- UseCases ---
  sl.registerLazySingleton(() => AddAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => WatchAccountsUseCase(sl()));

  sl.registerLazySingleton(() => AddTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl(), sl()));
  sl.registerLazySingleton(() => WatchTransactionsUseCase(sl()));

  // --- BLoC / Cubit ---
  sl.registerFactory(
    () => AccountCubit(
      watchAccounts: sl(),
      addAccount: sl(),
      deleteAccount: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => TransactionCubit(
      watchTransactions: sl(),
      addTransaction: sl(),
      updateTransaction: sl(),
      deleteTransaction: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => CategoryCubit(repository: sl()),
  );

  sl.registerFactory(
    () => AuthCubit(
      repository: sl(),
      firebaseAuth: sl(),
    ),
  );
}

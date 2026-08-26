import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../datasources/account_local_datasource.dart';
import '../datasources/transaction_local_datasource.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/account_remote_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/bloc/settings_cubit.dart';

class DataMigrationService {
  final AccountLocalDatasource accountLocal;
  final TransactionLocalDatasource transactionLocal;
  final CategoryLocalDatasource categoryLocal;

  final AccountRemoteDataSource accountRemote;
  final TransactionRemoteDataSource transactionRemote;
  final CategoryRemoteDatasource categoryRemote;
  
  final SharedPreferences prefs;
  final SettingsCubit settingsCubit;

  DataMigrationService({
    required this.accountLocal,
    required this.transactionLocal,
    required this.categoryLocal,
    required this.accountRemote,
    required this.transactionRemote,
    required this.categoryRemote,
    required this.prefs,
    required this.settingsCubit,
  });

  Future<void> migrateLocalToFirebase(String userId, {bool force = false}) async {
    final hasMigrated = prefs.getBool('has_migrated_$userId') ?? false;
    if (hasMigrated && !force) return;

    try {
      // 1. Migrate Categories
      final localCategories = await categoryLocal.getAllCategories(userId);
      for (final cat in localCategories) {
        await categoryRemote.saveCategory(userId, cat);
      }

      // 2. Migrate Accounts
      final localAccounts = await accountLocal.getAllAccounts(userId);
      for (final acc in localAccounts) {
        await accountRemote.saveAccount(userId, acc);
      }

      // 3. Migrate Transactions
      final localTransactions = await transactionLocal.getAllTransactions(userId);
      for (final txn in localTransactions) {
        await transactionRemote.saveTransaction(userId, txn);
      }

      // 4. Migrate Settings
      await settingsCubit.syncToCloud();

      await prefs.setBool('has_migrated_$userId', true);
      
      // Update Firestore so the user is marked as migrated permanently
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasMigratedToCloud': true,
      });
      
      // Optionally, clear local db after migration
      // await accountLocal.clear();
      // await transactionLocal.clear();
    } catch (e) {
      print('Migration failed: $e');
    }
  }
}

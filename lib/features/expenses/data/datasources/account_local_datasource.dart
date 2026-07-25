import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/account_model.dart';

abstract class AccountLocalDatasource {
  Future<List<AccountModel>> getAllAccounts(String userId);
  Stream<List<AccountModel>> watchAllAccounts(String userId);
  Future<AccountModel> getAccount(String id);
  Future<void> saveAccount(AccountModel account);
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
}

class HiveAccountLocalDatasource implements AccountLocalDatasource {
  final Box<AccountModel> box;

  HiveAccountLocalDatasource(this.box);

  @override
  Future<List<AccountModel>> getAllAccounts(String userId) async {
    try {
      final accounts = box.values.where((e) => e.userId == userId).toList();
      return accounts;
    } catch (e) {
      throw CacheException(message: 'Failed to fetch accounts: $e');
    }
  }

  @override
  Stream<List<AccountModel>> watchAllAccounts(String userId) async* {
    // Emit current accounts immediately, then stream future changes.
    yield box.values.where((e) => e.userId == userId).toList();
    yield* box.watch().map((_) {
      return box.values.where((e) => e.userId == userId).toList();
    });
  }

  @override
  Future<AccountModel> getAccount(String id) async {
    try {
      final account = box.values.firstWhere((e) => e.id == id);
      return account;
    } catch (e) {
      throw CacheException(message: 'Failed to find account with id: $id');
    }
  }

  @override
  Future<void> saveAccount(AccountModel account) async {
    try {
      await box.put(account.id, account);
    } catch (e) {
      throw CacheException(message: 'Failed to save account: $e');
    }
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    try {
      if (!box.containsKey(account.id)) {
        throw CacheException(message: 'Account not found for update');
      }
      await box.put(account.id, account);
    } catch (e) {
      throw CacheException(message: 'Failed to update account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Failed to delete account: $e');
    }
  }
}

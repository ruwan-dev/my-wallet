import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/account_model.dart';

abstract class AccountRemoteDataSource {
  Stream<List<AccountModel>> watchAllAccounts(String userId);
  Future<List<AccountModel>> getAllAccounts(String userId);
  Future<AccountModel> getAccount(String userId, String id);
  Future<void> saveAccount(String userId, AccountModel account);
  Future<void> updateAccount(String userId, AccountModel account);
  Future<void> deleteAccount(String userId, String id);
}

class FirestoreAccountRemoteDataSource implements AccountRemoteDataSource {
  final FirebaseFirestore firestore;

  FirestoreAccountRemoteDataSource(this.firestore);

  CollectionReference<Map<String, dynamic>> _accountsRef(String userId) {
    if (userId.isEmpty) throw CacheException(message: 'User ID cannot be empty');
    return firestore.collection('users').doc(userId).collection('accounts');
  }

  @override
  Stream<List<AccountModel>> watchAllAccounts(String userId) {
    try {
      return _accountsRef(userId).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => AccountModel.fromFirestore(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      throw CacheException(message: 'Failed to watch accounts: $e');
    }
  }

  @override
  Future<List<AccountModel>> getAllAccounts(String userId) async {
    try {
      final snapshot = await _accountsRef(userId).get();
      return snapshot.docs.map((doc) => AccountModel.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to fetch accounts: $e');
    }
  }

  @override
  Future<AccountModel> getAccount(String userId, String id) async {
    try {
      final doc = await _accountsRef(userId).doc(id).get();
      if (!doc.exists || doc.data() == null) {
        throw CacheException(message: 'Account not found');
      }
      return AccountModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw CacheException(message: 'Failed to fetch account: $e');
    }
  }

  @override
  Future<void> saveAccount(String userId, AccountModel account) async {
    try {
      // If the ID is empty, Firestore will generate one, but usually our entities generate UUIDs.
      // So we set the document with the explicit ID.
      final id = account.id.isEmpty ? _accountsRef(userId).doc().id : account.id;
      await _accountsRef(userId).doc(id).set(account.toFirestore());
    } catch (e) {
      throw CacheException(message: 'Failed to save account: $e');
    }
  }

  @override
  Future<void> updateAccount(String userId, AccountModel account) async {
    try {
      await _accountsRef(userId).doc(account.id).update(account.toFirestore());
    } catch (e) {
      throw CacheException(message: 'Failed to update account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String userId, String id) async {
    try {
      await _accountsRef(userId).doc(id).delete();
    } catch (e) {
      throw CacheException(message: 'Failed to delete account: $e');
    }
  }
}

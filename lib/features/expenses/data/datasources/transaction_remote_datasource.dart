import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Stream<List<TransactionModel>> watchAllTransactions(String userId);
  Future<List<TransactionModel>> getAllTransactions(String userId);
  Future<void> saveTransaction(String userId, TransactionModel transaction);
  Future<void> updateTransaction(String userId, TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String id);
}

class FirestoreTransactionRemoteDataSource implements TransactionRemoteDataSource {
  final FirebaseFirestore firestore;

  FirestoreTransactionRemoteDataSource(this.firestore);

  CollectionReference<Map<String, dynamic>> _transactionsRef(String userId) {
    if (userId.isEmpty) throw CacheException(message: 'User ID cannot be empty');
    return firestore.collection('users').doc(userId).collection('transactions');
  }

  @override
  Stream<List<TransactionModel>> watchAllTransactions(String userId) {
    try {
      return _transactionsRef(userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      throw CacheException(message: 'Failed to watch transactions: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    try {
      final snapshot = await _transactionsRef(userId).orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to fetch transactions: $e');
    }
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    try {
      final id = transaction.id.isEmpty ? _transactionsRef(userId).doc().id : transaction.id;
      await _transactionsRef(userId).doc(id).set(transaction.toFirestore());
    } catch (e) {
      throw CacheException(message: 'Failed to save transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(String userId, TransactionModel transaction) async {
    try {
      await _transactionsRef(userId).doc(transaction.id).update(transaction.toFirestore());
    } catch (e) {
      throw CacheException(message: 'Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String id) async {
    try {
      await _transactionsRef(userId).doc(id).delete();
    } catch (e) {
      throw CacheException(message: 'Failed to delete transaction: $e');
    }
  }
}

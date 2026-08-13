import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';
import '../../../../core/constants/app_constants.dart';

abstract class DebtRemoteDataSource {
  Stream<List<DebtModel>> watchDebts(String userId);
  Future<List<DebtModel>> getDebts(String userId);
  Future<void> addDebt(DebtModel debt);
  Future<void> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String userId, String debtId);
}

class DebtRemoteDataSourceImpl implements DebtRemoteDataSource {
  final FirebaseFirestore firestore;

  DebtRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<DebtModel>> watchDebts(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('debts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DebtModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<List<DebtModel>> getDebts(String userId) async {
    if (userId.isEmpty) return [];

    final snapshot = await firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('debts')
        .get();

    return snapshot.docs
        .map((doc) => DebtModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    if (debt.userId.isEmpty) return;

    await firestore
        .collection(AppConstants.usersCollection)
        .doc(debt.userId)
        .collection('debts')
        .doc(debt.id)
        .set(debt.toMap());
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    if (debt.userId.isEmpty) return;

    await firestore
        .collection(AppConstants.usersCollection)
        .doc(debt.userId)
        .collection('debts')
        .doc(debt.id)
        .update(debt.toMap());
  }

  @override
  Future<void> deleteDebt(String userId, String debtId) async {
    if (userId.isEmpty) return;

    await firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('debts')
        .doc(debtId)
        .delete();
  }
}

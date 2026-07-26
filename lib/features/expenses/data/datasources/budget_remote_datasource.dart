import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<void> saveBudget(String userId, CategoryBudgetModel budget);
  Stream<List<CategoryBudgetModel>> watchBudgetsForMonth(String userId, String monthYear);
  Future<void> deleteBudget(String userId, String budgetId);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseFirestore firestore;

  BudgetRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> saveBudget(String userId, CategoryBudgetModel budget) async {
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id.isEmpty ? null : budget.id);

    final data = budget.toFirestore();
    await docRef.set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<CategoryBudgetModel>> watchBudgetsForMonth(String userId, String monthYear) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .where('monthYear', isEqualTo: monthYear)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryBudgetModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }
}

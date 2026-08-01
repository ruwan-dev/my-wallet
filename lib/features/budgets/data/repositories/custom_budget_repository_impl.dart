import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/custom_budget.dart';
import '../../domain/repositories/custom_budget_repository.dart';
import '../models/custom_budget_model.dart';

class CustomBudgetRepositoryImpl implements CustomBudgetRepository {
  final FirebaseFirestore _firestore;

  CustomBudgetRepositoryImpl(this._firestore);

  @override
  Stream<Either<Failure, List<CustomBudgetEntity>>> watchCustomBudgets(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_budgets')
          .snapshots()
          .map((snapshot) {
        final budgets = snapshot.docs.map((doc) => CustomBudgetModel.fromFirestore(doc)).toList();
        budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Right<Failure, List<CustomBudgetEntity>>(budgets);
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(message: e.toString())));
    }
  }

  @override
  Future<Either<Failure, CustomBudgetEntity>> saveCustomBudget(CustomBudgetEntity budget) async {
    try {
      final model = CustomBudgetModel.fromEntity(budget);
      
      if (budget.id.isEmpty) {
        final docRef = await _firestore.collection('users').doc(budget.userId).collection('custom_budgets').add(model.toFirestore());
        return Right(model.copyWith(id: docRef.id) as CustomBudgetEntity);
      } else {
        await _firestore.collection('users').doc(budget.userId).collection('custom_budgets').doc(budget.id).update(model.toFirestore());
        return Right(model);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomBudget(String userId, String budgetId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('custom_budgets').doc(budgetId).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

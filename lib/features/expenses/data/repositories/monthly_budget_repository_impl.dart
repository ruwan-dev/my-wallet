import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/monthly_budget_repository.dart';
import '../models/monthly_budget_model.dart';

class MonthlyBudgetRepositoryImpl implements MonthlyBudgetRepository {
  final FirebaseFirestore _firestore;

  MonthlyBudgetRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, MonthlyBudgetEntity?>> getMonthlyBudget(String userId, int month, int year) async {
    try {
      final querySnapshot = await _firestore
          .collection('monthly_budgets')
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }

      final model = MonthlyBudgetModel.fromFirestore(querySnapshot.docs.first);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlyBudgetEntity>> saveMonthlyBudget(MonthlyBudgetEntity budget) async {
    try {
      final model = MonthlyBudgetModel.fromEntity(budget);
      
      if (budget.id.isEmpty) {
        // Create new
        final docRef = await _firestore.collection('monthly_budgets').add(model.toFirestore());
        return Right(model.copyWith(id: docRef.id));
      } else {
        // Update existing
        await _firestore.collection('monthly_budgets').doc(budget.id).update(model.toFirestore());
        return Right(model);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/custom_budget.dart';

abstract class CustomBudgetRepository {
  Stream<Either<Failure, List<CustomBudgetEntity>>> watchCustomBudgets(String userId);
  Future<Either<Failure, CustomBudgetEntity>> saveCustomBudget(CustomBudgetEntity budget);
  Future<Either<Failure, void>> deleteCustomBudget(String userId, String budgetId);
}

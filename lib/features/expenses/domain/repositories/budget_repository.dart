import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/category_budget.dart';

abstract class BudgetRepository {
  Stream<Either<Failure, List<CategoryBudgetEntity>>> watchBudgetsForMonth(String userId, String monthYear);
  Future<Either<Failure, void>> saveBudget(String userId, CategoryBudgetEntity budget);
  Future<Either<Failure, void>> deleteBudget(String userId, String budgetId);
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/monthly_budget.dart';

abstract class MonthlyBudgetRepository {
  Future<Either<Failure, MonthlyBudgetEntity?>> getMonthlyBudget(String userId, int month, int year);
  Future<Either<Failure, MonthlyBudgetEntity>> saveMonthlyBudget(MonthlyBudgetEntity budget);
}

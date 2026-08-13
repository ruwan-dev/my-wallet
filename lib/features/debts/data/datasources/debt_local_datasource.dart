import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt_model.dart';
import '../../../../core/constants/app_constants.dart';

abstract class DebtLocalDataSource {
  Stream<List<DebtModel>> watchDebts();
  Future<List<DebtModel>> getDebts();
  Future<void> addDebt(DebtModel debt);
  Future<void> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
  Future<void> clearDebts();
}

class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  final Box<DebtModel> box;

  DebtLocalDataSourceImpl({required this.box});

  @override
  Stream<List<DebtModel>> watchDebts() async* {
    yield box.values.toList();
    yield* box.watch().map((event) => box.values.toList());
  }

  @override
  Future<List<DebtModel>> getDebts() async {
    return box.values.toList();
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    await box.put(debt.id, debt);
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    await box.put(debt.id, debt);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await box.delete(id);
  }

  @override
  Future<void> clearDebts() async {
    await box.clear();
  }
}

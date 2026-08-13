import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_datasource.dart';
import '../datasources/debt_remote_datasource.dart';
import '../models/debt_model.dart';
import 'dart:async';

class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDataSource localDataSource;
  final DebtRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  DebtRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  Future<bool> _isConnected() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<List<Debt>> watchDebts(String userId) async* {
    if (userId.isEmpty) {
      yield [];
      return;
    }

    if (await _isConnected()) {
      try {
        final remoteDebts = await remoteDataSource.getDebts(userId);
        await localDataSource.clearDebts();
        for (var debt in remoteDebts) {
          await localDataSource.addDebt(debt);
        }
      } catch (e) {
        // Fallback to local
      }
    }

    // Yield from local database for reactivity
    yield* localDataSource.watchDebts().map((models) {
      return models.where((m) => m.userId == userId).toList();
    });
  }

  @override
  Future<void> addDebt(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    await localDataSource.addDebt(model);

    if (await _isConnected()) {
      try {
        await remoteDataSource.addDebt(model);
      } catch (e) {
        // Will sync later
      }
    }
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    await localDataSource.updateDebt(model);

    if (await _isConnected()) {
      try {
        await remoteDataSource.updateDebt(model);
      } catch (e) {
        // Will sync later
      }
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    final debts = await localDataSource.getDebts();
    
    // Find the debt safely
    DebtModel? debt;
    try {
      debt = debts.firstWhere((d) => d.id == id);
    } catch (e) {
      // Not found
    }
    
    await localDataSource.deleteDebt(id);

    if (await _isConnected() && debt != null) {
      try {
        await remoteDataSource.deleteDebt(debt.userId, id);
      } catch (e) {
        // Will sync later
      }
    }
  }
}

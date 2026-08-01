import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/add_account.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/watch_accounts.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final WatchAccountsUseCase _watchAccounts;
  final AddAccountUseCase _addAccount;
  final UpdateAccountUseCase _updateAccount;
  final DeleteAccountUseCase _deleteAccount;
  final AuthRepository _authRepository;

  StreamSubscription? _subscription;

  String get _currentUserId {
    final uid = _authRepository.getCurrentUserId();
    if (uid == null || uid.isEmpty) {
      throw Exception('Unauthenticated: Cannot access accounts.');
    }
    return uid;
  }

  AccountCubit({
    required WatchAccountsUseCase watchAccounts,
    required AddAccountUseCase addAccount,
    required UpdateAccountUseCase updateAccount,
    required DeleteAccountUseCase deleteAccount,
    required AuthRepository authRepository,
  })  : _watchAccounts = watchAccounts,
        _addAccount    = addAccount,
        _updateAccount = updateAccount,
        _deleteAccount = deleteAccount,
        _authRepository = authRepository,
        super(AccountInitial());

  void loadAccounts() {
    emit(AccountLoading());
    
    _subscription?.cancel();
    _subscription = _watchAccounts(_currentUserId).listen(
      (failureOrAccounts) {
        failureOrAccounts.fold(
          (failure) => emit(AccountError(failure.message)),
          (accounts) {
            emit(AccountLoaded(accounts: accounts));
          },
        );
      },
      onError: (error) {
        emit(AccountError('Stream error: $error'));
      },
    );
  }


  Future<void> addAccount(AccountEntity account) async {
    final accountWithUser = account.copyWith(userId: _currentUserId);
    final result = await _addAccount(accountWithUser);
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) {},
    );
  }

  Future<void> updateAccount(AccountEntity account) async {
    final accountWithUser = account.copyWith(userId: _currentUserId);
    final result = await _updateAccount(accountWithUser);
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) {}, // The stream will handle the success
    );
  }

  Future<void> deleteAccount(String accountId) async {
    if (state is AccountLoaded) {
      final loadedState = state as AccountLoaded;
      final updatedList = loadedState.accounts.where((a) => a.id != accountId).toList();
      emit(AccountLoaded(accounts: updatedList));
    }
    
    final result = await _deleteAccount(DeleteAccountParams(userId: _currentUserId, accountId: accountId));
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) {}, // The stream will handle the success
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

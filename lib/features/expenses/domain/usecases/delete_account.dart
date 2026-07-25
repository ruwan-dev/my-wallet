import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/account_repository.dart';

class DeleteAccountParams {
  final String userId;
  final String accountId;

  DeleteAccountParams({required this.userId, required this.accountId});
}

class DeleteAccountUseCase implements UseCase<void, DeleteAccountParams> {
  final AccountRepository repository;

  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    return await repository.deleteAccount(params.userId, params.accountId);
  }
}

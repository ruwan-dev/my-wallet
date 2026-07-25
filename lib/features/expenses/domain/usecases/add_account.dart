import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class AddAccountUseCase implements UseCase<AccountEntity, AccountEntity> {
  final AccountRepository repository;
  final _uuid = const Uuid();

  AddAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AccountEntity>> call(AccountEntity params) async {
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Account name cannot be empty'));
    }

    final account = params.copyWith(
      id: _uuid.v4(),
    );

    return repository.addAccount(account);
  }
}

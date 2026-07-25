import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use-case contract.
///
/// [Type]   – the return type on success.
/// [Params] – the input parameters.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Marker class for use-cases that require no parameters.
class NoParams {
  const NoParams();
}

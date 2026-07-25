import 'package:equatable/equatable.dart';

/// Base failure class for domain layer error handling.
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Failures originating from the server / Firebase.
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Failures due to no internet / network issues.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Failures from local cache / Hive storage.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failures related to authentication.
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Failures caused by invalid user input.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Unexpected / unknown failures.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message});
}

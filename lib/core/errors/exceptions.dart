/// Base exception class for data-layer errors.
abstract class AppException implements Exception {
  final String message;
  const AppException({required this.message});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a remote API / Firebase call fails.
class ServerException extends AppException {
  const ServerException({required super.message});
}

/// Thrown when there is no internet connectivity.
class NetworkException extends AppException {
  const NetworkException({required super.message});
}

/// Thrown when reading from or writing to local cache fails.
class CacheException extends AppException {
  const CacheException({required super.message});
}

/// Thrown when an authentication operation fails.
class AuthException extends AppException {
  const AuthException({required super.message});
}

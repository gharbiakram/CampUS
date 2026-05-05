/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;

  AppException({required this.message});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required String message,
    this.statusCode,
  }) : super(message: message);

  final int? statusCode;
}

/// Storage-related exceptions
class StorageException extends AppException {
  StorageException({required String message}) : super(message: message);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  PermissionException({required String message}) : super(message: message);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException({required String message}) : super(message: message);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  ValidationException({required String message}) : super(message: message);
}

/// Database-related exceptions
class DatabaseException extends AppException {
  DatabaseException({required String message}) : super(message: message);
}

/// Generic/Unknown exceptions
class UnknownException extends AppException {
  UnknownException({required String message}) : super(message: message);
}

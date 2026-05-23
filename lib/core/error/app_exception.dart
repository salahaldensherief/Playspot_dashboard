class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message ${code != null ? '($code)' : ''}';
}

class ServerException extends AppException {
  ServerException(super.message, [super.code]);
}

class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

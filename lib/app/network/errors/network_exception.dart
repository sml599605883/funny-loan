class NetworkException implements Exception {
  const NetworkException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => 'NetworkException(code: $code, message: $message)';
}

class AuthExpiredException extends NetworkException {
  const AuthExpiredException(super.message, {super.code});
}

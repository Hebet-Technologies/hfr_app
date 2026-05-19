class AppException implements Exception {
  AppException([this._message, this._prefix]);

  final String? _message;
  final String? _prefix;

  @override
  String toString() {
    return '${_prefix ?? ''}${_message ?? ''}';
  }
}

class ExceptionHandling extends AppException {
  ExceptionHandling([String? message]) : super(message, 'Oops! : ');
}

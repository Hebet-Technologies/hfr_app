String friendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final raw = error.toString().trim();
  if (raw.isEmpty) return fallback;

  var message = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^DioException \[[^\]]+\]:\s*'), '')
      .trim();

  if (_looksLikeTimeout(message)) {
    return 'The server took too long to respond. Please retry.';
  }

  if (_looksLikeBackendTrace(message)) {
    return fallback;
  }

  final firstLine = message.split(RegExp(r'[\r\n]')).first.trim();
  if (firstLine.isEmpty) return fallback;
  if (_looksLikeBackendTrace(firstLine)) return fallback;

  const maxLength = 180;
  if (firstLine.length <= maxLength) return firstLine;
  return '${firstLine.substring(0, maxLength).trimRight()}...';
}

String listLoadErrorMessage(Object error) {
  return friendlyErrorMessage(
    error,
    fallback: 'We could not load this list right now. Please try again.',
  );
}

bool _looksLikeBackendTrace(String message) {
  final lower = message.toLowerCase();
  return lower.contains('sqlstate') ||
      lower.contains('queryexception') ||
      lower.contains('illuminate\\') ||
      lower.contains('vendor/laravel') ||
      lower.contains('connection.php') ||
      lower.contains('stack trace') ||
      lower.contains('context:') ||
      lower.contains('unnamed portal parameter') ||
      lower.contains('response={') ||
      lower.contains('trace:') ||
      lower.contains('bad response') ||
      lower.contains('status code of 500') ||
      lower.contains('status code of 502') ||
      lower.contains('status code of 503') ||
      lower.contains('status code of 504') ||
      lower.contains('input of anonymous composite types') ||
      lower.contains('(connection: pgsql') ||
      lower.contains('/var/www/');
}

bool _looksLikeTimeout(String message) {
  final lower = message.toLowerCase();
  return lower.contains('receivetimeout') ||
      lower.contains('connectiontimeout') ||
      lower.contains('sendtimeout') ||
      lower.contains('request took longer') ||
      lower.contains('receive data') && lower.contains('aborted') ||
      lower.contains('timed out');
}

class AppException implements Exception{

  AppException([this._message, this._prefix]);
  final _message;
  final _prefix;

  @override
  String toString(){
    return "$_prefix$_message";
  }
}

class ExceptionHandling extends AppException{
  ExceptionHandling([String? message]):super(message, "Oops! : ");
}
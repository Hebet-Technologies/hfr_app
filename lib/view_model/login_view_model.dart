import 'package:flutter/cupertino.dart';

import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../utils/routes/routes_name.dart';
import '../utils/utils.dart';

import 'user_view_model.dart';

class LoginViewModel with ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  bool _isLoading = false;
  bool _isSecured = true;

  String _email = '';
  String _password = '';

  UserModel? _user;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  UserModel? get user => _user;

  bool get isLoading => _isLoading;
  bool get isSecured => _isSecured;

  String get email => _email;
  String get password => _password;

  FocusNode get emailFocusNode => _emailFocusNode;
  FocusNode get passwordFocusNode => _passwordFocusNode;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void setSecure(bool val) {
    _isSecured = val;
    notifyListeners();
  }

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  set password(String value) {
    _password = value;
    notifyListeners();
  }

  Future<void> loginApi(
    BuildContext context,
    UserViewModel userViewModel,
  ) async {
    Map data = {'email': _email, 'password': _password};

    setLoading(true);

    _authRepository
        .loginApi(data)
        .then((value) async {
          setLoading(false);

          if (value['statusCode'] == 401) {
            if (!context.mounted) return;
            Utils.flushBar("Incorrect email or password", context, "warning");
          } else {
            await userViewModel.saveUser(
              value["data"]['token'],
              _email,
              _password,
            );

            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.home,
              (route) => false,
            );
          }
        })
        .onError((error, stackTrace) {
          setLoading(false);

          if (!context.mounted) return;
          Utils.flushBar(error.toString(), context, "error");
        });
  }
}

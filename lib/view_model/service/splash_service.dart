import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../utils/routes/routes_name.dart';
import '../../view_model/user_view_model.dart';

class SplashService{
  void checkUserAuth(BuildContext context) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.getUserToken();
    if (userViewModel.userToken == "") {
      Navigator.pushNamedAndRemoveUntil(context, RoutesName.login, (route) => false);
    } else {
      userViewModel.loginApi(context);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:staffportal/utils/routes/routes_name.dart';
import '../../view/home_view.dart';
import '../../view/auth/login_view.dart';
import '../../view/auth/splash_view.dart';

class Routes{

  static Route<dynamic> generateRoute(RouteSettings setting){

    switch(setting.name){

      case RoutesName.login:
        return MaterialPageRoute(builder: (BuildContext context) => LoginView());

      case RoutesName.splash:
        return MaterialPageRoute(builder: (BuildContext context) => const SplashView());

      case RoutesName.home:
        return MaterialPageRoute(builder: (BuildContext context) => const HomeView());

      default:
        return MaterialPageRoute(builder: (_){
          return const Scaffold(
            body: Center(
              child: Text("No Route Defined"),
            ),
          );
        });
    }
  }
}
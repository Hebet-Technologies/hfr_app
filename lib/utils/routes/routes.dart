import 'package:flutter/material.dart';
import 'package:staffportal/utils/routes/routes_name.dart';
import '../../view/main_navigation.dart';
import '../../view/training/training_screen.dart';
import '../../view/tasks_screen.dart';
import '../../view/profile/profile_screen.dart';
import '../../view/auth/intro_screen.dart';
import '../../view/auth/login_screen.dart';
import '../../view/auth/registration_screen.dart';
import '../../view/auth/splash_view.dart';
import '../../view/auth/forgot_password_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings setting) {
    switch (setting.name) {
      case RoutesName.intro:
        return MaterialPageRoute(
          builder: (BuildContext context) => const IntroScreen(),
        );

      case RoutesName.login:
        return MaterialPageRoute(
          builder: (BuildContext context) => const LoginScreen(),
        );

      case RoutesName.register:
        return MaterialPageRoute(
          builder: (BuildContext context) => const RegistrationScreen(),
        );

      case RoutesName.splash:
        return MaterialPageRoute(
          builder: (BuildContext context) => const SplashView(),
        );

      case RoutesName.home:
        return MaterialPageRoute(
          builder: (BuildContext context) => const MainNavigation(),
        );

      case RoutesName.forgotPassword:
        return MaterialPageRoute(
          builder: (BuildContext context) => const ForgotPasswordScreen(),
        );

      case RoutesName.profile:
        return MaterialPageRoute(
          builder: (BuildContext context) => const ProfileScreen(),
        );

      case RoutesName.attendance:
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              const TrainingScreen(standalone: true),
        );

      case RoutesName.tasks:
        return MaterialPageRoute(
          builder: (BuildContext context) => const TasksScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) {
            return const Scaffold(
              body: Center(child: Text("No Route Defined")),
            );
          },
        );
    }
  }
}

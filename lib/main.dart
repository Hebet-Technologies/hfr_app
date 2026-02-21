import 'package:flutter/material.dart';
import 'package:staffportal/view_model/login_view_model.dart';
import 'package:staffportal/utils/routes/routes.dart';
import 'package:staffportal/utils/routes/routes_name.dart';
import 'package:staffportal/view_model/user_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel())
      ],
      child:const MaterialApp(
            initialRoute: RoutesName.splash,
            onGenerateRoute: Routes.generateRoute,
          )
    );
  }
}

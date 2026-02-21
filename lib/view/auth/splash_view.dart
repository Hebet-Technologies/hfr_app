import 'package:flutter/material.dart';
import 'package:staffportal/utils/colors.dart';
import 'package:staffportal/widget/button_widget.dart';
import 'package:provider/provider.dart';
import '../../view_model/service/splash_service.dart';
import '../../view_model/user_view_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {

  SplashService splashService = SplashService();

  @override
  void initState() {
    splashService.checkUserAuth(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserViewModel>(builder: (context, userModel, child){
        return Center(
            child: userModel.isLoading
              ? const CircularProgressIndicator()
              : userModel.msg == "error"
              ? SizedBox(
                height: 100,
                child: Column(
                  children: [
                    const Text("No Internet Connection"),
                    const SizedBox(height: 10,),
                    SizedBox(
                      width: 100,
                      child: ButtonWidget(
                          title: "Retry",
                          color: blueAccent,
                          textColor: white,
                          onPressed: ()=> userModel.loginApi(context)
                      ),
                    )
                  ],
                ),
              ): const CircularProgressIndicator(),
        );
      })
    );
  }
}

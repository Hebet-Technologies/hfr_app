import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widget/button_widget.dart';
import '../../view_model/login_view_model.dart';
import '../../utils/colors.dart';
import '../../utils/utils.dart';

class LoginView extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return PopScope(
        canPop: false,
        onPopInvoked: (bool shouldPop){
          SystemNavigator.pop();
        },
        child: Scaffold(
        resizeToAvoidBottomInset: true,
        body:Stack(
            alignment: Alignment.center,
            children: [
              ListView(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png', fit: BoxFit.contain,
                      ),
                      Container(
                        height: width - 100,
                        color: blue.withOpacity(0.9),
                      ),
                      // Add other children here if needed
                    ],
                  ),
                  Container(
                    height: height - width + 100,
                    color: white,
                  ),
                ],
              ),
              Align(
                  alignment: Alignment.center,
                  child:SizedBox(
                    height: 500,
                    child: ListView(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 440,
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom:20),
                              child: Card(
                                elevation: 20,
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Form(
                                        key: _formKey,
                                        child:Column(
                                          children: [
                                            const SizedBox(height: 30),
                                            const Text(
                                              'MoHZ',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Ministry of Health Zanzibar',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 20),
                                            Consumer<LoginViewModel>(builder: (context, value, child){
                                              return TextFormField(
                                                focusNode: value.emailFocusNode,
                                                decoration: Utils.getDecoration(
                                                    labelText: "Enter Your Email",
                                                    hintText: "Email Address",
                                                    decorationColor: blue,
                                                    prefixIcon: Icons.email
                                                ),
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) {
                                                    return 'Please enter some text';
                                                  }
                                                  value.email = val;
                                                  return null;
                                                },
                                                onFieldSubmitted: (val){
                                                  Utils.fieldFocusScope(context, value.emailFocusNode, value.passwordFocusNode);
                                                },
                                              );
                                            }),
                                            const SizedBox(height: 16),
                                            Consumer<LoginViewModel>(builder: (context, value, child){
                                              return TextFormField(
                                                focusNode: value.passwordFocusNode,
                                                obscureText: value.isSecured,
                                                decoration: Utils.getDecoration(
                                                    labelText: "Enter Your Password",
                                                    hintText: "Password",
                                                    decorationColor: blue,
                                                    prefixIcon: Icons.lock_clock_outlined,
                                                    suffixIcon: value.isSecured?Icons.visibility_off:Icons.visibility,
                                                    onSuffixClicked:()=> value.isSecured?value.setSecure(false):value.setSecure(true)
                                                ),
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) {
                                                    return 'Please enter your password';
                                                  }
                                                  value.password = val;
                                                  return null;
                                                },
                                              );
                                            }),
                                          ],
                                        ))),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: white,
                                child: Image.asset('assets/images/logo.png', height: 50,), // Ensure you have the logo image in your assets
                              ),
                            ),
                            Positioned(
                                bottom: 0,
                                left: 32,
                                right: 32,
                                child: Consumer<LoginViewModel>(builder: (context, value, child){
                                  return ButtonWidget(
                                      title: "login",
                                      color: blue,
                                      textColor: white,
                                      isLoading: value.isLoading,
                                      onPressed: () {
                                        if (_formKey.currentState!.validate() && !value.isLoading) {
                                          value.loginApi(context);
                                        }
                                      }
                                  );
                                })
                            )
                          ],
                        ),
                      ],
                    ),
                  ))
            ]
        )
    )
    );
  }
}





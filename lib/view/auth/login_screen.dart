import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/routes/routes_name.dart';
import '../../utils/validators.dart';
import '../../view_model/providers.dart';
import 'auth_styles.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  // final _emailController = TextEditingController(
  //   text: 'abdalla.khamis@mohz.go.tz',
  // );
  // final _passwordController = TextEditingController(text: 'Abdalla@2026');
  final _emailController = TextEditingController(text: 'samira.ali@mohz.go.tz');
  final _passwordController = TextEditingController(text: 'Samira@2026');
  // final _emailController = TextEditingController(text: 'info@mohz.go.tz');
  // final _passwordController = TextEditingController(text: '@dm1n@m0hz#321');
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = ref.read(authViewModelProvider.notifier);

      final success = await authViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, RoutesName.home);
      } else {
        Flushbar(
          message:
              ref.read(authViewModelProvider).errorMessage ?? 'Login failed',
          backgroundColor: const Color(0xFFE53935),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                authHeaderSection(
                  title: 'Login to your account',
                  subtitle: 'Enter your details to login.',
                ),
                const SizedBox(height: 24),
                authLabeledField(
                  label: 'Email Address',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: Validators.validateEmail,
                  ),
                ),
                authLabeledField(
                  label: 'Password',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: authIconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: authPrimary,
                            side: const BorderSide(color: authBorder),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Keep me logged in',
                          style: authTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, RoutesName.forgotPassword);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: authTextSecondary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: authUnderlineLinkStyle(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: authPrimaryButtonStyle(),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: authTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: authTextSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: authPrimary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Register',
                        style: authUnderlineLinkStyle(color: authPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

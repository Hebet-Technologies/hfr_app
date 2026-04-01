import 'package:flutter/material.dart';
import '../../utils/validators.dart';
import 'auth_styles.dart';
import 'verify_personal_info_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'Male';

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToVerification() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPersonalInfoScreen(
            firstName: _firstNameController.text.trim(),
            middleName: _middleNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            gender: _selectedGender,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: authAppBar(context: context, title: 'Create Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                authHeaderSection(
                  title: 'Create your account',
                  subtitle: 'Enter your details to register.',
                ),
                const SizedBox(height: 24),
                authLabeledField(
                  label: 'First Name',
                  child: TextFormField(
                    controller: _firstNameController,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter first name',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: Validators.validateRequired,
                  ),
                ),
                authLabeledField(
                  label: 'Middle Name',
                  child: TextFormField(
                    controller: _middleNameController,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter middle name',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: Validators.validateRequired,
                  ),
                ),
                authLabeledField(
                  label: 'Last Name',
                  child: TextFormField(
                    controller: _lastNameController,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter last name',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: Validators.validateRequired,
                  ),
                ),
                authLabeledField(
                  label: 'Gender',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    iconEnabledColor: authIconColor,
                    decoration: authInputDecoration(
                      hintText: 'Select gender',
                      prefixIcon: Icons.wc,
                    ),
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: authTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue!;
                      });
                    },
                  ),
                ),
                authLabeledField(
                  label: 'Phone Number',
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                    ),
                    validator: Validators.validatePhone,
                  ),
                ),
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
                    validator: Validators.validateGovernmentEmail,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Use an approved government email such as @mohz.go.tz.',
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: authTextSecondary,
                    ),
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
                      hintText: 'Create a password',
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
                authLabeledField(
                  label: 'Confirm Password',
                  margin: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Confirm your password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: authIconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _navigateToVerification,
                  style: authPrimaryButtonStyle(),
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: authTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: authTextSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: authPrimary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
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

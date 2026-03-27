import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:another_flushbar/flushbar.dart';
import '../../model/registration_model.dart';
import '../../view_model/providers.dart';

class VerifyPersonalInfoScreen extends ConsumerStatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String gender;

  const VerifyPersonalInfoScreen({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.gender,
  });

  @override
  ConsumerState<VerifyPersonalInfoScreen> createState() =>
      _VerifyPersonalInfoScreenState();
}

class _VerifyPersonalInfoScreenState
    extends ConsumerState<VerifyPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payrollController = TextEditingController();
  final _dobController = TextEditingController();

  Map<String, dynamic>? _personalInfo;
  bool _isVerified = false;

  @override
  void dispose() {
    _payrollController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _verifyPersonalInfo() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = ref.read(authViewModelProvider.notifier);

      final result = await authViewModel.getPersonalInfo(
        _payrollController.text.trim(),
        _dobController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _personalInfo = result;
          _isVerified = true;
        });

        Flushbar(
          message: 'Personal information verified successfully',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ).show(context);
      } else {
        Flushbar(
          message: ref.read(authViewModelProvider).errorMessage ??
              'Verification failed',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ).show(context);
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (_personalInfo == null) return;

    final authViewModel = ref.read(authViewModelProvider.notifier);

    final registrationModel = RegistrationModel(
      firstName: widget.firstName,
      middleName: widget.middleName,
      lastName: widget.lastName,
      locationId: _personalInfo!['location_id'] ?? '',
      gender: widget.gender,
      phoneNo: widget.phone,
      dateOfBirth: _dobController.text.trim(),
      email: widget.email,
      password: widget.password,
      workingStationId: _personalInfo!['working_station_id'] ?? '',
      personalInformationId: _personalInfo!['personal_information_id'] ?? '',
      pathId: _personalInfo!['path_id'] ?? '',
    );

    final success = await authViewModel.register(registrationModel);

    if (!mounted) return;

    if (success) {
      Flushbar(
        message: 'Registration successful! Please login.',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ).show(context);

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      Flushbar(
        message: ref.read(authViewModelProvider).errorMessage ??
            'Registration failed',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Personal Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Text(
                  'Verify Your Identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your payroll number and date of birth to verify',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _payrollController,
                  decoration: InputDecoration(
                    labelText: 'Payroll Number',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your payroll number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your date of birth';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: authState.isLoading || _isVerified
                      ? null
                      : _verifyPersonalInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                      : Text(
                          _isVerified ? 'Verified' : 'Verify',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                if (_isVerified) ...[
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

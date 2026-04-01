import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/registration_model.dart';
import '../../view_model/providers.dart';
import 'auth_styles.dart';

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
  List<Map<String, dynamic>> _pathOptions = const [];
  String? _selectedPathId;
  bool _isVerified = false;

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  void dispose() {
    _payrollController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _verifyPersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final result = await authViewModel.getPersonalInfo(
      _payrollController.text.trim(),
      _dobController.text.trim(),
    );

    if (!mounted) return;
    if (result == null) {
      _showError(
        ref.read(authViewModelProvider).errorMessage ?? 'Verification failed',
      );
      return;
    }

    final personalInfo = _extractPersonalInfo(result);
    final pathOptions = _extractPathOptions(result);

    if (personalInfo == null) {
      _showError('Verification response is missing staff information.');
      return;
    }
    if (pathOptions.isEmpty) {
      _showError('No approval path was found for this staff profile.');
      return;
    }

    setState(() {
      _personalInfo = personalInfo;
      _pathOptions = pathOptions;
      _selectedPathId = pathOptions.length == 1
          ? _asString(pathOptions.first['leave_path_id'])
          : null;
      _isVerified = true;
    });

    Flushbar(
      message: 'Personal information verified successfully',
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ).show(context);
  }

  Future<void> _completeRegistration() async {
    if (_personalInfo == null) return;
    if ((_selectedPathId ?? '').trim().isEmpty) {
      _showError('Select the approval path linked to this staff profile.');
      return;
    }

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final verifiedDateOfBirth = _asString(_personalInfo!['date_of_birth']);

    final registrationModel = RegistrationModel(
      firstName: widget.firstName,
      middleName: widget.middleName,
      lastName: widget.lastName,
      locationId: _asString(_personalInfo!['location_id']),
      gender: widget.gender,
      phoneNo: widget.phone,
      dateOfBirth: verifiedDateOfBirth.isNotEmpty
          ? verifiedDateOfBirth
          : _dobController.text.trim(),
      email: widget.email,
      password: widget.password,
      workingStationId: _asString(_personalInfo!['working_station_id']),
      personalInformationId: _asString(
        _personalInfo!['personal_information_id'],
      ),
      pathId: _selectedPathId!,
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
      return;
    }

    _showError(
      ref.read(authViewModelProvider).errorMessage ?? 'Registration failed',
    );
  }

  Map<String, dynamic>? _extractPersonalInfo(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<Map<String, dynamic>> _extractPathOptions(Map<String, dynamic> result) {
    final rawPaths = result['path'];
    if (rawPaths is List) {
      return rawPaths
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (rawPaths is Map) {
      return [Map<String, dynamic>.from(rawPaths)];
    }
    return const [];
  }

  String _verifiedName(Map<String, dynamic> info) {
    final parts = [
      _asString(info['first_name']),
      _asString(info['middle_name']),
      _asString(info['last_name']),
    ].where((value) => value.trim().isNotEmpty);
    return parts.join(' ');
  }

  void _showError(String message) {
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: authAppBar(
        context: context,
        title: 'Verify Personal Information',
      ),
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
                  icon: Icons.verified_user_outlined,
                  title: 'Verify your identity',
                  subtitle:
                      'Enter your payroll number and date of birth to verify.',
                ),
                const SizedBox(height: 24),
                authLabeledField(
                  label: 'Payroll Number',
                  child: TextFormField(
                    controller: _payrollController,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'Enter payroll number',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your payroll number';
                      }
                      return null;
                    },
                  ),
                ),
                authLabeledField(
                  label: 'Date of Birth',
                  margin: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _dobController,
                    style: authTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: authInputDecoration(
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading || _isVerified
                      ? null
                      : _verifyPersonalInfo,
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
                      : Text(_isVerified ? 'Verified' : 'Verify'),
                ),
                if (_isVerified) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: authBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Staff Information',
                          style: authTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _verifiedName(_personalInfo!),
                          style: authTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _asString(_personalInfo!['working_station_name']),
                          style: authTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: authTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Payroll: ${_asString(_personalInfo!['payroll'])}',
                          style: authTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: authTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  authLabeledField(
                    label: 'Approval Path',
                    margin: EdgeInsets.zero,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPathId,
                      style: authTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      iconEnabledColor: authIconColor,
                      decoration: authInputDecoration(
                        hintText: 'Select approval path',
                        prefixIcon: Icons.alt_route_rounded,
                      ),
                      items: _pathOptions.map((item) {
                        final pathId = _asString(item['leave_path_id']);
                        final pathName = _asString(item['leave_path_name']);
                        return DropdownMenuItem<String>(
                          value: pathId,
                          child: Text(
                            pathName,
                            style: authTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPathId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : _completeRegistration,
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
                        : const Text('Complete Registration'),
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

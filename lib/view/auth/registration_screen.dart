import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/registration_model.dart';
import '../../utils/routes/routes_name.dart';
import '../../utils/validators.dart';
import '../../view_model/providers.dart';
import 'auth_styles.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _searchFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _payrollController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? _verifiedProfile;
  List<Map<String, dynamic>> _pathOptions = const [];
  String? _selectedPathId;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  DateTime get _maxDate {
    final today = DateTime.now();
    return DateTime(today.year - 17, today.month, today.day);
  }

  @override
  void dispose() {
    _payrollController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final parsedDate = _parseDate(_dobController.text.trim());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: parsedDate ?? _maxDate,
      firstDate: DateTime(1950),
      lastDate: _maxDate,
    );

    if (!mounted || pickedDate == null) return;
    _dobController.text = _formatDate(pickedDate);
  }

  Future<void> _searchEmployee() async {
    if (!_searchFormKey.currentState!.validate()) return;

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final result = await authViewModel.getPersonalInfo(
      _payrollController.text.trim(),
      _dobController.text.trim(),
    );

    if (!mounted) return;
    if (result == null) {
      _showMessage(
        ref.read(authViewModelProvider).errorMessage ??
            'Failed to verify staff information.',
        isError: true,
      );
      return;
    }

    final verifiedProfile = _extractPersonalInfo(result);
    final pathOptions = _extractPathOptions(result);

    if (verifiedProfile == null) {
      _showMessage(
        'Verification response did not include staff information.',
        isError: true,
      );
      return;
    }

    if (pathOptions.isEmpty) {
      _showMessage(
        'No reporting chain was found for this staff profile.',
        isError: true,
      );
      return;
    }

    setState(() {
      _verifiedProfile = verifiedProfile;
      _pathOptions = pathOptions;
      _selectedPathId = pathOptions.length == 1
          ? _asString(pathOptions.first['leave_path_id'])
          : null;
      _emailController.text = _asString(verifiedProfile['email']);
      _passwordController.clear();
      _confirmPasswordController.clear();
    });

    _showMessage('Staff record verified successfully.');
  }

  Future<void> _register() async {
    if (_verifiedProfile == null) {
      _showMessage(
        'Verify staff information before creating an account.',
        isError: true,
      );
      return;
    }
    if (!_registerFormKey.currentState!.validate()) return;
    if ((_selectedPathId ?? '').trim().isEmpty) {
      _showMessage('Select the reporting chain starting point.', isError: true);
      return;
    }

    final profile = _verifiedProfile!;
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final registration = RegistrationModel(
      firstName: _asString(profile['first_name']),
      middleName: _asString(profile['middle_name']),
      lastName: _asString(profile['last_name']),
      surName: _asString(profile['sur_name']),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      pathId: _selectedPathId!,
      locationId: _asString(profile['location_id']),
      gender: _asString(profile['gender']),
      phoneNo: _asString(profile['phone_no']),
      dateOfBirth: _asString(profile['date_of_birth']).isNotEmpty
          ? _asString(profile['date_of_birth'])
          : _dobController.text.trim(),
      transferPathId: _asString(profile['transfer_path_id']),
      trainingPathId: _asString(profile['training_path_id']),
      workingStationId: _asString(profile['working_station_id']),
      workingStationName: _asString(profile['working_station_name']),
      personalInformationId: _asString(profile['personal_information_id']),
    );

    final success = await authViewModel.register(registration);

    if (!mounted) return;
    if (!success) {
      _showMessage(
        ref.read(authViewModelProvider).errorMessage ?? 'Registration failed.',
        isError: true,
      );
      return;
    }

    _showMessage('Account created successfully.');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RoutesName.login);
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
    final paths = result['path'];
    if (paths is List) {
      return paths
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (paths is Map) {
      return [Map<String, dynamic>.from(paths)];
    }
    return const [];
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _pathLabel(Map<String, dynamic> path) {
    final label = _asString(path['leave_path_name']);
    return label.isNotEmpty ? label : 'Approval path';
  }

  void _showMessage(String message, {bool isError = false}) {
    Flushbar(
      message: message,
      backgroundColor: isError ? const Color(0xFFE53935) : Colors.green,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  Widget _buildSectionCard({
    required String step,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: authTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: authPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: authTextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: authTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: authTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return authLabeledField(
      label: label,
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: authTextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        decoration: authInputDecoration(hintText: '', prefixIcon: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final verifiedProfile = _verifiedProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: authAppBar(context: context, title: 'Create Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              authHeaderSection(
                title: 'Create your account',
                subtitle:
                    'Verify your staff record first, then complete your account setup.',
              ),
              const SizedBox(height: 24),
              Form(
                key: _searchFormKey,
                child: _buildSectionCard(
                  step: 'Step 1',
                  title: 'Verify Staff Record',
                  subtitle:
                      'Use the same payroll number and date of birth required by the web portal.',
                  child: Column(
                    children: [
                      authLabeledField(
                        label: 'Payroll Number',
                        child: TextFormField(
                          controller: _payrollController,
                          keyboardType: TextInputType.number,
                          style: authTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: authInputDecoration(
                            hintText: 'Enter payroll number',
                            prefixIcon: Icons.badge_outlined,
                          ),
                          validator: Validators.validateRequired,
                        ),
                      ),
                      authLabeledField(
                        label: 'Date of Birth',
                        margin: EdgeInsets.zero,
                        child: TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: _pickDateOfBirth,
                          style: authTextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: authInputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icons.calendar_today_outlined,
                          ),
                          validator: Validators.validateRequired,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : _searchEmployee,
                          style: authPrimaryButtonStyle(),
                          child: authState.isLoading && verifiedProfile == null
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
                                  verifiedProfile == null
                                      ? 'Search'
                                      : 'Search Again',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (verifiedProfile != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFBF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1B8A4A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Verified: ${[_asString(verifiedProfile['first_name']), _asString(verifiedProfile['middle_name']), _asString(verifiedProfile['last_name'])].where((item) => item.isNotEmpty).join(' ')}',
                          style: authTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E37),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Form(
                  key: _registerFormKey,
                  child: _buildSectionCard(
                    step: 'Step 2',
                    title: 'Complete Registration',
                    subtitle:
                        'This matches the web signup flow: readonly staff data, organization email, reporting path, and password.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '* Please provide a valid organization email. If you do not have it, contact the responsible person.',
                            style: authTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8A6116),
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildReadOnlyField(
                          label: 'First Name',
                          value: _asString(verifiedProfile['first_name']),
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          label: 'Middle Name',
                          value: _asString(verifiedProfile['middle_name']),
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          label: 'Last Name',
                          value: _asString(verifiedProfile['last_name']),
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          label: 'Sur Name',
                          value: _asString(verifiedProfile['sur_name']),
                          icon: Icons.person_outline,
                        ),
                        _buildReadOnlyField(
                          label: 'Gender',
                          value: _asString(verifiedProfile['gender']),
                          icon: Icons.wc,
                        ),
                        _buildReadOnlyField(
                          label: 'Work Station',
                          value: _asString(
                            verifiedProfile['working_station_name'],
                          ),
                          icon: Icons.local_hospital_outlined,
                        ),
                        authLabeledField(
                          label: 'Email',
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: authTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: authInputDecoration(
                              hintText: 'abc.def@mohz.go.tz',
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: Validators.validateEmail,
                          ),
                        ),
                        authLabeledField(
                          label: 'Reporting Chain Starting Point',
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('reporting-path::$_selectedPathId'),
                            initialValue: _selectedPathId,
                            isExpanded: true,
                            style: authTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            iconEnabledColor: authIconColor,
                            decoration: authInputDecoration(
                              hintText: 'Select reporting path',
                              prefixIcon: Icons.account_tree_outlined,
                            ),
                            items: _pathOptions.map((path) {
                              final value = _asString(path['leave_path_id']);
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  _pathLabel(path),
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
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'This field is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        authLabeledField(
                          label: 'Password',
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            style: authTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: authInputDecoration(
                              hintText: 'Abc@123lop',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: authIconColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: Validators.validateStrongPassword,
                          ),
                        ),
                        authLabeledField(
                          label: 'Confirm Password',
                          margin: EdgeInsets.zero,
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_confirmPasswordVisible,
                            style: authTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: authInputDecoration(
                              hintText: 'Confirm password',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: authIconColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm password is required';
                              }
                              if (value != _passwordController.text) {
                                return 'Confirm password does not match password';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _register,
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
                                : const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    onPressed: () => Navigator.pop(context),
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
    );
  }
}

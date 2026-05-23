import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/profile/models/profile_details.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/widgets/responsive_layout.dart';
import '../providers/profile_view_model.dart';
import '../widgets/edit_profile_form_widgets.dart';
import '../widgets/profile_summary_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.initialDetails});

  final ProfileDetails initialDetails;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dateOfBirthController;

  late String _gender;
  bool _isSaving = false;
  String? _error;

  static const _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    final details = widget.initialDetails;
    _firstNameController = TextEditingController(text: details.firstName);
    _middleNameController = TextEditingController(text: details.middleName);
    _lastNameController = TextEditingController(text: details.lastName);
    _phoneController = TextEditingController(text: details.phoneNo);
    _emailController = TextEditingController(text: details.email);
    _dateOfBirthController = TextEditingController(
      text: _normalizeDate(details.dateOfBirth),
    );
    _gender = _normalizeGender(details.gender);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate =
        DateTime.tryParse(_dateOfBirthController.text.trim()) ??
        DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _dateOfBirthController.text = _formatDateForApi(picked);
    });
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.initialDetails.copyWith(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNo: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirthController.text.trim(),
    );

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(profileActionsProvider).updateProfile(updated);
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 44,
        titleSpacing: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F6BFF),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveListView(
          maxWidth: AppBreakpoints.maxFormWidth,
          padding: AppBreakpoints.pagePadding(context),
          children: [
            ProfileSectionLabel(title: 'PERSONAL DETAILS'),
            const SizedBox(height: 10),
            EditProfileFormCard(
              children: [
                EditProfileInputField(
                  controller: _firstNameController,
                  label: 'First Name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'First name is required.';
                    }
                    return null;
                  },
                ),
                EditProfileInputField(
                  controller: _middleNameController,
                  label: 'Middle Name',
                  textInputAction: TextInputAction.next,
                ),
                EditProfileInputField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Last name is required.';
                    }
                    return null;
                  },
                ),
                EditProfileDropdownField(
                  label: 'Gender',
                  value: _gender.isEmpty ? null : _gender,
                  items: _genders,
                  onChanged: (value) => setState(() => _gender = value ?? ''),
                ),
                EditProfileInputField(
                  controller: _dateOfBirthController,
                  label: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ProfileSectionLabel(title: 'CONTACT'),
            const SizedBox(height: 10),
            EditProfileFormCard(
              children: [
                EditProfileInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                EditProfileInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return null;
                    final valid = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);
                    if (!valid) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ProfileInlineMessage(message: _error!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeDate(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return value.trim();
    return _formatDateForApi(parsed);
  }

  String _normalizeGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male') return 'Male';
    if (normalized == 'female') return 'Female';
    return '';
  }

  String _formatDateForApi(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

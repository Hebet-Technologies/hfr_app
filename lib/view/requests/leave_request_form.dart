import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import 'request_form_widgets.dart';
import 'request_submission_success.dart';

class LeaveRequestFormScreen extends ConsumerStatefulWidget {
  const LeaveRequestFormScreen({super.key});

  @override
  ConsumerState<LeaveRequestFormScreen> createState() =>
      _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState
    extends ConsumerState<LeaveRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _numberOfDaysController = TextEditingController();
  final _placeToTravelController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  String? _leaveTypeId;
  String? _representativeId;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _contactController.dispose();
    _numberOfDaysController.dispose();
    _placeToTravelController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final selectedLeaveType = state.leaveTypes.firstWhereOrNull(
      (item) => item.id == _leaveTypeId,
    );
    final requiresRepresentative = authState.user?.primaryRoleId != '7';

    return Scaffold(
      backgroundColor: requestSurface,
      appBar: AppBar(
        backgroundColor: requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Apply Leave',
          style: requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppDropdownField(
                  label: 'Leave Type',
                  value: _leaveTypeId,
                  hintText: 'Select',
                  items: state.leaveTypes,
                  onChanged: (value) {
                    setState(() {
                      _leaveTypeId = value;
                      final nextType = state.leaveTypes.firstWhereOrNull(
                        (item) => item.id == value,
                      );
                      if (nextType?.requiresDayCount != true) {
                        _numberOfDaysController.clear();
                      }
                      if (nextType?.requiresAttachment != true) {
                        _selectedFile = null;
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a leave type' : null,
                ),
                DateInputField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await pickDate(context, initial: _startDate);
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                if (selectedLeaveType?.requiresDayCount == true)
                  AppTextField(
                    label: 'Number of Days',
                    controller: _numberOfDaysController,
                    hintText: 'Input Number of Days',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final normalized = (value ?? '').trim();
                      if (normalized.isEmpty) {
                        return 'This field is required';
                      }
                      final days = int.tryParse(normalized);
                      if (days == null || days <= 0) {
                        return 'Enter a valid number of days';
                      }
                      return null;
                    },
                  ),
                AppTextField(
                  label: 'Contact on Leave',
                  controller: _contactController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.phone,
                ),
                if (selectedLeaveType?.requiresAttachment == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FileUploadField(
                      title: 'Upload Leave Attachment',
                      description: 'PDF format, max 1MB.',
                      fileName: _selectedFile?.name,
                      onBrowse: _pickFile,
                    ),
                  ),
                if (requiresRepresentative)
                  AppDropdownField(
                    label: 'Representative',
                    value: _representativeId,
                    hintText: 'Input Name',
                    items: state.representatives,
                    onChanged: (value) =>
                        setState(() => _representativeId = value),
                    validator: (value) =>
                        value == null ? 'Select a representative' : null,
                  ),
                // AppTextField(
                //   label: 'Place To Travel',
                //   controller: _placeToTravelController,
                //   hintText: 'Optional',
                //   validator: (_) => null,
                // ),
                /* AppTextField(
                  label: 'Reason for Leave',
                  controller: _reasonController,
                  hintText: 'Optional',
                  maxLines: 5,
                  validator: (_) => null,
                ), */
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  InlineErrorText(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: filledButtonStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Leave Request',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showError('Choose a start date.');
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    final leaveType = state.leaveTypes.firstWhereOrNull(
      (item) => item.id == _leaveTypeId,
    );
    if (leaveType == null) {
      _showError('Leave types are unavailable. Refresh and try again.');
      return;
    }
    int? numberOfDays;
    if (leaveType.requiresDayCount) {
      numberOfDays = int.tryParse(_numberOfDaysController.text.trim());
      if (numberOfDays == null || numberOfDays <= 0) {
        _showError('Enter a valid number of days.');
        return;
      }
    }

    final requiresRepresentative =
        ref.read(authViewModelProvider).user?.primaryRoleId != '7';
    final representative = state.representatives.firstWhereOrNull(
      (item) => item.id == _representativeId,
    );
    if (requiresRepresentative && representative == null) {
      _showError('Select a representative before continuing.');
      return;
    }
    final placeToTravel = _placeToTravelController.text.trim();
    final file = _selectedFile;
    final filePath = file?.path;
    if (leaveType.requiresAttachment &&
        (file == null || filePath == null || filePath.trim().isEmpty)) {
      _showError('Upload the required PDF attachment before submitting.');
      return;
    }

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitLeaveRequest(
            LeaveRequestDraft(
              leaveTypeId: leaveType.id,
              leaveTypeLabel: leaveType.label,
              startDate: _startDate!,
              contactOnLeave: _contactController.text.trim(),
              reason: '', // _reasonController.text.trim(),
              numberOfDays: numberOfDays,
              representativeId: representative?.id,
              representativeLabel: representative?.label,
              placeToTravel: placeToTravel.isEmpty ? null : placeToTravel,
              filePath: filePath,
              fileName: file?.name,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSubmissionSuccessScreen(request: record),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload a PDF file smaller than 1MB.')),
      );
      return;
    }
    setState(() => _selectedFile = file);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

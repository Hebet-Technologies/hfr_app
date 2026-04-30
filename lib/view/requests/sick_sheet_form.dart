import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import 'request_form_widgets.dart';
import 'request_submission_success.dart';

class SickSheetFormScreen extends ConsumerStatefulWidget {
  const SickSheetFormScreen({super.key});

  @override
  ConsumerState<SickSheetFormScreen> createState() =>
      _SickSheetFormScreenState();
}

class _SickSheetFormScreenState extends ConsumerState<SickSheetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _noteController = TextEditingController();
  String? _leaveTypeId;
  DateTime? _sickSheetDate;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _contactController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final sickLeaveTypes = state.leaveTypes.where((item) {
      final label = item.label.toLowerCase();
      return label.contains('sick') || label.contains('medical');
    }).toList();
    final leaveTypes = sickLeaveTypes.isEmpty
        ? state.leaveTypes
        : sickLeaveTypes;

    return Scaffold(
      backgroundColor: requestSurface,
      appBar: AppBar(
        backgroundColor: requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Submit Sick Sheet',
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
                /* AppDropdownField(
                  label: 'Sick Leave Type',
                  value: _leaveTypeId,
                  hintText: 'Select',
                  items: leaveTypes,
                  onChanged: (value) => setState(() => _leaveTypeId = value),
                  validator: (value) =>
                      value == null ? 'Select sick leave type' : null,
                ),
                DateInputField(
                  label: 'Sick Sheet Date',
                  value: _sickSheetDate,
                  onTap: () async {
                    final picked = await pickDate(
                      context,
                      initial: _sickSheetDate,
                    );
                    if (picked != null) {
                      setState(() => _sickSheetDate = picked);
                    }
                  },
                ),
                AppTextField(
                  label: 'Contact During Sick Leave',
                  controller: _contactController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.phone,
                ),
                AppTextField(
                  label: 'Note',
                  controller: _noteController,
                  hintText: 'Optional',
                  maxLines: 4,
                  validator: (_) => null,
                ), */
                FileUploadField(
                  title: 'Upload Sick Sheet',
                  description: 'PDF format, max 1MB.',
                  fileName: _selectedFile?.name,
                  onBrowse: _pickFile,
                ),
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
                          : 'Submit Sick Sheet',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    /* if (_sickSheetDate == null) {
      _showError('Choose the sick sheet date.');
      return;
    } */
    final file = _selectedFile;
    final filePath = file?.path;
    if (file == null || filePath == null || filePath.trim().isEmpty) {
      _showError('Upload the sick sheet document before submitting.');
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    /* final leaveType = state.leaveTypes.firstWhereOrNull(
      (item) => item.id == _leaveTypeId,
    );
    if (leaveType == null) {
      _showError('Sick leave type is unavailable. Refresh and try again.');
      return;
    } */

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitSickSheet(
            SickSheetDraft(
              leaveTypeId: '',
              leaveTypeLabel: '',
              startDate: DateTime.now(),
              contactOnLeave: '',
              filePath: filePath,
              fileName: file.name,
              numberOfDays: null,
              note: '',
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

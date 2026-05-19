import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';
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
    final file = _selectedFile;
    final filePath = file?.path;
    if (file == null || filePath == null || filePath.trim().isEmpty) {
      _showError('Upload the sick sheet document before submitting.');
      return;
    }

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
      _showError(friendlyErrorMessage(error));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

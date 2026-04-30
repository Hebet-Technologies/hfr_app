import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import 'request_form_widgets.dart';
import 'request_submission_success.dart';

class TransferRequestFormScreen extends ConsumerStatefulWidget {
  const TransferRequestFormScreen({super.key});

  @override
  ConsumerState<TransferRequestFormScreen> createState() =>
      _TransferRequestFormScreenState();
}

class _TransferRequestFormScreenState
    extends ConsumerState<TransferRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonTextController = TextEditingController();
  String? _facilityId;
  String? _departmentId;
  String? _reasonId;
  DateTime? _preferredDate;
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _reasonTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final departments = state.departmentsByFacilityId[_facilityId] ?? const [];
    final selectedReason = state.transferReasons.firstWhereOrNull(
      (item) => item.id == _reasonId,
    );

    return Scaffold(
      backgroundColor: requestSurface,
      appBar: AppBar(
        backgroundColor: requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Request Transfer',
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
                  label: 'Preferred Facility',
                  value: _facilityId,
                  hintText: 'Select',
                  items: state.facilities,
                  onChanged: (value) {
                    setState(() {
                      _facilityId = value;
                      _departmentId = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a facility' : null,
                ),
                AppDropdownField(
                  label: 'Preferred Department',
                  value: _departmentId,
                  hintText: 'Select',
                  items: departments,
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
                AppDropdownField(
                  label: 'Reason for Transfer',
                  value: _reasonId,
                  hintText: 'Select',
                  items: state.transferReasons,
                  onChanged: (value) {
                    setState(() {
                      _reasonId = value;
                      final nextReason = state.transferReasons.firstWhereOrNull(
                        (item) => item.id == value,
                      );
                      if (nextReason?.requiresAttachment != true) {
                        _selectedFile = null;
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a transfer reason' : null,
                ),
                AppTextField(
                  label: 'Transfer Notes',
                  controller: _reasonTextController,
                  hintText: 'Optional',
                  maxLines: 5,
                  validator: (_) => null,
                ),
                DateInputField(
                  label: 'Preferred Transfer Date',
                  value: _preferredDate,
                  onTap: () async {
                    final picked = await pickDate(
                      context,
                      initial: _preferredDate,
                    );
                    if (picked != null) {
                      setState(() => _preferredDate = picked);
                    }
                  },
                ),
                if (selectedReason?.requiresAttachment == true) ...[
                  const SizedBox(height: 10),
                  FileUploadField(
                    title: 'Upload Transfer Attachment',
                    description: 'PDF format, max 1MB.',
                    fileName: _selectedFile?.name,
                    onBrowse: _pickFile,
                  ),
                ],
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
                          : 'Submit Transfer Request',
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
    if (_preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a preferred transfer date.')),
      );
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    final facility = state.facilities.firstWhereOrNull(
      (item) => item.id == _facilityId,
    );
    final reason = state.transferReasons.firstWhereOrNull(
      (item) => item.id == _reasonId,
    );
    if (facility == null || reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transfer options are unavailable. Refresh and try again.',
          ),
        ),
      );
      return;
    }
    final file = _selectedFile;
    final filePath = file?.path;
    if (reason.requiresAttachment &&
        (file == null || filePath == null || filePath.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload the required PDF attachment before submitting.',
          ),
        ),
      );
      return;
    }
    final department = state.departmentsByFacilityId[_facilityId]
        ?.firstWhereOrNull((item) => item.id == _departmentId);

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitTransferRequest(
            TransferRequestDraft(
              facilityId: facility.id,
              facilityLabel: facility.label,
              reasonId: reason.id,
              reasonLabel: reason.label,
              reasonText: _reasonTextController.text.trim(),
              preferredTransferDate: _preferredDate!,
              departmentId: department?.id,
              departmentLabel: department?.label,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
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
}

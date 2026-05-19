import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import 'request_form_widgets.dart';
import 'request_submission_success.dart';

class ActivityRequestFormScreen extends ConsumerStatefulWidget {
  const ActivityRequestFormScreen({super.key});

  @override
  ConsumerState<ActivityRequestFormScreen> createState() =>
      _ActivityRequestFormScreenState();
}

class _ActivityRequestFormScreenState
    extends ConsumerState<ActivityRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  String? _category;
  String? _scope;
  PlatformFile? _selectedFile;

  static const _categories = ['Travel', 'Workshop', 'Outreach', 'Meeting'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ref.read(staffRequestsViewModelProvider.notifier).fetchActivityOptions();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final rules = ref.watch(activityRequestRulesProvider);
    final selectedScope = rules.scopeFromLabel(_scope);
    final requiresAttachment = selectedScope?.requiresAttachment ?? false;

    return Scaffold(
      backgroundColor: requestSurface,
      appBar: AppBar(
        backgroundColor: requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Register Activity',
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
                SimpleDropdownField(
                  label: 'Activity Category',
                  value: _category,
                  hintText: 'Select',
                  items: _categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
                SimpleDropdownField(
                  label: 'Activity Scope',
                  value: _scope,
                  hintText: 'Select',
                  items: rules.scopeLabels,
                  onChanged: (value) {
                    setState(() {
                      _scope = value;
                      if (!rules.requiresAttachment(value)) {
                        _selectedFile = null;
                      }
                    });
                  },
                ),
                AppTextField(
                  label: 'Destination Name (Optional)',
                  controller: _locationController,
                  hintText: 'Input',
                ),
                DateInputField(
                  label: 'Activity Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await pickDate(context, initial: _startDate);
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                AppTextField(
                  label: 'Description (Optional)',
                  controller: _descriptionController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                FileUploadField(
                  title: requiresAttachment
                      ? 'Upload Letter or Supporting Documents'
                      : 'Upload Supporting Documents (Optional)',
                  description: requiresAttachment
                      ? 'PDF format, max 1MB. Required for mainland or international activities.'
                      : 'PDF format, max 1MB.',
                  fileName: _selectedFile?.name,
                  onBrowse: _pickFile,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  InlineErrorText(message: state.errorMessage!),
                ],
                /* const SizedBox(height: 10),
                const UploadPlaceholder(), */
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: filledButtonStyle(),
                    onPressed: state.isSubmitting ? null : _submit,
                    child: Text(
                      state.isSubmitting ? 'Submitting...' : 'Submit Activity',
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
    if (_category == null || _scope == null || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }
    if (isPastDate(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity date cannot be before today.')),
      );
      return;
    }

    final scope = ref.read(activityRequestRulesProvider).scopeFromLabel(_scope);
    if (scope == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a valid activity scope.')),
      );
      return;
    }

    final file = _selectedFile;
    final filePath = file?.path;
    if (scope.requiresAttachment &&
        (file == null || filePath == null || filePath.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload the required letter or supporting documents.'),
        ),
      );
      return;
    }

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitActivityRequest(
            ActivityRequestDraft(
              name: _category!,
              activityDate: _startDate!,
              activityAreaType: scope.apiValue,
              destinationName: _locationController.text.trim(),
              description: _descriptionController.text.trim(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
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

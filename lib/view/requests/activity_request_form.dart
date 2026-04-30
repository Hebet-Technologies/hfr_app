import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
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

  static const _categories = ['Travel', 'Workshop', 'Outreach', 'Meeting'];

  static const _scopes = [
    'Within Facility',
    'Within District',
    'Within Zanzibar',
    'Mainland Tanzania',
    'International',
  ];

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
                  items: _scopes,
                  onChanged: (value) => setState(() => _scope = value),
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
                    final picked = await pickDate(
                      context,
                      initial: _startDate,
                    );
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

    String apiScope = 'WITHIN_WORKING_AREA';
    switch (_scope) {
      case 'Within Facility':
      case 'Within District':
        apiScope = 'WITHIN_WORKING_AREA';
        break;
      case 'Within Zanzibar':
        apiScope = 'ZANZIBAR';
        break;
      case 'Mainland Tanzania':
        apiScope = 'MAINLAND';
        break;
      case 'International':
        apiScope = 'INTERNATIONAL';
        break;
    }

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitActivityRequest(
            ActivityRequestDraft(
              name: _category!,
              activityDate: _startDate!,
              activityAreaType: apiScope,
              destinationName: _locationController.text.trim(),
              description: _descriptionController.text.trim(),
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
}

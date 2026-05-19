import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:staffportal/features/requests/models/staff_request_models.dart';
import 'package:staffportal/core/utils/error_messages.dart';
import 'package:staffportal/core/providers/app_providers.dart';
import 'request_form_widgets.dart';
import 'request_submission_success.dart';

class LoanRequestFormScreen extends ConsumerStatefulWidget {
  const LoanRequestFormScreen({super.key});

  @override
  ConsumerState<LoanRequestFormScreen> createState() =>
      _LoanRequestFormScreenState();
}

class _LoanRequestFormScreenState extends ConsumerState<LoanRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _bankId;
  String? _repaymentPeriod;

  static const _repaymentOptions = [
    '6 Months',
    '12 Months',
    '18 Months',
    '24 Months',
  ];

  @override
  void dispose() {
    _amountController.dispose();
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
          'Apply for Loan',
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
                  label: 'Preferred Bank',
                  value: _bankId,
                  hintText: 'Select',
                  items: state.loanBanks,
                  onChanged: (value) => setState(() => _bankId = value),
                  validator: (value) => value == null ? 'Select bank' : null,
                ),
                AppTextField(
                  label: 'Requested Amount',
                  controller: _amountController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.number,
                ),
                SimpleDropdownField(
                  label: 'Repayment Period',
                  value: _repaymentPeriod,
                  hintText: 'Select',
                  items: _repaymentOptions,
                  onChanged: (value) =>
                      setState(() => _repaymentPeriod = value),
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
                      state.isSubmitting
                          ? 'Submitting...'
                          : 'Submit Loan Application',
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
    if (_bankId == null || _repaymentPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }

    final state = ref.read(staffRequestsViewModelProvider);
    final bank = state.loanBanks.firstWhereOrNull((item) => item.id == _bankId);
    if (bank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank list is unavailable. Refresh and try again.'),
        ),
      );
      return;
    }
    final repayment = loanTermFromLabel(_repaymentPeriod!);

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitLoanRequest(
            LoanRequestDraft(
              bankId: bank.id,
              bankLabel: bank.label,
              loanType: '',
              requestedAmount: _amountController.text.trim(),
              employerStatus: '',
              monthlySalary: '',
              repaymentMonths: _repaymentPeriod!,
              termDuration: repayment.duration,
              termPeriod: repayment.period,
              purpose: '',
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/staff_request_models.dart';
import '../../view_model/providers.dart';
import '../../view_model/staff_request_view_model.dart';

const _requestBlue = Color(0xFF1F6BFF);
const _requestSurface = Color(0xFFF5F7FB);
const _requestCard = Colors.white;
const _requestBorder = Color(0xFFE8EEF6);
const _requestText = Color(0xFF111827);
const _requestMuted = Color(0xFF6B7280);

Future<void> showRequestComposerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _NewRequestSheet(parentContext: context),
  );
}

void openRequestFormScreen(BuildContext context, StaffRequestType type) {
  final page = switch (type) {
    StaffRequestType.activity => const ActivityRequestFormScreen(),
    StaffRequestType.leave => const LeaveRequestFormScreen(),
    StaffRequestType.transfer => const TransferRequestFormScreen(),
    StaffRequestType.loan => const LoanRequestFormScreen(),
    StaffRequestType.sickLeave => const RequestCategoryListScreen(
      type: StaffRequestType.sickLeave,
    ),
  };

  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffRequestsViewModelProvider);

    return Scaffold(
      backgroundColor: _requestSurface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _requestBlue,
        onPressed: () => showRequestComposerSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _requestBlue,
          onRefresh: () =>
              ref.read(staffRequestsViewModelProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Text(
                'Requests',
                style: _requestTextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (state.errorMessage != null)
                _InlineBanner(
                  message: state.errorMessage!,
                  onClose: () => ref
                      .read(staffRequestsViewModelProvider.notifier)
                      .clearError(),
                ),
              if (state.errorMessage != null) const SizedBox(height: 14),
              if (state.isLoading && state.records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _RequestOverviewSection(
                  type: StaffRequestType.activity,
                  count: state.countFor(StaffRequestType.activity),
                  preview: _previewFor(state, StaffRequestType.activity),
                  onTap: () => _openList(context, StaffRequestType.activity),
                ),
                const SizedBox(height: 14),
                _RequestOverviewSection(
                  type: StaffRequestType.leave,
                  count: state.countFor(StaffRequestType.leave),
                  preview: _previewFor(state, StaffRequestType.leave),
                  onTap: () => _openList(context, StaffRequestType.leave),
                ),
                const SizedBox(height: 14),
                _RequestOverviewSection(
                  type: StaffRequestType.transfer,
                  count: state.countFor(StaffRequestType.transfer),
                  preview: _previewFor(state, StaffRequestType.transfer),
                  onTap: () => _openList(context, StaffRequestType.transfer),
                ),
                const SizedBox(height: 14),
                _RequestOverviewSection(
                  type: StaffRequestType.loan,
                  count: state.countFor(StaffRequestType.loan),
                  preview: _previewFor(state, StaffRequestType.loan),
                  onTap: () => _openList(context, StaffRequestType.loan),
                ),
                const SizedBox(height: 14),
                _RequestOverviewSection(
                  type: StaffRequestType.sickLeave,
                  count: state.countFor(StaffRequestType.sickLeave),
                  preview: _previewFor(state, StaffRequestType.sickLeave),
                  onTap: () => _openList(context, StaffRequestType.sickLeave),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static StaffRequestRecord _previewFor(
    StaffRequestsState state,
    StaffRequestType type,
  ) {
    final items = state.recordsFor(type);
    if (items.isNotEmpty) return items.first;

    return StaffRequestRecord(
      id: 'empty-${type.name}',
      type: type,
      title: type.pluralLabel,
      summary: 'No records yet',
      status: StaffRequestStatus.pending,
      submittedAt: DateTime.now(),
      detailFields: const [],
    );
  }

  static void _openList(BuildContext context, StaffRequestType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestCategoryListScreen(type: type),
      ),
    );
  }
}

class RequestCategoryListScreen extends ConsumerWidget {
  const RequestCategoryListScreen({super.key, required this.type});

  final StaffRequestType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final items = state.recordsFor(type);

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          type.pluralLabel,
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: type == StaffRequestType.sickLeave
          ? null
          : FloatingActionButton(
              backgroundColor: _requestBlue,
              mini: true,
              onPressed: () => openRequestFormScreen(context, type),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _RequestListCard(
            request: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RequestDetailScreen(request: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _detailTitle(request.type),
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _requestCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _requestBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: _requestTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.referenceNumber ?? 'Reference pending',
                  style: _requestTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _requestMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _StatusBadge(status: request.status),
                const SizedBox(height: 18),
                for (final field in request.detailFields) ...[
                  _DetailRow(field: field),
                  const Divider(height: 24, color: _requestBorder),
                ],
                if (request.attachmentName != null &&
                    request.attachmentName!.trim().isNotEmpty)
                  _AttachmentCard(name: request.attachmentName!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _detailTitle(StaffRequestType type) {
    switch (type) {
      case StaffRequestType.activity:
        return 'Activity Details';
      case StaffRequestType.leave:
        return 'Leave Request Details';
      case StaffRequestType.transfer:
        return 'Transfer Request Details';
      case StaffRequestType.loan:
        return 'Loan Application Details';
      case StaffRequestType.sickLeave:
        return 'Sick Leave Details';
    }
  }
}

class RequestSubmissionSuccessScreen extends StatelessWidget {
  const RequestSubmissionSuccessScreen({super.key, required this.request});

  final StaffRequestRecord request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF5),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _requestBlue,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  '${request.type.label} Request Submitted',
                  textAlign: TextAlign.center,
                  style: _requestTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Request submitted successfully.\nReference Number ${request.referenceNumber ?? 'Pending'}',
                  textAlign: TextAlign.center,
                  style: _requestTextStyle(
                    fontSize: 13,
                    color: _requestMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => RequestDetailScreen(request: request),
                        ),
                      );
                    },
                    child: const Text('View Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  final _placeToTravelController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _leaveTypeId;
  String? _representativeId;

  @override
  void dispose() {
    _contactController.dispose();
    _placeToTravelController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Apply Leave',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppDropdownField(
                  label: 'Leave Type',
                  value: _leaveTypeId,
                  hintText: 'Select',
                  items: state.leaveTypes,
                  onChanged: (value) => setState(() => _leaveTypeId = value),
                  validator: (value) =>
                      value == null ? 'Select a leave type' : null,
                ),
                _DateInputField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                _DateInputField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _endDate ?? _startDate,
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
                _AppTextField(
                  label: 'Contact on Leave',
                  controller: _contactController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.phone,
                ),
                _AppDropdownField(
                  label: 'Representative',
                  value: _representativeId,
                  hintText: 'Input Name',
                  items: state.representatives,
                  onChanged: (value) =>
                      setState(() => _representativeId = value),
                ),
                _AppTextField(
                  label: 'Place To Travel',
                  controller: _placeToTravelController,
                  hintText: 'Optional',
                  validator: (_) => null,
                ),
                _AppTextField(
                  label: 'Reason for Leave',
                  controller: _reasonController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineErrorText(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
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
    if (_startDate == null || _endDate == null) {
      _showError('Choose both start and end dates.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date cannot be earlier than start date.');
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
    final representative = state.representatives.firstWhereOrNull(
      (item) => item.id == _representativeId,
    );
    final placeToTravel = _placeToTravelController.text.trim();

    try {
      final record = await ref
          .read(staffRequestsViewModelProvider.notifier)
          .submitLeaveRequest(
            LeaveRequestDraft(
              leaveTypeId: leaveType.id,
              leaveTypeLabel: leaveType.label,
              startDate: _startDate!,
              endDate: _endDate!,
              contactOnLeave: _contactController.text.trim(),
              reason: _reasonController.text.trim(),
              representativeId: representative?.id,
              representativeLabel: representative?.label,
              placeToTravel: placeToTravel.isEmpty ? null : placeToTravel,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSubmissionSuccessScreen(request: record),
        ),
      );
    } catch (_) {}
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

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

  @override
  void dispose() {
    _reasonTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    final departments = state.departmentsByFacilityId[_facilityId] ?? const [];

    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Request Transfer',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppDropdownField(
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
                _AppDropdownField(
                  label: 'Preferred Department',
                  value: _departmentId,
                  hintText: 'Select',
                  items: departments,
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
                _AppDropdownField(
                  label: 'Reason for Transfer',
                  value: _reasonId,
                  hintText: 'Select',
                  items: state.transferReasons,
                  onChanged: (value) => setState(() => _reasonId = value),
                  validator: (value) =>
                      value == null ? 'Select a transfer reason' : null,
                ),
                _AppTextField(
                  label: 'Reason for Transfer',
                  controller: _reasonTextController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                _DateInputField(
                  label: 'Preferred Transfer Date',
                  value: _preferredDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _preferredDate,
                    );
                    if (picked != null) {
                      setState(() => _preferredDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _InlineErrorText(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
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
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSubmissionSuccessScreen(request: record),
        ),
      );
    } catch (_) {}
  }
}

class ActivityRequestFormScreen extends ConsumerStatefulWidget {
  const ActivityRequestFormScreen({super.key});

  @override
  ConsumerState<ActivityRequestFormScreen> createState() =>
      _ActivityRequestFormScreenState();
}

class _ActivityRequestFormScreenState
    extends ConsumerState<ActivityRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;
  String? _scope;
  String _participants = 'Individual Activity';

  static const _categories = ['Travel', 'Workshop', 'Outreach', 'Meeting'];

  static const _scopes = [
    'Within Facility',
    'Within District',
    'Within Zanzibar',
    'Mainland Tanzania',
    'International',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Register Activity',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AppTextField(
                  label: 'Activity Title',
                  controller: _titleController,
                  hintText: 'Input',
                ),
                _SimpleDropdownField(
                  label: 'Activity Category',
                  value: _category,
                  hintText: 'Select',
                  items: _categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
                _SimpleDropdownField(
                  label: 'Activity Scope',
                  value: _scope,
                  hintText: 'Select',
                  items: _scopes,
                  onChanged: (value) => setState(() => _scope = value),
                ),
                _AppTextField(
                  label: 'Activity Location',
                  controller: _locationController,
                  hintText: 'Input',
                ),
                _DateInputField(
                  label: 'Start Date',
                  value: _startDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _startDate,
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
                _DateInputField(
                  label: 'End Date',
                  value: _endDate,
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initial: _endDate ?? _startDate,
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
                _ParticipantsSelector(
                  value: _participants,
                  onChanged: (value) => setState(() => _participants = value),
                ),
                _AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
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
    if (_startDate == null ||
        _endDate == null ||
        _category == null ||
        _scope == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }

    final record = await ref
        .read(staffRequestsViewModelProvider.notifier)
        .submitActivityRequest(
          ActivityRequestDraft(
            activityTitle: _titleController.text.trim(),
            category: _category!,
            scope: _scope!,
            location: _locationController.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            participants: _participants,
            description: _descriptionController.text.trim(),
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RequestSubmissionSuccessScreen(request: record),
      ),
    );
  }
}

class LoanRequestFormScreen extends ConsumerStatefulWidget {
  const LoanRequestFormScreen({super.key});

  @override
  ConsumerState<LoanRequestFormScreen> createState() =>
      _LoanRequestFormScreenState();
}

class _LoanRequestFormScreenState extends ConsumerState<LoanRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _salaryController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _loanType;
  String? _employerStatus;
  String? _repaymentPeriod;

  static const _loanTypes = [
    'Soft Development Loan',
    'Emergency Loan',
    'School Fees Loan',
  ];

  static const _employerStatuses = [
    'Permanent Staff',
    'Contract Staff',
    'Probation',
  ];

  static const _repaymentOptions = ['6', '12', '18', '24'];

  @override
  void dispose() {
    _amountController.dispose();
    _salaryController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestsViewModelProvider);
    return Scaffold(
      backgroundColor: _requestSurface,
      appBar: AppBar(
        backgroundColor: _requestSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Apply for Loan',
          style: _requestTextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _SimpleDropdownField(
                  label: 'Loan Type',
                  value: _loanType,
                  hintText: 'Select',
                  items: _loanTypes,
                  onChanged: (value) => setState(() => _loanType = value),
                ),
                _AppTextField(
                  label: 'Requested Amount',
                  controller: _amountController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.number,
                ),
                _SimpleDropdownField(
                  label: 'Employer Status',
                  value: _employerStatus,
                  hintText: 'Select',
                  items: _employerStatuses,
                  onChanged: (value) => setState(() => _employerStatus = value),
                ),
                _AppTextField(
                  label: 'Monthly Salary',
                  controller: _salaryController,
                  hintText: 'Input Number',
                  keyboardType: TextInputType.number,
                ),
                _SimpleDropdownField(
                  label: 'Repayment Period',
                  value: _repaymentPeriod,
                  hintText: 'Select',
                  items: _repaymentOptions
                      .map((item) => '$item Months')
                      .toList(),
                  onChanged: (value) => setState(() {
                    _repaymentPeriod = value?.split(' ').first;
                  }),
                ),
                _AppTextField(
                  label: 'Purpose of Loan',
                  controller: _purposeController,
                  hintText: 'Input',
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                const _UploadPlaceholder(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: _filledStyle(),
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
    if (_loanType == null ||
        _employerStatus == null ||
        _repaymentPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields.')),
      );
      return;
    }

    final record = await ref
        .read(staffRequestsViewModelProvider.notifier)
        .submitLoanRequest(
          LoanRequestDraft(
            loanType: _loanType!,
            requestedAmount: _amountController.text.trim(),
            employerStatus: _employerStatus!,
            monthlySalary: _salaryController.text.trim(),
            repaymentMonths: _repaymentPeriod!,
            purpose: _purposeController.text.trim(),
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RequestSubmissionSuccessScreen(request: record),
      ),
    );
  }
}

class _NewRequestSheet extends StatelessWidget {
  const _NewRequestSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            _ComposerOptionTile(
              title: 'Apply Leave',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.leave);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Request Transfer',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.transfer);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Register Activity',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.activity);
              },
            ),
            const SizedBox(height: 10),
            _ComposerOptionTile(
              title: 'Apply Loan',
              onTap: () {
                Navigator.of(context).pop();
                openRequestFormScreen(parentContext, StaffRequestType.loan);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestOverviewSection extends StatelessWidget {
  const _RequestOverviewSection({
    required this.type,
    required this.count,
    required this.preview,
    required this.onTap,
  });

  final StaffRequestType type;
  final int count;
  final StaffRequestRecord preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _requestCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquareIcon(icon: _iconFor(type), background: _softFor(type)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.pluralLabel,
                      style: _requestTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'record' : 'records'}',
                      style: _requestTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _requestMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(
                  'View Details',
                  style: _requestTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _requestBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RequestPreviewCard(request: preview, onTap: onTap),
        ],
      ),
    );
  }
}

class _RequestPreviewCard extends StatelessWidget {
  const _RequestPreviewCard({required this.request, required this.onTap});

  final StaffRequestRecord request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _requestBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.summary.isEmpty
                        ? 'No details yet'
                        : request.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 12,
                      color: _requestMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusBadge(status: request.status),
          ],
        ),
      ),
    );
  }
}

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({required this.request, required this.onTap});

  final StaffRequestRecord request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _requestCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _requestBorder),
        ),
        child: Row(
          children: [
            _SquareIcon(
              icon: _iconFor(request.type),
              background: _softFor(request.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.referenceNumber ??
                        _formatShortDate(request.submittedAt),
                    style: _requestTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _requestMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _requestTextStyle(
                      fontSize: 12,
                      color: _requestMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: request.status),
                const SizedBox(height: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _requestMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.field});

  final RequestDetailField field;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            field.label,
            style: _requestTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _requestMuted,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: field.status == null
              ? Text(
                  field.value,
                  textAlign: TextAlign.right,
                  style: _requestTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: _StatusBadge(status: field.status!),
                ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _requestBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: _requestBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: _requestTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StaffRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusSoft(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: _requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.background});

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: _requestBlue, size: 20),
    );
  }
}

class _ComposerOptionTile extends StatelessWidget {
  const _ComposerOptionTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _requestBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: _requestTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _requestMuted),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSelector extends StatelessWidget {
  const _ParticipantsSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: _requestTextStyle(fontSize: 12, color: _requestMuted),
            ),
            const SizedBox(height: 8),
            _ParticipantOption(
              label: 'Individual Activity',
              selected: value == 'Individual Activity',
              onTap: () => onChanged('Individual Activity'),
            ),
            const SizedBox(height: 8),
            _ParticipantOption(
              label: 'Group Activity',
              selected: value == 'Group Activity',
              onTap: () => onChanged('Group Activity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _requestBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: _requestMuted),
          const SizedBox(height: 10),
          Text(
            'Upload Documents',
            style: _requestTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '.JPEG, PNG, PDF and MP4 formats, up to 50 MB.',
            textAlign: TextAlign.center,
            style: _requestTextStyle(fontSize: 11, color: _requestMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _requestMuted,
              side: const BorderSide(color: _requestBorder),
            ),
            child: const Text('Browse File'),
          ),
        ],
      ),
    );
  }
}

class _ParticipantOption extends StatelessWidget {
  const _ParticipantOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _requestBlue : _requestMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: _requestTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator:
                validator ??
                (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
            style: _requestTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(hintText),
          ),
        ],
      ),
    );
  }
}

class _AppDropdownField extends StatelessWidget {
  const _AppDropdownField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<RequestLookupOption> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: _inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.label,
                      style: _requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

class _SimpleDropdownField extends StatelessWidget {
  const _SimpleDropdownField({
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: _inputDecoration(hintText),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: _requestTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (selected) =>
                selected == null ? 'This field is required' : null,
          ),
        ],
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _requestTextStyle(fontSize: 12, color: _requestMuted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: _inputDecoration('DD / MM / YYYY').copyWith(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _requestMuted,
                ),
              ),
              child: Text(
                value == null ? 'DD / MM / YYYY' : _formatInputDate(value!),
                style: _requestTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null ? const Color(0xFF9CA3AF) : _requestText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE67E22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _requestTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A5518),
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: _requestTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD14343),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: _requestTextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _requestBlue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD14343)),
    ),
  );
}

ButtonStyle _filledStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _requestBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: _requestTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );
}

TextStyle _requestTextStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color color = _requestText,
  double? height,
}) {
  return GoogleFonts.manrope(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
}

String _formatInputDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} / ${value.month.toString().padLeft(2, '0')} / ${value.year.toString().padLeft(4, '0')}';
}

String _formatShortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')} ${_monthShort(value.month)} ${value.year}';
}

String _monthShort(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

IconData _iconFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return Icons.assignment_turned_in_outlined;
    case StaffRequestType.leave:
      return Icons.event_available_rounded;
    case StaffRequestType.transfer:
      return Icons.compare_arrows_rounded;
    case StaffRequestType.loan:
      return Icons.account_balance_wallet_outlined;
    case StaffRequestType.sickLeave:
      return Icons.medical_services_outlined;
  }
}

Color _softFor(StaffRequestType type) {
  switch (type) {
    case StaffRequestType.activity:
      return const Color(0xFFEAF2FF);
    case StaffRequestType.leave:
      return const Color(0xFFEAFBF1);
    case StaffRequestType.transfer:
      return const Color(0xFFFFF2E8);
    case StaffRequestType.loan:
      return const Color(0xFFF3ECFF);
    case StaffRequestType.sickLeave:
      return const Color(0xFFFFEEF1);
  }
}

Color _statusColor(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.pending:
      return const Color(0xFFE67E22);
    case StaffRequestStatus.approved:
      return const Color(0xFF12B76A);
    case StaffRequestStatus.rejected:
      return const Color(0xFFD14343);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFF64748B);
    case StaffRequestStatus.submitted:
      return _requestBlue;
  }
}

Color _statusSoft(StaffRequestStatus status) {
  switch (status) {
    case StaffRequestStatus.pending:
      return const Color(0xFFFFF2E8);
    case StaffRequestStatus.approved:
      return const Color(0xFFEAFBF1);
    case StaffRequestStatus.rejected:
      return const Color(0xFFFFEEF1);
    case StaffRequestStatus.withdrawn:
      return const Color(0xFFF1F5F9);
    case StaffRequestStatus.submitted:
      return const Color(0xFFEAF2FF);
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

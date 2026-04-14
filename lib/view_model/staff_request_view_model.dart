import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/staff_portal_access.dart';
import '../model/staff_request_models.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../repository/staff_requests_repository.dart';
import 'providers.dart';

const _sentinel = Object();

class StaffRequestsState {
  const StaffRequestsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.records = const [],
    this.announcements = const [],
    this.trainings = const [],
    this.leaveTypes = const [],
    this.representatives = const [],
    this.transferReasons = const [],
    this.facilities = const [],
    this.departmentsByFacilityId = const {},
    this.leaveApprovalTasks = const [],
    this.transferApprovalTasks = const [],
    this.leaveBalanceDays = 18,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<StaffRequestRecord> records;
  final List<HomeAnnouncement> announcements;
  final List<HomeTrainingItem> trainings;
  final List<RequestLookupOption> leaveTypes;
  final List<RequestLookupOption> representatives;
  final List<RequestLookupOption> transferReasons;
  final List<RequestLookupOption> facilities;
  final Map<String, List<RequestLookupOption>> departmentsByFacilityId;
  final List<ApprovalTask> leaveApprovalTasks;
  final List<ApprovalTask> transferApprovalTasks;
  final int leaveBalanceDays;

  List<StaffRequestRecord> recordsFor(StaffRequestType type) {
    return records.where((record) => record.type == type).toList();
  }

  int countFor(StaffRequestType type) => recordsFor(type).length;

  int get pendingCount =>
      records.where((record) => record.status.isOpen).length;

  int get totalApprovalCount =>
      leaveApprovalTasks.length + transferApprovalTasks.length;

  List<ApprovalTask> get recentApprovalTasks {
    final sorted = [
      ...leaveApprovalTasks,
      ...transferApprovalTasks,
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));
    return sorted.take(4).toList();
  }

  int get activityCountThisMonth {
    final now = DateTime.now();
    return records
        .where(
          (record) =>
              record.type == StaffRequestType.activity &&
              record.submittedAt.year == now.year &&
              record.submittedAt.month == now.month,
        )
        .length;
  }

  List<StaffRequestRecord> get recentRecords {
    final sorted = [
      ...records,
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));
    return sorted.take(3).toList();
  }

  StaffRequestsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    List<StaffRequestRecord>? records,
    List<HomeAnnouncement>? announcements,
    List<HomeTrainingItem>? trainings,
    List<RequestLookupOption>? leaveTypes,
    List<RequestLookupOption>? representatives,
    List<RequestLookupOption>? transferReasons,
    List<RequestLookupOption>? facilities,
    Map<String, List<RequestLookupOption>>? departmentsByFacilityId,
    List<ApprovalTask>? leaveApprovalTasks,
    List<ApprovalTask>? transferApprovalTasks,
    int? leaveBalanceDays,
  }) {
    return StaffRequestsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      records: records ?? this.records,
      announcements: announcements ?? this.announcements,
      trainings: trainings ?? this.trainings,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      representatives: representatives ?? this.representatives,
      transferReasons: transferReasons ?? this.transferReasons,
      facilities: facilities ?? this.facilities,
      departmentsByFacilityId:
          departmentsByFacilityId ?? this.departmentsByFacilityId,
      leaveApprovalTasks: leaveApprovalTasks ?? this.leaveApprovalTasks,
      transferApprovalTasks:
          transferApprovalTasks ?? this.transferApprovalTasks,
      leaveBalanceDays: leaveBalanceDays ?? this.leaveBalanceDays,
    );
  }
}

class StaffRequestsViewModel extends Notifier<StaffRequestsState> {
  late StaffRequestsRepository _repository;
  late AuthRepository _authRepository;
  UserModel? _currentUser;
  late StaffPortalAccess _currentAccess;

  @override
  StaffRequestsState build() {
    _repository = ref.watch(staffRequestsRepositoryProvider);
    _authRepository = ref.watch(authRepositoryProvider);
    final authState = ref.watch(authViewModelProvider);
    _currentUser = authState.user;
    _currentAccess = StaffPortalAccess.fromUser(
      authState.user,
      preferredMode: authState.activePortalMode,
    );
    Future<void>.microtask(load);
    return const StaffRequestsState();
  }

  Future<void> load() async {
    final user = _currentUser ?? await _authRepository.getSavedUser();
    final mockRecords = _repository.buildMockRequests(user);
    final fallbackTraining = _repository.buildMockTraining();
    final announcements = _repository.buildAnnouncements(user);

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      announcements: announcements,
    );

    List<StaffRequestRecord> leaveRecords = [];
    List<StaffRequestRecord> transferRecords = [];
    List<HomeTrainingItem> trainings = fallbackTraining;
    List<RequestLookupOption> leaveTypes = _repository.buildMockLeaveTypes();
    List<RequestLookupOption> representatives = _repository
        .buildMockRepresentatives();
    List<RequestLookupOption> transferReasons = _repository
        .buildMockTransferReasons();
    final mockDirectory = _repository.buildMockFacilityDirectory();
    List<RequestLookupOption> facilities = mockDirectory.facilities;
    Map<String, List<RequestLookupOption>> departmentsByFacilityId =
        mockDirectory.departmentsByFacilityId;
    List<ApprovalTask> leaveApprovalTasks = const [];
    List<ApprovalTask> transferApprovalTasks = const [];
    String? errorMessage;

    if (user != null) {
      try {
        leaveRecords = await _repository.fetchLeaveRequests(user);
      } catch (error) {
        errorMessage ??= error.toString().replaceAll('Exception: ', '');
      }

      try {
        transferRecords = await _repository.fetchTransferRequests(user);
      } catch (_) {}

      try {
        trainings = await _repository.fetchUpcomingTraining(user);
      } catch (_) {}

      try {
        leaveTypes = await _repository.fetchLeaveTypes(user);
      } catch (_) {}

      try {
        representatives = await _repository.fetchRepresentatives();
      } catch (_) {}

      try {
        transferReasons = await _repository.fetchTransferReasons();
      } catch (_) {}

      try {
        final directory = await _repository.fetchFacilityDirectory();
        facilities = directory.facilities;
        departmentsByFacilityId = directory.departmentsByFacilityId;
      } catch (_) {}

      if (_currentAccess.hasApproverMode) {
        try {
          leaveApprovalTasks = await _repository.fetchLeaveApprovalTasks();
        } catch (_) {}

        try {
          transferApprovalTasks = await _repository
              .fetchTransferApprovalTasks();
        } catch (_) {}
      }
    }

    final records = <StaffRequestRecord>[
      ...mockRecords.where(
        (record) => record.type == StaffRequestType.activity,
      ),
      ...(leaveRecords.isEmpty
          ? mockRecords.where((record) => record.type == StaffRequestType.leave)
          : leaveRecords),
      ...(transferRecords.isEmpty
          ? mockRecords.where(
              (record) => record.type == StaffRequestType.transfer,
            )
          : transferRecords),
      ...mockRecords.where((record) => record.type == StaffRequestType.loan),
      ...mockRecords.where(
        (record) => record.type == StaffRequestType.sickLeave,
      ),
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));

    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
      records: records,
      announcements: announcements,
      trainings: trainings,
      leaveTypes: leaveTypes,
      representatives: representatives,
      transferReasons: transferReasons,
      facilities: facilities,
      departmentsByFacilityId: departmentsByFacilityId,
      leaveApprovalTasks: leaveApprovalTasks,
      transferApprovalTasks: transferApprovalTasks,
    );
  }

  Future<void> refresh() => load();

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<StaffRequestRecord> submitLeaveRequest(LeaveRequestDraft draft) async {
    final user = _currentUser ?? await _authRepository.getSavedUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final record = user == null || user.personalInformationId.trim().isEmpty
          ? _mockLeaveRecord(draft)
          : await _repository.submitLeaveRequest(user: user, draft: draft);
      _prependRecord(record);
      state = state.copyWith(isSubmitting: false);
      return record;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<StaffRequestRecord> submitTransferRequest(
    TransferRequestDraft draft,
  ) async {
    final user = _currentUser ?? await _authRepository.getSavedUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final record = user == null || user.personalInformationId.trim().isEmpty
          ? _mockTransferRecord(draft)
          : await _repository.submitTransferRequest(user: user, draft: draft);
      _prependRecord(record);
      state = state.copyWith(isSubmitting: false);
      return record;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<StaffRequestRecord> submitActivityRequest(
    ActivityRequestDraft draft,
  ) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final record = _mockActivityRecord(draft);
    _prependRecord(record);
    state = state.copyWith(isSubmitting: false);
    return record;
  }

  Future<StaffRequestRecord> submitLoanRequest(LoanRequestDraft draft) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final record = _mockLoanRecord(draft);
    _prependRecord(record);
    state = state.copyWith(isSubmitting: false);
    return record;
  }

  Future<StaffRequestRecord> withdrawRequest(StaffRequestRecord request) async {
    if (!request.status.isOpen) return request;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final updated = request.copyWith(
      status: StaffRequestStatus.withdrawn,
      stageLabel: 'Withdrawn',
      detailFields: _replaceStatusField(
        request.detailFields,
        StaffRequestStatus.withdrawn,
      ),
    );

    _replaceRecord(updated);
    state = state.copyWith(isSubmitting: false);
    return updated;
  }

  Future<ApprovalTask> loadApprovalTaskDetail(ApprovalTask task) async {
    if (task.type == ApproverRequestType.leave) {
      final personalInformationId = task.personalInformationId?.trim() ?? '';
      if (personalInformationId.isEmpty) {
        throw Exception('Leave approval details are unavailable.');
      }
      return _repository.fetchLeaveApprovalDetail(personalInformationId);
    }
    return task;
  }

  Future<String> performApprovalAction({
    required ApprovalTask task,
    required ApproverAction action,
    required String comment,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final message = switch (task.type) {
        ApproverRequestType.leave => await _repository.handleLeaveApproval(
          task: task,
          action: action,
          comment: comment,
          startDate: startDate,
          endDate: endDate,
        ),
        ApproverRequestType.transfer =>
          await _repository.handleTransferApproval(
            task: task,
            action: action,
            comment: comment,
          ),
      };

      await load();
      state = state.copyWith(isSubmitting: false);
      return message;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  void _prependRecord(StaffRequestRecord record) {
    final updated = [
      record,
      ...state.records,
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));
    state = state.copyWith(records: updated);
  }

  void _replaceRecord(StaffRequestRecord record) {
    final updated =
        state.records
            .map((item) => item.id == record.id ? record : item)
            .toList()
          ..sort(
            (first, second) => second.submittedAt.compareTo(first.submittedAt),
          );
    state = state.copyWith(records: updated);
  }

  List<RequestDetailField> _replaceStatusField(
    List<RequestDetailField> fields,
    StaffRequestStatus status,
  ) {
    final statusField = RequestDetailField(
      label: 'Status',
      value: status.label,
      status: status,
    );

    if (fields.any((field) => field.label.toLowerCase() == 'status')) {
      return fields
          .map(
            (field) =>
                field.label.toLowerCase() == 'status' ? statusField : field,
          )
          .toList();
    }

    return [...fields, statusField];
  }

  StaffRequestRecord _mockLeaveRecord(LeaveRequestDraft draft) {
    final now = DateTime.now();
    return StaffRequestRecord(
      id: 'leave-local-${now.microsecondsSinceEpoch}',
      type: StaffRequestType.leave,
      title: '${draft.leaveTypeLabel} Request',
      summary: draft.reason,
      status: StaffRequestStatus.submitted,
      submittedAt: now,
      referenceNumber:
          'LV-${now.year}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
      startDate: draft.startDate,
      endDate: draft.endDate,
      detailFields: [
        RequestDetailField(label: 'Leave Type', value: draft.leaveTypeLabel),
        RequestDetailField(
          label: 'Start Date',
          value: _displayDate(draft.startDate),
        ),
        if (draft.endDate != null)
          RequestDetailField(
            label: 'End Date',
            value: _displayDate(draft.endDate!),
          ),
        RequestDetailField(
          label: 'Contact on Leave',
          value: draft.contactOnLeave,
        ),
        if (draft.numberOfDays != null)
          RequestDetailField(
            label: 'Number of Days',
            value: '${draft.numberOfDays}',
          ),
        RequestDetailField(
          label: 'Representative',
          value: draft.representativeLabel ?? 'Not selected',
        ),
        if ((draft.placeToTravel ?? '').trim().isNotEmpty)
          RequestDetailField(
            label: 'Place To Travel',
            value: draft.placeToTravel!,
          ),
        RequestDetailField(label: 'Reason', value: draft.reason),
        const RequestDetailField(
          label: 'Status',
          value: 'Submitted',
          status: StaffRequestStatus.submitted,
        ),
      ],
    );
  }

  StaffRequestRecord _mockTransferRecord(TransferRequestDraft draft) {
    final now = DateTime.now();
    return StaffRequestRecord(
      id: 'transfer-local-${now.microsecondsSinceEpoch}',
      type: StaffRequestType.transfer,
      title: 'Transfer Request',
      summary: draft.reasonText,
      status: StaffRequestStatus.submitted,
      submittedAt: now,
      referenceNumber:
          'TR-${now.year}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
      location: draft.facilityLabel,
      detailFields: [
        RequestDetailField(
          label: 'Preferred Facility',
          value: draft.facilityLabel,
        ),
        RequestDetailField(
          label: 'Preferred Department',
          value: draft.departmentLabel ?? 'Not selected',
        ),
        RequestDetailField(label: 'Reason', value: draft.reasonLabel),
        RequestDetailField(
          label: 'Transfer Notes',
          value: draft.reasonText.isEmpty ? 'Not provided' : draft.reasonText,
        ),
        RequestDetailField(
          label: 'Preferred Transfer Date',
          value: _displayDate(draft.preferredTransferDate),
        ),
        const RequestDetailField(
          label: 'Status',
          value: 'Submitted',
          status: StaffRequestStatus.submitted,
        ),
      ],
    );
  }

  StaffRequestRecord _mockActivityRecord(ActivityRequestDraft draft) {
    final now = DateTime.now();
    return StaffRequestRecord(
      id: 'activity-local-${now.microsecondsSinceEpoch}',
      type: StaffRequestType.activity,
      title: draft.activityTitle,
      summary: draft.description,
      status: StaffRequestStatus.submitted,
      submittedAt: now,
      referenceNumber:
          'AC-${now.year}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
      startDate: draft.startDate,
      endDate: draft.endDate,
      location: draft.location,
      detailFields: [
        RequestDetailField(label: 'Activity', value: draft.activityTitle),
        RequestDetailField(label: 'Category', value: draft.category),
        RequestDetailField(label: 'Scope', value: draft.scope),
        RequestDetailField(label: 'Location', value: draft.location),
        RequestDetailField(label: 'Participants', value: draft.participants),
        RequestDetailField(label: 'Description', value: draft.description),
        const RequestDetailField(
          label: 'Status',
          value: 'Submitted',
          status: StaffRequestStatus.submitted,
        ),
      ],
    );
  }

  StaffRequestRecord _mockLoanRecord(LoanRequestDraft draft) {
    final now = DateTime.now();
    return StaffRequestRecord(
      id: 'loan-local-${now.microsecondsSinceEpoch}',
      type: StaffRequestType.loan,
      title: '${draft.loanType} Application',
      summary: draft.purpose,
      status: StaffRequestStatus.submitted,
      submittedAt: now,
      referenceNumber:
          'LN-${now.year}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
      detailFields: [
        RequestDetailField(label: 'Loan Type', value: draft.loanType),
        RequestDetailField(
          label: 'Requested Amount',
          value: draft.requestedAmount,
        ),
        RequestDetailField(
          label: 'Employer Status',
          value: draft.employerStatus,
        ),
        RequestDetailField(label: 'Monthly Salary', value: draft.monthlySalary),
        RequestDetailField(
          label: 'Repayment Period',
          value: '${draft.repaymentMonths} Months',
        ),
        RequestDetailField(label: 'Purpose', value: draft.purpose),
        const RequestDetailField(
          label: 'Status',
          value: 'Submitted',
          status: StaffRequestStatus.submitted,
        ),
      ],
    );
  }

  String _displayDate(DateTime value) {
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
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }
}

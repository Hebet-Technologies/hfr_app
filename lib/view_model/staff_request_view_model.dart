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
    this.resources = const [],
    this.trainings = const [],
    this.leaveTypes = const [],
    this.representatives = const [],
    this.transferReasons = const [],
    this.activityOptions = const [],
    this.loanBanks = const [],
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
  final List<HomeResource> resources;
  final List<HomeTrainingItem> trainings;
  final List<RequestLookupOption> leaveTypes;
  final List<RequestLookupOption> representatives;
  final List<RequestLookupOption> transferReasons;
  final List<RequestLookupOption> activityOptions;
  final List<RequestLookupOption> loanBanks;
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
    List<HomeResource>? resources,
    List<HomeTrainingItem>? trainings,
    List<RequestLookupOption>? leaveTypes,
    List<RequestLookupOption>? representatives,
    List<RequestLookupOption>? transferReasons,
    List<RequestLookupOption>? activityOptions,
    List<RequestLookupOption>? loanBanks,
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
      resources: resources ?? this.resources,
      trainings: trainings ?? this.trainings,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      representatives: representatives ?? this.representatives,
      transferReasons: transferReasons ?? this.transferReasons,
      activityOptions: activityOptions ?? this.activityOptions,
      loanBanks: loanBanks ?? this.loanBanks,
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
    _currentAccess = StaffPortalAccess.fromUser(authState.user);
    Future<void>.microtask(load);
    return const StaffRequestsState();
  }

  Future<void> load() async {
    final user = await _resolveCurrentUser();
    var announcements = const <HomeAnnouncement>[];
    var resources = const <HomeResource>[];

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      announcements: announcements,
      resources: resources,
    );

    List<StaffRequestRecord> leaveRecords = [];
    List<StaffRequestRecord> transferRecords = [];
    List<StaffRequestRecord> sickLeaveRecords = const [];
    List<StaffRequestRecord> loanRequestRecords = const [];
    List<HomeTrainingItem> trainings = const [];
    List<RequestLookupOption> leaveTypes = const [];
    List<RequestLookupOption> representatives = const [];
    List<RequestLookupOption> transferReasons = const [];
    List<RequestLookupOption> activityOptions = const [];
    List<RequestLookupOption> loanBanks = const [];
    List<RequestLookupOption> facilities = const [];
    Map<String, List<RequestLookupOption>> departmentsByFacilityId = const {};
    List<ApprovalTask> leaveApprovalTasks = const [];
    List<ApprovalTask> transferApprovalTasks = const [];
    String? errorMessage;

    Future<void> runSafely(
      Future<void> Function() task, {
      bool captureError = false,
    }) async {
      try {
        await task();
      } catch (error) {
        if (captureError) {
          errorMessage ??= error.toString().replaceAll('Exception: ', '');
        }
      }
    }

    if (user != null) {
      final canLoadSelfServiceRequests = _currentAccess.hasEmployeeProfile;

      if (canLoadSelfServiceRequests) {
        await Future.wait<void>([
          runSafely(() async {
            announcements = await _repository.fetchAnnouncements();
          }),
          runSafely(() async {
            resources = await _repository.fetchResources();
          }),
          runSafely(() async {
            leaveRecords = await _repository.fetchLeaveRequests(user);
          }, captureError: true),
          runSafely(() async {
            transferRecords = await _repository.fetchTransferRequests(user);
          }),
          runSafely(() async {
            trainings = await _repository.fetchUpcomingTraining(user);
          }),
          runSafely(() async {
            leaveTypes = await _repository.fetchLeaveTypes(user);
          }),
          runSafely(() async {
            representatives = await _repository.fetchRepresentatives();
          }),
          runSafely(() async {
            transferReasons = await _repository.fetchTransferReasons();
          }),
          // runSafely(() async {
          //   activityOptions = await _repository.fetchActivityOptions();
          // }),
          runSafely(() async {
            loanBanks = await _repository.fetchLoanBanks();
          }),
          runSafely(() async {
            final directory = await _repository.fetchFacilityDirectory();
            facilities = directory.facilities;
            departmentsByFacilityId = directory.departmentsByFacilityId;
          }),
          runSafely(() async {
            sickLeaveRecords = await _repository.fetchSickSheets(user);
          }),
          runSafely(() async {
            loanRequestRecords = await _repository.fetchLoanRequests(user);
          }),
        ]);

        leaveRecords = [...leaveRecords, ...sickLeaveRecords];
        transferRecords = [...transferRecords, ...loanRequestRecords];
      } else {
        await runSafely(() async {
          announcements = await _repository.fetchAnnouncements();
        });
        await runSafely(() async {
          resources = await _repository.fetchResources();
        });
      }

      if (_currentAccess.hasRequestApproverAccess) {
        await Future.wait<void>([
          runSafely(() async {
            leaveApprovalTasks = await _repository.fetchLeaveApprovalTasks();
          }),
          runSafely(() async {
            transferApprovalTasks = await _repository
                .fetchTransferApprovalTasks();
          }),
        ]);
      }
    }

    final records = <StaffRequestRecord>[
      ...leaveRecords,
      ...transferRecords,
    ]..sort((first, second) => second.submittedAt.compareTo(first.submittedAt));

    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
      records: records,
      announcements: announcements,
      resources: resources,
      trainings: trainings,
      leaveTypes: leaveTypes,
      representatives: representatives,
      transferReasons: transferReasons,
      activityOptions: activityOptions,
      loanBanks: loanBanks,
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

  Future<UserModel?> _resolveCurrentUser() async {
    final user = _currentUser ?? await _authRepository.getSavedUser();
    final resolved = await _authRepository.resolveEmployeeUser(user);
    _currentUser = resolved;
    _currentAccess = StaffPortalAccess.fromUser(resolved);
    return resolved;
  }

  String _missingEmployeeInformationMessage() {
    if (_currentAccess.hasRequestApproverAccess) {
      return 'This admin account is not linked to an employee profile, so it cannot submit employee leave requests. Switch to a staff account or use the approver workspace.';
    }
    return 'Your account is missing employee information. Please sign in again or contact support.';
  }

  Future<StaffRequestRecord> submitLeaveRequest(LeaveRequestDraft draft) async {
    final user = await _resolveCurrentUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // if (user == null || user.personalInformationId.trim().isEmpty) {
      //   throw Exception(_missingEmployeeInformationMessage());
      // }
      final record = await _repository.submitLeaveRequest(
        user: user!,
        draft: draft,
      );
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
    final user = await _resolveCurrentUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      if (user == null || user.personalInformationId.trim().isEmpty) {
        throw Exception(_missingEmployeeInformationMessage());
      }
      final record = await _repository.submitTransferRequest(
        user: user,
        draft: draft,
      );
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
    final user = await _resolveCurrentUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // if (user == null || user.payroll.trim().isEmpty) {
      //   throw Exception(_missingEmployeeInformationMessage());
      // }
      final record = await _repository.submitActivityRequest(
        user: user!,
        draft: draft,
      );
      _prependRecord(record);
      state = state.copyWith(isSubmitting: false);
      return record;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<StaffRequestRecord> submitLoanRequest(LoanRequestDraft draft) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final record = await _repository.submitLoanRequest(draft: draft);
      _prependRecord(record);
      state = state.copyWith(isSubmitting: false);
      return record;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<StaffRequestRecord> submitSickSheet(SickSheetDraft draft) async {
    final user = await _resolveCurrentUser();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // if (user == null || user.personalInformationId.trim().isEmpty) {
      //   throw Exception(_missingEmployeeInformationMessage());
      // }
      final record = await _repository.submitSickSheet(
        user: user!,
        draft: draft,
      );
      _prependRecord(record);
      state = state.copyWith(isSubmitting: false);
      return record;
    } catch (error) {
      final message = error.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<StaffRequestRecord> withdrawRequest(StaffRequestRecord request) async {
    if (!request.status.isOpen) return request;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (request.type == StaffRequestType.transfer) {
      try {
        await _repository.deleteTransferRequest(request);
        final updatedRecords = state.records
            .where((item) => item.id != request.id)
            .toList();
        state = state.copyWith(
          isSubmitting: false,
          records: updatedRecords,
          errorMessage: null,
        );
        return request.copyWith(
          status: StaffRequestStatus.withdrawn,
          stageLabel: 'Deleted',
          detailFields: _replaceStatusField(
            request.detailFields,
            StaffRequestStatus.withdrawn,
          ),
        );
      } catch (error) {
        final message = error.toString().replaceAll('Exception: ', '');
        state = state.copyWith(isSubmitting: false, errorMessage: message);
        rethrow;
      }
    }

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
}

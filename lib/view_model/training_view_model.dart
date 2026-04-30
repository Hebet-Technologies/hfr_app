import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/staff_portal_access.dart';
import '../model/training_models.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../repository/training_repository.dart';
import 'providers.dart';

const _sentinel = Object();

class TrainingState {
  const TrainingState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSubmittingApproval = false,
    this.errorMessage,
    this.latestTrainings = const [],
    this.myTrainings = const [],
    this.resources = const [],
    this.detailsById = const {},
    this.trainingRequests = const [],
    this.approvalQueue = const [],
    this.approvalDetailsById = const {},
  });

  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmittingApproval;
  final String? errorMessage;
  final List<TrainingProgram> latestTrainings;
  final List<TrainingProgram> myTrainings;
  final List<TrainingResource> resources;
  final Map<String, TrainingProgram> detailsById;
  final List<TrainingApprovalRecord> trainingRequests;
  final List<TrainingApprovalRecord> approvalQueue;
  final Map<String, TrainingApprovalRecord> approvalDetailsById;

  TrainingProgram resolveProgram(TrainingProgram training) {
    final directDetail = detailsById[training.id];
    if (directDetail != null) return directDetail;

    for (final item in myTrainings) {
      if (_programsMatch(item, training)) return item;
    }

    for (final item in latestTrainings) {
      if (_programsMatch(item, training)) return item;
    }

    return training;
  }

  TrainingApprovalRecord resolveApproval(TrainingApprovalRecord record) {
    final directDetail = approvalDetailsById[record.id];
    if (directDetail != null) return directDetail;

    for (final item in trainingRequests) {
      if (_approvalsMatch(item, record)) return item;
    }

    for (final item in approvalQueue) {
      if (_approvalsMatch(item, record)) return item;
    }

    return record;
  }

  TrainingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmittingApproval,
    Object? errorMessage = _sentinel,
    List<TrainingProgram>? latestTrainings,
    List<TrainingProgram>? myTrainings,
    List<TrainingResource>? resources,
    Map<String, TrainingProgram>? detailsById,
    List<TrainingApprovalRecord>? trainingRequests,
    List<TrainingApprovalRecord>? approvalQueue,
    Map<String, TrainingApprovalRecord>? approvalDetailsById,
  }) {
    return TrainingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmittingApproval: isSubmittingApproval ?? this.isSubmittingApproval,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      latestTrainings: latestTrainings ?? this.latestTrainings,
      myTrainings: myTrainings ?? this.myTrainings,
      resources: resources ?? this.resources,
      detailsById: detailsById ?? this.detailsById,
      trainingRequests: trainingRequests ?? this.trainingRequests,
      approvalQueue: approvalQueue ?? this.approvalQueue,
      approvalDetailsById: approvalDetailsById ?? this.approvalDetailsById,
    );
  }
}

class TrainingViewModel extends Notifier<TrainingState> {
  late TrainingRepository _repository;
  late AuthRepository _authRepository;
  late StaffPortalAccess _access;
  UserModel? _currentUser;

  @override
  TrainingState build() {
    _repository = ref.watch(trainingRepositoryProvider);
    _authRepository = ref.watch(authRepositoryProvider);
    final authState = ref.watch(authViewModelProvider);
    _access = ref.watch(staffPortalAccessProvider);
    _currentUser = authState.user;
    Future<void>.microtask(load);
    return const TrainingState();
  }

  Future<void> load() async {
    final user = _currentUser ?? await _authRepository.getSavedUser();

    state = state.copyWith(isLoading: true, errorMessage: null);

    List<TrainingProgram> myTrainings = const [];
    List<TrainingProgram> latestTrainings = const [];
    List<TrainingResource> resources = const [];
    List<TrainingApprovalRecord> trainingRequests = const [];
    List<TrainingApprovalRecord> approvalQueue = const [];
    String? errorMessage;

    if (user != null) {
      if (_access.hasEmployeeProfile) {
        try {
          myTrainings = await _repository.fetchMyTrainings(user);
        } catch (error) {
          errorMessage ??= _cleanMessage(error);
        }
      }

      try {
        latestTrainings = await _repository.fetchLatestTrainings(
          myTrainings: myTrainings,
        );
      } catch (_) {}

      if (_access.hasEmployeeProfile) {
        try {
          resources = await _repository.fetchResources(user);
        } catch (_) {}
      }

      if (_access.canViewTrainingRequests) {
        try {
          trainingRequests = await _repository.fetchTrainingRequests(
            publishedTrainings: latestTrainings,
          );
        } catch (error) {
          errorMessage ??= _cleanMessage(error);
        }
      }

      if (_access.canReviewTrainingRequests) {
        try {
          approvalQueue = await _repository.fetchApprovalQueue(
            publishedTrainings: latestTrainings,
          );
        } catch (error) {
          errorMessage ??= _cleanMessage(error);
        }
      }
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
      latestTrainings: latestTrainings,
      myTrainings: myTrainings,
      resources: resources,
      detailsById: const {},
      trainingRequests: trainingRequests,
      approvalQueue: approvalQueue,
      approvalDetailsById: const {},
    );
  }

  Future<void> refresh() => load();

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<TrainingProgram> loadDetail(TrainingProgram training) async {
    final current = state.resolveProgram(training);
    if ((current.trainingApplicationId ?? '').trim().isEmpty) {
      return current;
    }

    final cached = state.detailsById[current.id];
    if (cached != null) {
      return cached;
    }

    try {
      final detailed = await _repository.fetchTrainingDetails(current);
      _upsertTraining(detailed, addToMyTrainings: true);
      return detailed;
    } catch (error) {
      final message = _cleanMessage(error);
      state = state.copyWith(errorMessage: message);
      return current;
    }
  }

  Future<TrainingProgram> applyForTraining(TrainingProgram training) async {
    final user = _currentUser ?? await _authRepository.getSavedUser();
    final current = state.resolveProgram(training);

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final updated = user == null
          ? _repository.buildOptimisticAppliedProgram(current)
          : await _repository.applyForTraining(user: user, training: current);
      _upsertTraining(updated, addToMyTrainings: true);
      state = state.copyWith(isSubmitting: false);
      return updated;
    } catch (error) {
      final message = _cleanMessage(error);
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      rethrow;
    }
  }

  Future<TrainingApprovalRecord> loadApprovalDetail(
    TrainingApprovalRecord record,
  ) async {
    final current = state.resolveApproval(record);
    final cached = state.approvalDetailsById[current.id];
    if (cached != null) {
      return cached;
    }

    try {
      final detailed = await _repository.fetchApprovalDetails(
        current,
        fallbackProgram: _matchPublishedTraining(current),
      );
      _upsertApproval(detailed);
      return detailed;
    } catch (error) {
      final message = _cleanMessage(error);
      state = state.copyWith(errorMessage: message);
      return current;
    }
  }

  Future<String> submitApprovalAction({
    required TrainingApprovalRecord record,
    required String comment,
  }) async {
    final current = state.resolveApproval(record);

    state = state.copyWith(isSubmittingApproval: true, errorMessage: null);
    try {
      final message = await _repository.submitApprovalAction(
        record: current,
        comment: comment,
      );
      final nextQueue = state.approvalQueue
          .where((item) => !_approvalsMatch(item, current))
          .toList();
      final nextDetails = Map<String, TrainingApprovalRecord>.from(
        state.approvalDetailsById,
      )..removeWhere((_, value) => _approvalsMatch(value, current));
      final nextRequests = state.trainingRequests.map((item) {
        if (_approvalsMatch(item, current)) {
          return item.copyWith(rawStatus: _nextApprovalStatus(current));
        }
        return item;
      }).toList();
      state = state.copyWith(
        isSubmittingApproval: false,
        trainingRequests: nextRequests,
        approvalQueue: nextQueue,
        approvalDetailsById: nextDetails,
      );
      return message;
    } catch (error) {
      final message = _cleanMessage(error);
      state = state.copyWith(
        isSubmittingApproval: false,
        errorMessage: message,
      );
      rethrow;
    }
  }

  void _upsertTraining(
    TrainingProgram updated, {
    required bool addToMyTrainings,
  }) {
    final nextLatest = _replaceOrInsert(
      state.latestTrainings,
      updated,
      insertIfMissing: false,
    );
    final nextMine = _replaceOrInsert(
      state.myTrainings,
      updated,
      insertIfMissing: addToMyTrainings,
    );
    final nextDetails = Map<String, TrainingProgram>.from(state.detailsById)
      ..[updated.id] = updated;

    state = state.copyWith(
      latestTrainings: nextLatest,
      myTrainings: nextMine,
      detailsById: nextDetails,
    );
  }

  void _upsertApproval(TrainingApprovalRecord updated) {
    var didUpdateRequests = false;
    final nextRequests = state.trainingRequests.map((item) {
      if (_approvalsMatch(item, updated)) {
        didUpdateRequests = true;
        return updated;
      }
      return item;
    }).toList();
    final nextQueue = state.approvalQueue.map((item) {
      if (_approvalsMatch(item, updated)) {
        return updated;
      }
      return item;
    }).toList();
    final nextDetails = Map<String, TrainingApprovalRecord>.from(
      state.approvalDetailsById,
    )..[updated.id] = updated;

    state = state.copyWith(
      trainingRequests: didUpdateRequests
          ? nextRequests
          : state.trainingRequests,
      approvalQueue: nextQueue,
      approvalDetailsById: nextDetails,
    );
  }

  List<TrainingProgram> _replaceOrInsert(
    List<TrainingProgram> source,
    TrainingProgram updated, {
    required bool insertIfMissing,
  }) {
    var didReplace = false;
    final next = source.map((item) {
      if (_programsMatch(item, updated)) {
        didReplace = true;
        return item.copyWith(
          id: updated.id,
          title: updated.title,
          trainingType: updated.trainingType,
          organizer: updated.organizer,
          location: updated.location,
          description: updated.description,
          targetCadres: updated.targetCadres,
          badge: updated.badge,
          status: updated.status,
          availableSlots: updated.availableSlots,
          participantCount: updated.participantCount,
          resources: updated.resources,
          startDate: updated.startDate,
          endDate: updated.endDate,
          trainingApplicationId: updated.trainingApplicationId,
          developmentPlanVendorId: updated.developmentPlanVendorId,
          shortCourseDescriptionId: updated.shortCourseDescriptionId,
          programId: updated.programId,
          instituteId: updated.instituteId,
          educationLevelId: updated.educationLevelId,
          educationLevelName: updated.educationLevelName,
          workingStationName: updated.workingStationName,
          batchYear: updated.batchYear,
          workingExperienceLabel: updated.workingExperienceLabel,
          isLive: updated.isLive,
          canApplyLive: updated.canApplyLive,
        );
      }
      return item;
    }).toList();

    if (!didReplace && insertIfMissing) {
      next.add(updated);
    }

    next.sort(_sortProgramsByDate);
    return next;
  }

  String _cleanMessage(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }

  TrainingProgram? _matchPublishedTraining(TrainingApprovalRecord record) {
    final recordTitle = record.title.trim().toLowerCase();
    if (recordTitle.isEmpty) return null;

    for (final item in state.latestTrainings) {
      if (item.title.trim().toLowerCase() == recordTitle) {
        return item;
      }
    }

    return null;
  }
}

bool _programsMatch(TrainingProgram first, TrainingProgram second) {
  if (first.id == second.id) return true;

  final firstApplicationId = (first.trainingApplicationId ?? '').trim();
  final secondApplicationId = (second.trainingApplicationId ?? '').trim();
  if (firstApplicationId.isNotEmpty &&
      secondApplicationId.isNotEmpty &&
      firstApplicationId == secondApplicationId) {
    return true;
  }

  final firstDevelopmentPlanId = (first.developmentPlanVendorId ?? '').trim();
  final secondDevelopmentPlanId = (second.developmentPlanVendorId ?? '').trim();
  if (firstDevelopmentPlanId.isNotEmpty &&
      secondDevelopmentPlanId.isNotEmpty &&
      firstDevelopmentPlanId == secondDevelopmentPlanId) {
    return true;
  }

  final firstShortCourseId = (first.shortCourseDescriptionId ?? '').trim();
  final secondShortCourseId = (second.shortCourseDescriptionId ?? '').trim();
  if (firstShortCourseId.isNotEmpty &&
      secondShortCourseId.isNotEmpty &&
      firstShortCourseId == secondShortCourseId) {
    return true;
  }

  return false;
}

int _sortProgramsByDate(TrainingProgram first, TrainingProgram second) {
  final firstDate = first.startDate ?? first.endDate ?? DateTime(2100);
  final secondDate = second.startDate ?? second.endDate ?? DateTime(2100);
  return firstDate.compareTo(secondDate);
}

String _nextApprovalStatus(TrainingApprovalRecord record) {
  final current = record.rawStatus.trim().toUpperCase();
  if (current == 'FORWARDED') {
    return 'AWAITING_TRAINING_CONTRACT';
  }
  return 'FORWARDED';
}

bool _approvalsMatch(
  TrainingApprovalRecord first,
  TrainingApprovalRecord second,
) {
  if (first.id == second.id) return true;
  return first.trainingApplicationId.trim().isNotEmpty &&
      first.trainingApplicationId.trim() == second.trainingApplicationId.trim();
}

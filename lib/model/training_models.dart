enum TrainingParticipationStatus {
  notApplied,
  pending,
  approved,
  rejected,
  completed,
}

extension TrainingParticipationStatusX on TrainingParticipationStatus {
  String get label {
    switch (this) {
      case TrainingParticipationStatus.notApplied:
        return 'Not Applied';
      case TrainingParticipationStatus.pending:
        return 'Pending';
      case TrainingParticipationStatus.approved:
        return 'Approved';
      case TrainingParticipationStatus.rejected:
        return 'Rejected';
      case TrainingParticipationStatus.completed:
        return 'Completed';
    }
  }

  bool get isApplied => this != TrainingParticipationStatus.notApplied;

  static TrainingParticipationStatus fromRaw(dynamic rawStatus) {
    final value = rawStatus?.toString().trim().toUpperCase() ?? '';
    switch (value) {
      case 'PENDING':
      case 'REQUESTED':
      case 'FORWARDED':
      case 'SUBMITTED':
        return TrainingParticipationStatus.pending;
      case 'APPROVED':
        return TrainingParticipationStatus.approved;
      case 'REJECTED':
      case 'DENIED':
        return TrainingParticipationStatus.rejected;
      case 'COMPLETED':
        return TrainingParticipationStatus.completed;
      default:
        return TrainingParticipationStatus.notApplied;
    }
  }
}

class TrainingResource {
  const TrainingResource({
    required this.id,
    required this.title,
    required this.sizeLabel,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.isLive = false,
  });

  final String id;
  final String title;
  final String sizeLabel;
  final String fileName;
  final String filePath;
  final String fileType;
  final bool isLive;

  TrainingResource copyWith({
    String? id,
    String? title,
    String? sizeLabel,
    String? fileName,
    String? filePath,
    String? fileType,
    bool? isLive,
  }) {
    return TrainingResource(
      id: id ?? this.id,
      title: title ?? this.title,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      isLive: isLive ?? this.isLive,
    );
  }
}

class TrainingProgram {
  const TrainingProgram({
    required this.id,
    required this.title,
    required this.trainingType,
    required this.organizer,
    required this.location,
    required this.description,
    required this.targetCadres,
    required this.badge,
    required this.status,
    required this.availableSlots,
    required this.participantCount,
    required this.resources,
    this.startDate,
    this.endDate,
    this.trainingApplicationId,
    this.developmentPlanVendorId,
    this.shortCourseDescriptionId,
    this.programId,
    this.instituteId,
    this.educationLevelId,
    this.educationLevelName,
    this.workingStationName,
    this.batchYear,
    this.workingExperienceLabel,
    this.isLive = false,
    this.canApplyLive = false,
  });

  final String id;
  final String title;
  final String trainingType;
  final String organizer;
  final String location;
  final String description;
  final List<String> targetCadres;
  final String badge;
  final TrainingParticipationStatus status;
  final int availableSlots;
  final int participantCount;
  final List<TrainingResource> resources;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? trainingApplicationId;
  final String? developmentPlanVendorId;
  final String? shortCourseDescriptionId;
  final String? programId;
  final String? instituteId;
  final String? educationLevelId;
  final String? educationLevelName;
  final String? workingStationName;
  final String? batchYear;
  final String? workingExperienceLabel;
  final bool isLive;
  final bool canApplyLive;

  bool get isApplied => status.isApplied;

  TrainingProgram copyWith({
    String? id,
    String? title,
    String? trainingType,
    String? organizer,
    String? location,
    String? description,
    List<String>? targetCadres,
    String? badge,
    TrainingParticipationStatus? status,
    int? availableSlots,
    int? participantCount,
    List<TrainingResource>? resources,
    DateTime? startDate,
    DateTime? endDate,
    String? trainingApplicationId,
    String? developmentPlanVendorId,
    String? shortCourseDescriptionId,
    String? programId,
    String? instituteId,
    String? educationLevelId,
    String? educationLevelName,
    String? workingStationName,
    String? batchYear,
    String? workingExperienceLabel,
    bool? isLive,
    bool? canApplyLive,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      title: title ?? this.title,
      trainingType: trainingType ?? this.trainingType,
      organizer: organizer ?? this.organizer,
      location: location ?? this.location,
      description: description ?? this.description,
      targetCadres: targetCadres ?? this.targetCadres,
      badge: badge ?? this.badge,
      status: status ?? this.status,
      availableSlots: availableSlots ?? this.availableSlots,
      participantCount: participantCount ?? this.participantCount,
      resources: resources ?? this.resources,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trainingApplicationId:
          trainingApplicationId ?? this.trainingApplicationId,
      developmentPlanVendorId:
          developmentPlanVendorId ?? this.developmentPlanVendorId,
      shortCourseDescriptionId:
          shortCourseDescriptionId ?? this.shortCourseDescriptionId,
      programId: programId ?? this.programId,
      instituteId: instituteId ?? this.instituteId,
      educationLevelId: educationLevelId ?? this.educationLevelId,
      educationLevelName: educationLevelName ?? this.educationLevelName,
      workingStationName: workingStationName ?? this.workingStationName,
      batchYear: batchYear ?? this.batchYear,
      workingExperienceLabel:
          workingExperienceLabel ?? this.workingExperienceLabel,
      isLive: isLive ?? this.isLive,
      canApplyLive: canApplyLive ?? this.canApplyLive,
    );
  }
}

class TrainingApprovalRecord {
  const TrainingApprovalRecord({
    required this.id,
    required this.trainingApplicationId,
    required this.trainingAppStatusId,
    required this.title,
    required this.applicantName,
    required this.applicantPhone,
    required this.applicantEmail,
    required this.applicantGender,
    required this.vendorName,
    required this.cadreName,
    required this.instituteName,
    required this.educationLevelName,
    required this.batchYear,
    required this.workingStationName,
    required this.rawStatus,
    this.startDate,
    this.endDate,
    this.resources = const [],
    this.isLive = false,
  });

  final String id;
  final String trainingApplicationId;
  final String trainingAppStatusId;
  final String title;
  final String applicantName;
  final String applicantPhone;
  final String applicantEmail;
  final String applicantGender;
  final String vendorName;
  final String cadreName;
  final String instituteName;
  final String educationLevelName;
  final String batchYear;
  final String workingStationName;
  final String rawStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TrainingResource> resources;
  final bool isLive;

  TrainingParticipationStatus get status =>
      TrainingParticipationStatusX.fromRaw(rawStatus);

  String get workflowLabel {
    switch (rawStatus.trim().toUpperCase()) {
      case 'REQUESTED':
        return 'Pending Review';
      case 'FORWARDED':
        return 'Forwarded for Approval';
      case 'AWAITING_TRAINING_CONTRACT':
        return 'Approved for Contract';
      case 'AWAITING_TRAINING_CONTRACT_APPROVAL':
        return 'Awaiting Contract Approval';
      case 'TRAINING_CONTRACT_APPROVED':
        return 'Contract Approved';
      default:
        final normalized = rawStatus.trim();
        if (normalized.isEmpty) return 'Pending Review';
        return normalized
            .split('_')
            .map((part) {
              if (part.isEmpty) return part;
              return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
            })
            .join(' ');
    }
  }

  TrainingApprovalRecord copyWith({
    String? id,
    String? trainingApplicationId,
    String? trainingAppStatusId,
    String? title,
    String? applicantName,
    String? applicantPhone,
    String? applicantEmail,
    String? applicantGender,
    String? vendorName,
    String? cadreName,
    String? instituteName,
    String? educationLevelName,
    String? batchYear,
    String? workingStationName,
    String? rawStatus,
    DateTime? startDate,
    DateTime? endDate,
    List<TrainingResource>? resources,
    bool? isLive,
  }) {
    return TrainingApprovalRecord(
      id: id ?? this.id,
      trainingApplicationId:
          trainingApplicationId ?? this.trainingApplicationId,
      trainingAppStatusId: trainingAppStatusId ?? this.trainingAppStatusId,
      title: title ?? this.title,
      applicantName: applicantName ?? this.applicantName,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantGender: applicantGender ?? this.applicantGender,
      vendorName: vendorName ?? this.vendorName,
      cadreName: cadreName ?? this.cadreName,
      instituteName: instituteName ?? this.instituteName,
      educationLevelName: educationLevelName ?? this.educationLevelName,
      batchYear: batchYear ?? this.batchYear,
      workingStationName: workingStationName ?? this.workingStationName,
      rawStatus: rawStatus ?? this.rawStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      resources: resources ?? this.resources,
      isLive: isLive ?? this.isLive,
    );
  }
}

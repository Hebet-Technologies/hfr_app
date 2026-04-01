enum StaffRequestType { activity, leave, transfer, loan, sickLeave }

extension StaffRequestTypeX on StaffRequestType {
  String get label {
    switch (this) {
      case StaffRequestType.activity:
        return 'Activity';
      case StaffRequestType.leave:
        return 'Leave';
      case StaffRequestType.transfer:
        return 'Transfer';
      case StaffRequestType.loan:
        return 'Loan';
      case StaffRequestType.sickLeave:
        return 'Sick Leave';
    }
  }

  String get pluralLabel {
    switch (this) {
      case StaffRequestType.activity:
        return 'Activity Requests';
      case StaffRequestType.leave:
        return 'Leave Requests';
      case StaffRequestType.transfer:
        return 'Transfer Requests';
      case StaffRequestType.loan:
        return 'Loan Applications';
      case StaffRequestType.sickLeave:
        return 'Sick Leave Submissions';
    }
  }

  String get actionLabel {
    switch (this) {
      case StaffRequestType.activity:
        return 'Register Activity';
      case StaffRequestType.leave:
        return 'Apply Leave';
      case StaffRequestType.transfer:
        return 'Request Transfer';
      case StaffRequestType.loan:
        return 'Apply for Loan';
      case StaffRequestType.sickLeave:
        return 'Submit Sick Leave';
    }
  }
}

enum StaffRequestStatus { pending, approved, rejected, withdrawn, submitted }

extension StaffRequestStatusX on StaffRequestStatus {
  String get label {
    switch (this) {
      case StaffRequestStatus.pending:
        return 'Pending';
      case StaffRequestStatus.approved:
        return 'Approved';
      case StaffRequestStatus.rejected:
        return 'Rejected';
      case StaffRequestStatus.withdrawn:
        return 'Withdrawn';
      case StaffRequestStatus.submitted:
        return 'Submitted';
    }
  }

  bool get isOpen {
    return this == StaffRequestStatus.pending ||
        this == StaffRequestStatus.submitted;
  }
}

class RequestLookupOption {
  const RequestLookupOption({
    required this.id,
    required this.label,
    this.subtitle,
  });

  final String id;
  final String label;
  final String? subtitle;
}

class RequestDetailField {
  const RequestDetailField({
    required this.label,
    required this.value,
    this.status,
  });

  final String label;
  final String value;
  final StaffRequestStatus? status;
}

class StaffRequestRecord {
  const StaffRequestRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.status,
    required this.submittedAt,
    required this.detailFields,
    this.referenceNumber,
    this.startDate,
    this.endDate,
    this.location,
    this.attachmentName,
    this.stageLabel,
    this.isLive = false,
  });

  final String id;
  final StaffRequestType type;
  final String title;
  final String summary;
  final StaffRequestStatus status;
  final DateTime submittedAt;
  final List<RequestDetailField> detailFields;
  final String? referenceNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? attachmentName;
  final String? stageLabel;
  final bool isLive;

  StaffRequestRecord copyWith({
    String? id,
    StaffRequestType? type,
    String? title,
    String? summary,
    StaffRequestStatus? status,
    DateTime? submittedAt,
    List<RequestDetailField>? detailFields,
    String? referenceNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? attachmentName,
    String? stageLabel,
    bool? isLive,
  }) {
    return StaffRequestRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      detailFields: detailFields ?? this.detailFields,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      attachmentName: attachmentName ?? this.attachmentName,
      stageLabel: stageLabel ?? this.stageLabel,
      isLive: isLive ?? this.isLive,
    );
  }
}

enum ApproverRequestType { leave, transfer }

extension ApproverRequestTypeX on ApproverRequestType {
  String get label {
    switch (this) {
      case ApproverRequestType.leave:
        return 'Leave Approval';
      case ApproverRequestType.transfer:
        return 'Transfer Approval';
    }
  }

  String get pluralLabel {
    switch (this) {
      case ApproverRequestType.leave:
        return 'Leave Approvals';
      case ApproverRequestType.transfer:
        return 'Transfer Approvals';
    }
  }
}

enum ApproverAction { forward, approve, deny }

extension ApproverActionX on ApproverAction {
  String get label {
    switch (this) {
      case ApproverAction.forward:
        return 'Forward';
      case ApproverAction.approve:
        return 'Approve';
      case ApproverAction.deny:
        return 'Deny';
    }
  }
}

class ApprovalCommentRecord {
  const ApprovalCommentRecord({
    required this.stage,
    required this.comment,
    this.reason,
    this.additionalComment,
  });

  final String stage;
  final String comment;
  final String? reason;
  final String? additionalComment;
}

class ApprovalTask {
  const ApprovalTask({
    required this.id,
    required this.requestId,
    required this.type,
    required this.title,
    required this.subjectName,
    required this.summary,
    required this.status,
    required this.submittedAt,
    this.referenceNumber,
    this.attachmentName,
    this.personalInformationId,
    this.employmentStatusId,
    this.numberOfDays,
    this.parentStageId,
    this.rawStatus,
    this.proposedStartDate,
    this.proposedEndDate,
    this.startDate,
    this.endDate,
    this.detailFields = const [],
    this.commentHistory = const [],
  });

  final String id;
  final String requestId;
  final ApproverRequestType type;
  final String title;
  final String subjectName;
  final String summary;
  final StaffRequestStatus status;
  final DateTime submittedAt;
  final String? referenceNumber;
  final String? attachmentName;
  final String? personalInformationId;
  final String? employmentStatusId;
  final int? numberOfDays;
  final String? parentStageId;
  final String? rawStatus;
  final DateTime? proposedStartDate;
  final DateTime? proposedEndDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<RequestDetailField> detailFields;
  final List<ApprovalCommentRecord> commentHistory;

  bool get isFinalStage => (parentStageId ?? '').trim().isEmpty;

  bool get isForwarded => (rawStatus ?? '').toUpperCase() == 'FORWARDED';

  ApprovalTask copyWith({
    String? id,
    String? requestId,
    ApproverRequestType? type,
    String? title,
    String? subjectName,
    String? summary,
    StaffRequestStatus? status,
    DateTime? submittedAt,
    String? referenceNumber,
    String? attachmentName,
    String? personalInformationId,
    String? employmentStatusId,
    int? numberOfDays,
    String? parentStageId,
    String? rawStatus,
    DateTime? proposedStartDate,
    DateTime? proposedEndDate,
    DateTime? startDate,
    DateTime? endDate,
    List<RequestDetailField>? detailFields,
    List<ApprovalCommentRecord>? commentHistory,
  }) {
    return ApprovalTask(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      type: type ?? this.type,
      title: title ?? this.title,
      subjectName: subjectName ?? this.subjectName,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      attachmentName: attachmentName ?? this.attachmentName,
      personalInformationId:
          personalInformationId ?? this.personalInformationId,
      employmentStatusId: employmentStatusId ?? this.employmentStatusId,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      parentStageId: parentStageId ?? this.parentStageId,
      rawStatus: rawStatus ?? this.rawStatus,
      proposedStartDate: proposedStartDate ?? this.proposedStartDate,
      proposedEndDate: proposedEndDate ?? this.proposedEndDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      detailFields: detailFields ?? this.detailFields,
      commentHistory: commentHistory ?? this.commentHistory,
    );
  }
}

class HomeAnnouncement {
  const HomeAnnouncement({
    required this.title,
    required this.subtitle,
    required this.caption,
  });

  final String title;
  final String subtitle;
  final String caption;
}

class HomeTrainingItem {
  const HomeTrainingItem({
    required this.title,
    required this.location,
    required this.dateLabel,
    required this.tag,
  });

  final String title;
  final String location;
  final String dateLabel;
  final String tag;
}

class FacilityDirectory {
  const FacilityDirectory({
    required this.facilities,
    required this.departmentsByFacilityId,
  });

  final List<RequestLookupOption> facilities;
  final Map<String, List<RequestLookupOption>> departmentsByFacilityId;
}

class LeaveRequestDraft {
  const LeaveRequestDraft({
    required this.leaveTypeId,
    required this.leaveTypeLabel,
    required this.startDate,
    required this.endDate,
    required this.contactOnLeave,
    required this.reason,
    this.representativeId,
    this.representativeLabel,
    this.placeToTravel,
  });

  final String leaveTypeId;
  final String leaveTypeLabel;
  final DateTime startDate;
  final DateTime endDate;
  final String contactOnLeave;
  final String reason;
  final String? representativeId;
  final String? representativeLabel;
  final String? placeToTravel;
}

class TransferRequestDraft {
  const TransferRequestDraft({
    required this.facilityId,
    required this.facilityLabel,
    required this.reasonId,
    required this.reasonLabel,
    required this.reasonText,
    required this.preferredTransferDate,
    this.departmentId,
    this.departmentLabel,
  });

  final String facilityId;
  final String facilityLabel;
  final String reasonId;
  final String reasonLabel;
  final String reasonText;
  final DateTime preferredTransferDate;
  final String? departmentId;
  final String? departmentLabel;
}

class ActivityRequestDraft {
  const ActivityRequestDraft({
    required this.activityTitle,
    required this.category,
    required this.scope,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.description,
  });

  final String activityTitle;
  final String category;
  final String scope;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String participants;
  final String description;
}

class LoanRequestDraft {
  const LoanRequestDraft({
    required this.loanType,
    required this.requestedAmount,
    required this.employerStatus,
    required this.monthlySalary,
    required this.repaymentMonths,
    required this.purpose,
  });

  final String loanType;
  final String requestedAmount;
  final String employerStatus;
  final String monthlySalary;
  final String repaymentMonths;
  final String purpose;
}

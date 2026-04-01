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

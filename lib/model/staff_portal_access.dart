import 'user_model.dart';

enum StaffPortalMode { employee, approver }

extension StaffPortalModeX on StaffPortalMode {
  String get storageValue {
    switch (this) {
      case StaffPortalMode.employee:
        return 'employee';
      case StaffPortalMode.approver:
        return 'approver';
    }
  }

  String get label {
    switch (this) {
      case StaffPortalMode.employee:
        return 'Employee';
      case StaffPortalMode.approver:
        return 'Approver';
    }
  }
}

class StaffPortalAccess {
  StaffPortalAccess._({
    required this.activeMode,
    required this.hasEmployeeProfile,
    required this.hasApproverMode,
    required this.roles,
    required this.permissions,
    required this.isAdmin,
    required this.canForwardLeave,
    required this.canApproveLeave,
    required this.canDenyLeave,
    required this.canForwardTransfer,
    required this.canApproveTransfer,
    required this.canDenyTransfer,
    required this.canViewTrainingRequests,
    required this.canForwardTrainingRequests,
    required this.canApproveTrainingRequests,
    required this.canDenyTrainingRequests,
    required this.canCreateTrainingResult,
    required this.canCreatePositionRequest,
  });

  factory StaffPortalAccess.fromUser(UserModel? user) {
    final roles = [...user?.roles ?? const <String>[]];
    final permissions = [...user?.permissions ?? const <String>[]];
    final values = [...roles, ...permissions].map(_normalize).toList();
    final hasEmployeeProfile =
        user?.personalInformationId.trim().isNotEmpty == true;

    final isAdmin = _containsAny(values, const [
      'role admin',
      'role national',
      'administrator',
      'admin',
      'super admin',
      'human resource',
      'hr admin',
    ]);

    final canForwardLeave =
        isAdmin || _containsAny(values, const ['forward leave request']);
    final canApproveLeave =
        isAdmin || _containsAny(values, const ['approve leave request']);
    final canDenyLeave =
        isAdmin ||
        _containsAny(values, const [
          'deny leave request',
          'denied leave request',
        ]);
    final canForwardTransfer =
        isAdmin ||
        _containsAny(values, const [
          'forward staff request',
          'forward transfer request',
        ]);
    final canApproveTransfer =
        isAdmin ||
        _containsAny(values, const [
          'approve staff request',
          'approve transfer request',
        ]);
    final canDenyTransfer =
        isAdmin ||
        _containsAny(values, const [
          'deny staff request',
          'denied staff request',
        ]);
    final canViewTrainingRequests =
        isAdmin || _containsAny(values, const ['view training request']);
    final canForwardTrainingRequests =
        isAdmin || _containsAny(values, const ['forward training request']);
    final canApproveTrainingRequests =
        isAdmin || _containsAny(values, const ['approve training request']);
    final canDenyTrainingRequests =
        isAdmin ||
        _containsAny(values, const [
          'deny training request',
          'denied training request',
        ]);
    final canCreateTrainingResult =
        isAdmin || _containsAny(values, const ['create training result']);
    final canCreatePositionRequest =
        isAdmin || _containsAny(values, const ['create position request']);

    final hasApproverMode =
        canForwardLeave ||
        canApproveLeave ||
        canDenyLeave ||
        canForwardTransfer ||
        canApproveTransfer ||
        canDenyTransfer ||
        canViewTrainingRequests ||
        canForwardTrainingRequests ||
        canApproveTrainingRequests ||
        canDenyTrainingRequests ||
        canCreateTrainingResult;

    return StaffPortalAccess._(
      activeMode: hasApproverMode
          ? StaffPortalMode.approver
          : StaffPortalMode.employee,
      hasEmployeeProfile: hasEmployeeProfile,
      hasApproverMode: hasApproverMode,
      roles: roles,
      permissions: permissions,
      isAdmin: isAdmin,
      canForwardLeave: canForwardLeave,
      canApproveLeave: canApproveLeave,
      canDenyLeave: canDenyLeave,
      canForwardTransfer: canForwardTransfer,
      canApproveTransfer: canApproveTransfer,
      canDenyTransfer: canDenyTransfer,
      canViewTrainingRequests: canViewTrainingRequests,
      canForwardTrainingRequests: canForwardTrainingRequests,
      canApproveTrainingRequests: canApproveTrainingRequests,
      canDenyTrainingRequests: canDenyTrainingRequests,
      canCreateTrainingResult: canCreateTrainingResult,
      canCreatePositionRequest: canCreatePositionRequest,
    );
  }

  final StaffPortalMode activeMode;
  final bool hasEmployeeProfile;
  final bool hasApproverMode;
  final List<String> roles;
  final List<String> permissions;
  final bool isAdmin;
  final bool canForwardLeave;
  final bool canApproveLeave;
  final bool canDenyLeave;
  final bool canForwardTransfer;
  final bool canApproveTransfer;
  final bool canDenyTransfer;
  final bool canViewTrainingRequests;
  final bool canForwardTrainingRequests;
  final bool canApproveTrainingRequests;
  final bool canDenyTrainingRequests;
  final bool canCreateTrainingResult;
  final bool canCreatePositionRequest;

  bool get isEmployeeMode => activeMode == StaffPortalMode.employee;

  bool get isApproverMode => hasApproverMode;

  bool get canReviewTrainingRequests =>
      canApproveTrainingRequests || canCreateTrainingResult;

  bool get hasRequestApproverAccess =>
      canForwardLeave ||
      canApproveLeave ||
      canDenyLeave ||
      canForwardTransfer ||
      canApproveTransfer ||
      canDenyTransfer;

  List<StaffPortalMode> get availableModes {
    return hasApproverMode
        ? const [StaffPortalMode.employee, StaffPortalMode.approver]
        : const [StaffPortalMode.employee];
  }

  String get activeModeLabel => activeMode.label;

  String get modeSummary {
    switch (activeMode) {
      case StaffPortalMode.employee:
        return 'Create and track your own staff requests.';
      case StaffPortalMode.approver:
        return 'Review, forward, approve, or deny other staff requests.';
    }
  }

  bool allows(String permission) {
    if (isAdmin) return true;
    final values = [...roles, ...permissions].map(_normalize).toList();
    return _containsAny(values, [permission]);
  }

  static bool _containsAny(List<String> haystack, List<String> needles) {
    return haystack.any(
      (value) => needles.any((needle) => value.contains(_normalize(needle))),
    );
  }

  static String _normalize(String value) {
    final buffer = StringBuffer();
    var previousWasSpace = false;

    for (final codeUnit in value.toLowerCase().codeUnits) {
      final isLetter = codeUnit >= 97 && codeUnit <= 122;
      final isNumber = codeUnit >= 48 && codeUnit <= 57;
      if (isLetter || isNumber) {
        buffer.writeCharCode(codeUnit);
        previousWasSpace = false;
      } else if (!previousWasSpace) {
        buffer.write(' ');
        previousWasSpace = true;
      }
    }

    return buffer.toString().trim();
  }
}

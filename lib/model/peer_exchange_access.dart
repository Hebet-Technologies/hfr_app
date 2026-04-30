import 'user_model.dart';

enum PeerExchangePersona { staff, approver, moderator, hrAdmin }

class PeerExchangeAccess {
  PeerExchangeAccess._({
    required this.userId,
    required this.roles,
    required this.permissions,
    required this.persona,
  });

  factory PeerExchangeAccess.fromUser(
    UserModel? user, {
    bool? isApproverOverride,
  }) {
    final roles = [...user?.roles ?? const <String>[]];
    final permissions = [...user?.permissions ?? const <String>[]];
    final values = [...roles, ...permissions].map(_normalize).toList();

    final isHrAdmin = _containsAny(values, const [
      'hr admin',
      'human resource',
      'ict admin',
      'administrator',
      'super admin',
      'admin',
    ]);
    final isModerator = _containsAny(values, const [
      'moderator',
      'community moderator',
      'forum moderator',
      'content moderator',
    ]);
    final inferredApprover = _containsAny(values, const [
      'approver',
      'supervisor',
      'manager',
      'head of department',
      'hod',
      'lead',
      'director',
      'officer',
      'reviewer',
    ]);
    final isApprover = isApproverOverride ?? inferredApprover;

    final persona = isHrAdmin
        ? PeerExchangePersona.hrAdmin
        : isModerator
        ? PeerExchangePersona.moderator
        : isApprover
        ? PeerExchangePersona.approver
        : PeerExchangePersona.staff;

    return PeerExchangeAccess._(
      userId: user?.userId ?? '',
      roles: roles,
      permissions: permissions,
      persona: persona,
    );
  }

  final String userId;
  final List<String> roles;
  final List<String> permissions;
  final PeerExchangePersona persona;

  bool get isAuthenticated => userId.trim().isNotEmpty;

  bool get isStaff => persona == PeerExchangePersona.staff;
  bool get isApprover => persona == PeerExchangePersona.approver;
  bool get isModerator => persona == PeerExchangePersona.moderator;
  bool get isHrAdmin => persona == PeerExchangePersona.hrAdmin;
  bool get isPrivileged => !isStaff;

  bool get canStartDirectChats => isAuthenticated;
  bool get canAskQuestions => isAuthenticated;
  bool get canReplyToQuestions => isAuthenticated;
  bool get canReplyToTopics => isAuthenticated;
  bool get canViewGroupMembers => isAuthenticated;

  bool get canCreateGroups => _hasPermission('Create Program Group');

  bool get canUpdateGroups => _hasPermission('Update Program Group');

  bool get canDeleteGroups => _hasPermission('Delete Program Group');

  bool get canCreateTopics =>
      isPrivileged ||
      _hasScopedPermission(
        verbs: const ['create', 'store', 'manage', 'update'],
        nouns: const ['topic', 'topics', 'community'],
      );

  bool get canManageQuestionCategories =>
      isPrivileged ||
      _hasScopedPermission(
        verbs: const ['create', 'store', 'manage', 'update', 'delete'],
        nouns: const [
          'question category',
          'question categories',
          'category',
          'categories',
          'forum',
        ],
      );

  bool get canReviewReports =>
      isPrivileged ||
      _hasScopedPermission(
        verbs: const ['review', 'moderate', 'manage'],
        nouns: const ['report', 'reports', 'abuse', 'content', 'community'],
      );

  bool canEditGroup(int? createdBy) =>
      canUpdateGroups || _owns(createdBy);

  bool canDeleteGroup(int? createdBy) =>
      canDeleteGroups || _owns(createdBy);

  bool canManageGroup(int? createdBy) =>
      canEditGroup(createdBy) || canDeleteGroup(createdBy);

  bool canManageGroupMembers(int? createdBy) =>
      canManageGroup(createdBy) ||
      _hasScopedPermission(
        verbs: const ['manage', 'update', 'add', 'remove'],
        nouns: const ['member', 'members', 'group', 'groups'],
      );

  bool canEditQuestion(int? createdBy) =>
      canManageQuestionCategories ||
      _hasScopedPermission(
        verbs: const ['edit', 'update', 'delete', 'manage'],
        nouns: const ['question', 'questions', 'forum'],
      ) ||
      _owns(createdBy);

  bool canEditTopic(int? createdBy) =>
      canCreateTopics ||
      _hasScopedPermission(
        verbs: const ['edit', 'update', 'delete', 'manage', 'moderate'],
        nouns: const ['topic', 'topics', 'community'],
      ) ||
      _owns(createdBy);

  bool get canModerateSpaces =>
      canCreateTopics || canCreateGroups || canManageQuestionCategories;

  bool get canCreateSomethingInEverySection =>
      canStartDirectChats &&
      canCreateGroups &&
      canAskQuestions &&
      canCreateTopics;

  String get roleLabel {
    switch (persona) {
      case PeerExchangePersona.staff:
        return 'Staff';
      case PeerExchangePersona.approver:
        return 'Approver';
      case PeerExchangePersona.moderator:
        return 'Moderator';
      case PeerExchangePersona.hrAdmin:
        return 'HR Admin';
    }
  }

  String get roleSummary {
    switch (persona) {
      case PeerExchangePersona.staff:
        return 'You can ask questions, join discussions, and send direct messages.';
      case PeerExchangePersona.approver:
        return 'You can coordinate groups and topics while guiding peer discussions.';
      case PeerExchangePersona.moderator:
        return 'You can manage moderated spaces, categories, groups, and topics.';
      case PeerExchangePersona.hrAdmin:
        return 'You can oversee peer exchange setup, moderation, and structured collaboration.';
    }
  }

  List<String> get capabilityHighlights {
    final highlights = <String>[
      if (canStartDirectChats) 'Direct messages',
      if (canAskQuestions) 'Q&A replies',
      if (canCreateGroups) 'Closed groups',
      if (canCreateTopics) 'Moderated topics',
      if (canManageQuestionCategories) 'Forum categories',
      if (canReviewReports) 'Moderation review',
    ];

    return highlights;
  }

  bool isOwner(int? createdBy) => _owns(createdBy);

  bool _owns(int? createdBy) {
    final currentId = int.tryParse(userId);
    return currentId != null && createdBy != null && createdBy == currentId;
  }

  bool _hasPermission(String permissionName) {
    final normalizedTarget = _normalize(permissionName);
    return permissions.any(
      (permission) => _normalize(permission) == normalizedTarget,
    );
  }

  bool _hasScopedPermission({
    required List<String> verbs,
    required List<String> nouns,
  }) {
    final normalizedPermissions = permissions.map(_normalize).toList();
    for (final permission in normalizedPermissions) {
      final hasVerb = verbs.any(
        (verb) => permission.contains(_normalize(verb)),
      );
      final hasNoun = nouns.any(
        (noun) => permission.contains(_normalize(noun)),
      );
      if (hasVerb && hasNoun) {
        return true;
      }
    }
    return false;
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
      final shouldKeep = isLetter || isNumber;
      if (shouldKeep) {
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

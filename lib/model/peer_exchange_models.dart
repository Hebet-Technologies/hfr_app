class PeerAuthor {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNo;

  const PeerAuthor({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNo,
  });

  factory PeerAuthor.fromJson(Map<String, dynamic> json) {
    return PeerAuthor(
      id: _asInt(json['id']),
      firstName: _asString(json['first_name']),
      middleName: _asString(json['middle_name']),
      lastName: _asString(json['last_name']),
      fullName: _asString(json['full_name']),
      email: _asString(json['email']),
      phoneNo: _asString(json['phone_no']),
    );
  }
}

class PeerDirectoryPerson {
  final int id;
  final String fullName;
  final String email;
  final String phoneNo;
  final String title;
  final String workingStationName;

  const PeerDirectoryPerson({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNo,
    required this.title,
    required this.workingStationName,
  });

  factory PeerDirectoryPerson.fromJson(Map<String, dynamic> json) {
    final firstName = _asString(
      json['first_name'] ?? json['firstname'] ?? json['given_name'],
    );
    final middleName = _asString(
      json['middle_name'] ?? json['middlename'] ?? json['other_name'],
    );
    final lastName = _asString(
      json['last_name'] ?? json['lastname'] ?? json['surname'],
    );
    final fullName = _asString(
      json['full_name'] ??
          json['name'] ??
          json['employee_name'] ??
          [
            firstName,
            middleName,
            lastName,
          ].where((part) => part.trim().isNotEmpty).join(' '),
    );

    return PeerDirectoryPerson(
      id:
          _nullableInt(
            json['user_id'] ??
                json['employee_id'] ??
                json['id'] ??
                json['staff_id'],
          ) ??
          0,
      fullName: fullName.isEmpty ? 'Unknown staff' : fullName,
      email: _asString(json['email']),
      phoneNo: _asString(json['phone_no'] ?? json['phone']),
      title: _asString(
        json['designation'] ??
            json['job_title'] ??
            json['cadre_name'] ??
            json['role'] ??
            json['position'],
      ),
      workingStationName: _asString(
        json['working_station_name'] ??
            json['facility_name'] ??
            json['department_name'],
      ),
    );
  }

  String get subtitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (workingStationName.trim().isNotEmpty) return workingStationName.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'Staff member';
  }
}

class PeerAttachment {
  final String uuid;
  final String category;
  final String subCategory;
  final String originalFileName;
  final String filePath;
  final String mimeType;
  final String fileSize;

  const PeerAttachment({
    required this.uuid,
    required this.category,
    required this.subCategory,
    required this.originalFileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
  });

  factory PeerAttachment.fromJson(Map<String, dynamic> json) {
    return PeerAttachment(
      uuid: _asString(json['uuid']),
      category: _asString(json['category']),
      subCategory: _asString(json['sub_category']),
      originalFileName: _asString(json['original_file_name']),
      filePath: _asString(json['file_path']),
      mimeType: _asString(json['mime_type']),
      fileSize: _asString(json['file_size']),
    );
  }
}

class PeerMember {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNo;
  final String membershipUuid;
  final String role;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isActive;

  const PeerMember({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNo,
    required this.membershipUuid,
    required this.role,
    required this.joinedAt,
    required this.leftAt,
    required this.isMuted,
    required this.isActive,
  });

  factory PeerMember.fromJson(Map<String, dynamic> json) {
    return PeerMember(
      id: _asString(json['id']),
      firstName: _asString(json['first_name']),
      middleName: _asString(json['middle_name']),
      lastName: _asString(json['last_name']),
      fullName: _asString(json['full_name']),
      email: _asString(json['email']),
      phoneNo: _asString(json['phone_no']),
      membershipUuid: _asString(json['membership_uuid']),
      role: _asString(json['role']),
      joinedAt: _asDateTime(json['joined_at']),
      leftAt: _asDateTime(json['left_at']),
      isMuted: _asBool(json['is_muted']),
      isActive: _asBool(json['is_active'], fallback: true),
    );
  }

  int? get numericId => int.tryParse(id);
}

class PeerMessage {
  final String uuid;
  final int conversationId;
  final int senderId;
  final String messageType;
  final String status;
  final String message;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String replyToUuid;
  final bool isEdited;
  final DateTime? editedAt;
  final PeerMember? sender;
  final List<PeerAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PeerMessage({
    required this.uuid,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.status,
    required this.message,
    required this.sentAt,
    required this.deliveredAt,
    required this.readAt,
    required this.replyToUuid,
    required this.isEdited,
    required this.editedAt,
    required this.sender,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PeerMessage.fromJson(Map<String, dynamic> json) {
    return PeerMessage(
      uuid: _asString(json['uuid']),
      conversationId: _asInt(json['conversation_id']),
      senderId: _asInt(json['sender_id']),
      messageType: _asString(json['message_type']),
      status: _asString(json['status']),
      message: _asString(json['message']),
      sentAt: _asDateTime(json['sent_at']),
      deliveredAt: _asDateTime(json['delivered_at']),
      readAt: _asDateTime(json['read_at']),
      replyToUuid: _asString(json['reply_to_uuid']),
      isEdited: _asBool(json['is_edited']),
      editedAt: _asDateTime(json['edited_at']),
      sender: _asMap(json['sender']) == null
          ? null
          : PeerMember.fromJson(_asMap(json['sender'])!),
      attachments: _asList(
        json['attachments'],
      ).map((item) => PeerAttachment.fromJson(item)).toList(),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  bool get hasMessage => message.trim().isNotEmpty;

  String get preview {
    if (hasMessage) {
      return message.trim();
    }

    if (attachments.isNotEmpty) {
      final suffix = attachments.length == 1 ? 'attachment' : 'attachments';
      return '${attachments.length} $suffix';
    }

    return 'No message yet';
  }
}

class PeerConversation {
  final String uuid;
  final String name;
  final String displayName;
  final String iconPath;
  final String type;
  final String description;
  final int? lastMessageId;
  final DateTime? lastMessageAt;
  final bool isActive;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messagesCount;
  final int usersCount;
  final List<PeerMember> users;
  final PeerMessage? lastMessage;
  final List<PeerMessage> recentMessages;

  const PeerConversation({
    required this.uuid,
    required this.name,
    required this.displayName,
    required this.iconPath,
    required this.type,
    required this.description,
    required this.lastMessageId,
    required this.lastMessageAt,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.messagesCount,
    required this.usersCount,
    required this.users,
    required this.lastMessage,
    required this.recentMessages,
  });

  factory PeerConversation.fromJson(Map<String, dynamic> json) {
    return PeerConversation(
      uuid: _asString(json['uuid']),
      name: _asString(json['name']),
      displayName: _asString(json['display_name']),
      iconPath: _asString(json['icon_path']),
      type: _asString(json['type']),
      description: _asString(json['description']),
      lastMessageId: _nullableInt(json['last_message_id']),
      lastMessageAt: _asDateTime(json['last_message_at']),
      isActive: _asBool(json['is_active'], fallback: true),
      createdBy: _nullableInt(json['created_by']),
      updatedBy: _nullableInt(json['updated_by']),
      deletedAt: _asDateTime(json['deleted_at']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      messagesCount: _asInt(json['messages_count']),
      usersCount: _asInt(json['users_count']),
      users: _asList(
        json['users'],
      ).map((item) => PeerMember.fromJson(item)).toList(),
      lastMessage: _asMap(json['last_message']) == null
          ? null
          : PeerMessage.fromJson(_asMap(json['last_message'])!),
      recentMessages: _asList(
        json['recent_messages'],
      ).map((item) => PeerMessage.fromJson(item)).toList(),
    );
  }

  bool get isGroup => type.toLowerCase() == 'group';

  String get title {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (name.trim().isNotEmpty) return name.trim();
    if (users.isNotEmpty) return users.first.fullName;
    return isGroup ? 'Group conversation' : 'Conversation';
  }

  String get subtitle {
    if (lastMessage != null) return lastMessage!.preview;
    if (description.trim().isNotEmpty) return description.trim();
    return isGroup ? 'No group activity yet' : 'No conversation activity yet';
  }
}

class PeerQuestionCategory {
  final String uuid;
  final String name;
  final bool isActive;

  const PeerQuestionCategory({
    required this.uuid,
    required this.name,
    required this.isActive,
  });

  factory PeerQuestionCategory.fromJson(Map<String, dynamic> json) {
    return PeerQuestionCategory(
      uuid: _asString(json['uuid']),
      name: _asString(json['name']),
      isActive: _asBool(json['is_active'], fallback: true),
    );
  }
}

class PeerComment {
  final String uuid;
  final int? commentableId;
  final String commentableType;
  final int? parentCommentId;
  final String category;
  final String subCategory;
  final String comment;
  final int commentedBy;
  final PeerAuthor? author;
  final List<PeerAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PeerComment({
    required this.uuid,
    required this.commentableId,
    required this.commentableType,
    required this.parentCommentId,
    required this.category,
    required this.subCategory,
    required this.comment,
    required this.commentedBy,
    required this.author,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PeerComment.fromJson(Map<String, dynamic> json) {
    return PeerComment(
      uuid: _asString(json['uuid']),
      commentableId: _nullableInt(json['commentable_id']),
      commentableType: _asString(json['commentable_type']),
      parentCommentId: _nullableInt(json['parent_comment_id']),
      category: _asString(json['category']),
      subCategory: _asString(json['sub_category']),
      comment: _asString(json['comment']),
      commentedBy: _asInt(json['commented_by']),
      author: _asMap(json['author']) == null
          ? null
          : PeerAuthor.fromJson(_asMap(json['author'])!),
      attachments: _asList(
        json['attachments'],
      ).map((item) => PeerAttachment.fromJson(item)).toList(),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }
}

class PeerQuestion {
  final String uuid;
  final int categoryId;
  final String categoryUuid;
  final String content;
  final int? lastCommentId;
  final DateTime? lastCommentAt;
  final bool isActive;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int commentsCount;
  final PeerQuestionCategory? category;
  final List<PeerAttachment> attachments;
  final PeerComment? lastComment;
  final PeerAuthor? author;

  const PeerQuestion({
    required this.uuid,
    required this.categoryId,
    required this.categoryUuid,
    required this.content,
    required this.lastCommentId,
    required this.lastCommentAt,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.commentsCount,
    required this.category,
    required this.attachments,
    required this.lastComment,
    required this.author,
  });

  factory PeerQuestion.fromJson(Map<String, dynamic> json) {
    return PeerQuestion(
      uuid: _asString(json['uuid']),
      categoryId: _asInt(json['category_id']),
      categoryUuid: _asString(json['category_uuid']),
      content: _asString(json['content']),
      lastCommentId: _nullableInt(json['last_comment_id']),
      lastCommentAt: _asDateTime(json['last_comment_at']),
      isActive: _asBool(json['is_active'], fallback: true),
      createdBy: _nullableInt(json['created_by']),
      updatedBy: _nullableInt(json['updated_by']),
      deletedAt: _asDateTime(json['deleted_at']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      commentsCount: _asInt(json['comments_count']),
      category: _asMap(json['category']) == null
          ? null
          : PeerQuestionCategory.fromJson(_asMap(json['category'])!),
      attachments: _asList(
        json['attachments'],
      ).map((item) => PeerAttachment.fromJson(item)).toList(),
      lastComment: _asMap(json['last_comment']) == null
          ? null
          : PeerComment.fromJson(_asMap(json['last_comment'])!),
      author: _questionAuthorFromJson(json),
    );
  }
}

PeerAuthor? _questionAuthorFromJson(Map<String, dynamic> json) {
  for (final key in const [
    'author',
    'asked_by',
    'askedBy',
    'created_by_user',
    'createdByUser',
    'creator',
    'user',
    'staff',
  ]) {
    final author = _normalizedAuthorMap(_asMap(json[key]));
    if (_hasAuthorValues(author)) {
      return PeerAuthor.fromJson(author);
    }
  }

  final flattened = _normalizedAuthorMap({
    'id': json['author_id'] ?? json['asked_by_id'] ?? json['created_by'],
    'first_name':
        json['author_first_name'] ??
        json['asked_by_first_name'] ??
        json['created_by_first_name'],
    'middle_name':
        json['author_middle_name'] ??
        json['asked_by_middle_name'] ??
        json['created_by_middle_name'],
    'last_name':
        json['author_last_name'] ??
        json['asked_by_last_name'] ??
        json['created_by_last_name'],
    'full_name':
        json['author_full_name'] ??
        json['asked_by_name'] ??
        json['asked_by_full_name'] ??
        json['created_by_name'] ??
        json['created_by_full_name'],
    'email':
        json['author_email'] ??
        json['asked_by_email'] ??
        json['created_by_email'],
    'phone_no':
        json['author_phone_no'] ??
        json['asked_by_phone_no'] ??
        json['created_by_phone_no'],
  });

  if (_hasAuthorValues(flattened)) {
    return PeerAuthor.fromJson(flattened);
  }

  return null;
}

Map<String, dynamic> _normalizedAuthorMap(Map<String, dynamic>? raw) {
  if (raw == null) return const {};

  return {
    'id': raw['id'] ?? raw['user_id'] ?? raw['author_id'],
    'first_name':
        raw['first_name'] ?? raw['firstname'] ?? raw['given_name'] ?? '',
    'middle_name':
        raw['middle_name'] ?? raw['middlename'] ?? raw['other_name'] ?? '',
    'last_name': raw['last_name'] ?? raw['lastname'] ?? raw['surname'] ?? '',
    'full_name': raw['full_name'] ?? raw['name'] ?? raw['display_name'] ?? '',
    'email': raw['email'] ?? '',
    'phone_no': raw['phone_no'] ?? raw['phone'] ?? '',
  };
}

bool _hasAuthorValues(Map<String, dynamic>? value) {
  if (value == null || value.isEmpty) return false;

  for (final key in const [
    'full_name',
    'first_name',
    'last_name',
    'email',
    'phone_no',
  ]) {
    if (_asString(value[key]).trim().isNotEmpty) {
      return true;
    }
  }

  return false;
}

class PeerTopicAudience {
  final int id;
  final String audienceType;
  final int audienceValueId;

  const PeerTopicAudience({
    required this.id,
    required this.audienceType,
    required this.audienceValueId,
  });

  factory PeerTopicAudience.fromJson(Map<String, dynamic> json) {
    return PeerTopicAudience(
      id: _asInt(json['id']),
      audienceType: _asString(json['audience_type']),
      audienceValueId: _asInt(json['audience_value_id']),
    );
  }
}

class PeerTopic {
  final String uuid;
  final String name;
  final String description;
  final int? lastCommentId;
  final DateTime? lastCommentAt;
  final bool isActive;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int commentsCount;
  final List<PeerTopicAudience> audiences;
  final PeerComment? lastComment;

  const PeerTopic({
    required this.uuid,
    required this.name,
    required this.description,
    required this.lastCommentId,
    required this.lastCommentAt,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.commentsCount,
    required this.audiences,
    required this.lastComment,
  });

  factory PeerTopic.fromJson(Map<String, dynamic> json) {
    return PeerTopic(
      uuid: _asString(json['uuid']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      lastCommentId: _nullableInt(json['last_comment_id']),
      lastCommentAt: _asDateTime(json['last_comment_at']),
      isActive: _asBool(json['is_active'], fallback: true),
      createdBy: _nullableInt(json['created_by']),
      updatedBy: _nullableInt(json['updated_by']),
      deletedAt: _asDateTime(json['deleted_at']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      commentsCount: _asInt(json['comments_count']),
      audiences: _asList(
        json['audiences'],
      ).map((item) => PeerTopicAudience.fromJson(item)).toList(),
      lastComment: _asMap(json['last_comment']) == null
          ? null
          : PeerComment.fromJson(_asMap(json['last_comment'])!),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => _asMap(item))
      .whereType<Map<String, dynamic>>()
      .toList();
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase().trim();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

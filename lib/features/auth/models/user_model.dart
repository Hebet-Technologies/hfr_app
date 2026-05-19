class UserModel {
  final String userId;
  final String email;
  final String fullName;
  final String loginStatus;
  final String workingStationId;
  final String workingStationName;
  final String? workingStationType;
  final String personalInformationId;
  final String employmentInformationId;
  final String payroll;
  final String token;
  final List<String> roles;
  final List<String> roleIds;
  final List<String> permissions;
  final List<String> permissionIds;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.loginStatus,
    required this.workingStationId,
    required this.workingStationName,
    this.workingStationType,
    required this.personalInformationId,
    required this.employmentInformationId,
    required this.payroll,
    required this.token,
    this.roles = const <String>[],
    this.roleIds = const <String>[],
    this.permissions = const <String>[],
    this.permissionIds = const <String>[],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: _pickString(json, const ['user_id', 'id']),
      email: _asString(json['email']),
      fullName: _pickString(json, const ['full_name', 'name']),
      loginStatus: _asString(json['login_status']),
      workingStationId: _asString(json['working_station_id']),
      workingStationName: _asString(json['working_station_name']),
      workingStationType: _asNullableString(json['working_station_type']),
      personalInformationId: _pickString(json, const [
        'personal_information_id',
        'personal_id',
        'employee_id',
        'staff_id',
      ]),
      employmentInformationId: _pickString(json, const [
        'employment_information_id',
        'employment_id',
      ]),
      payroll: _asString(json['payroll']),
      token: _asString(json['token']),
      roles: _asStringList(json['roles']),
      roleIds: _asIdList(json['roles']),
      permissions: _asStringList(json['permissions']),
      permissionIds: _asIdList(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'login_status': loginStatus,
      'working_station_id': workingStationId,
      'working_station_name': workingStationName,
      'working_station_type': workingStationType,
      'personal_information_id': personalInformationId,
      'employment_information_id': employmentInformationId,
      'payroll': payroll,
      'token': token,
      'roles': roles,
      'role_ids': roleIds,
      'permissions': permissions,
      'permission_ids': permissionIds,
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? loginStatus,
    String? workingStationId,
    String? workingStationName,
    String? workingStationType,
    String? personalInformationId,
    String? employmentInformationId,
    String? payroll,
    String? token,
    List<String>? roles,
    List<String>? roleIds,
    List<String>? permissions,
    List<String>? permissionIds,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      loginStatus: loginStatus ?? this.loginStatus,
      workingStationId: workingStationId ?? this.workingStationId,
      workingStationName: workingStationName ?? this.workingStationName,
      workingStationType: workingStationType ?? this.workingStationType,
      personalInformationId:
          personalInformationId ?? this.personalInformationId,
      employmentInformationId:
          employmentInformationId ?? this.employmentInformationId,
      payroll: payroll ?? this.payroll,
      token: token ?? this.token,
      roles: roles ?? this.roles,
      roleIds: roleIds ?? this.roleIds,
      permissions: permissions ?? this.permissions,
      permissionIds: permissionIds ?? this.permissionIds,
    );
  }

  String? get primaryRoleId => roleIds.isEmpty ? null : roleIds.first;

  bool hasRoleId(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) return false;
    return roleIds.any((item) => item == normalized);
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _asString(json[key]).trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return <String>[];

    return value
        .map((item) {
          if (item == null) return '';
          if (item is Map<String, dynamic>) {
            return _asString(
              item['name'] ??
                  item['role'] ??
                  item['permission'] ??
                  item['title'],
            );
          }
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<String> _asIdList(dynamic value) {
    if (value is! List) return <String>[];

    return value
        .map((item) {
          if (item == null) return '';
          if (item is Map<String, dynamic>) {
            return _asString(item['id']);
          }
          if (item is Map) {
            return _asString(item['id']);
          }
          return '';
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

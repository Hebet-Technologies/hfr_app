class UserModel {
  final String userId;
  final String email;
  final String fullName;
  final String loginStatus;
  final String workingStationId;
  final String workingStationName;
  final String? workingStationType;
  final String personalInformationId;
  final String token;
  final List<String> roles;
  final List<String> permissions;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.loginStatus,
    required this.workingStationId,
    required this.workingStationName,
    this.workingStationType,
    required this.personalInformationId,
    required this.token,
    required this.roles,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: _asString(json['user_id']),
      email: _asString(json['email']),
      fullName: _asString(json['full_name']),
      loginStatus: _asString(json['login_status']),
      workingStationId: _asString(json['working_station_id']),
      workingStationName: _asString(json['working_station_name']),
      workingStationType: _asNullableString(json['working_station_type']),
      personalInformationId: _asString(json['personal_information_id']),
      token: _asString(json['token']),
      roles: _asStringList(json['roles']),
      permissions: _asStringList(json['permissions']),
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
      'token': token,
      'roles': roles,
      'permissions': permissions,
    };
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
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
              item['name'] ?? item['role'] ?? item['permission'] ?? item['title'],
            );
          }
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

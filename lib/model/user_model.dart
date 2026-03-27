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
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      loginStatus: json['login_status'] ?? '',
      workingStationId: json['working_station_id'] ?? '',
      workingStationName: json['working_station_name'] ?? '',
      workingStationType: json['working_station_type'],
      personalInformationId: json['personal_information_id'] ?? '',
      token: json['token'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
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
}

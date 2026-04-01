import 'dart:convert';

import 'user_model.dart';

class ProfileDetails {
  const ProfileDetails({
    required this.employeeId,
    required this.personalInformationId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phoneNo,
    required this.gender,
    required this.dateOfBirth,
    required this.cadre,
    required this.department,
    required this.facility,
  });

  factory ProfileDetails.fromUser(UserModel user) {
    final parts = _splitName(user.fullName);
    return ProfileDetails(
      employeeId: user.userId,
      personalInformationId: user.personalInformationId,
      firstName: parts.$1,
      middleName: parts.$2,
      lastName: parts.$3,
      email: user.email,
      phoneNo: '',
      gender: '',
      dateOfBirth: '',
      cadre: user.workingStationType ?? '',
      department: '',
      facility: user.workingStationName,
    );
  }

  factory ProfileDetails.fromApi(
    Map<String, dynamic> source, {
    required UserModel fallbackUser,
  }) {
    final fallback = ProfileDetails.fromUser(fallbackUser);
    final normalized = _normalizeMap(source);
    final firstName = _pickString(normalized, const [
      'first_name',
      'firstname',
      'given_name',
    ]);
    final middleName = _pickString(normalized, const [
      'middle_name',
      'middlename',
      'other_name',
    ]);
    final lastName = _pickString(normalized, const [
      'last_name',
      'lastname',
      'surname',
    ]);

    final nameParts = _splitName(
      _pickString(normalized, const ['full_name', 'name', 'employee_name']),
    );

    return ProfileDetails(
      employeeId: _pickString(normalized, const [
        'employee_id',
        'user_id',
        'id',
      ], fallback: fallback.employeeId),
      personalInformationId: _pickString(normalized, const [
        'personal_information_id',
        'personal_id',
      ], fallback: fallback.personalInformationId),
      firstName: firstName.isNotEmpty ? firstName : nameParts.$1,
      middleName: middleName.isNotEmpty ? middleName : nameParts.$2,
      lastName: lastName.isNotEmpty ? lastName : nameParts.$3,
      email: _pickString(normalized, const ['email'], fallback: fallback.email),
      phoneNo: _pickString(normalized, const [
        'phone_no',
        'phone',
        'mobile_number',
      ], fallback: fallback.phoneNo),
      gender: _pickString(normalized, const [
        'gender',
      ], fallback: fallback.gender),
      dateOfBirth: _pickString(normalized, const [
        'date_of_birth',
        'dob',
      ], fallback: fallback.dateOfBirth),
      cadre: _pickString(normalized, const [
        'cadre',
        'cadre_name',
        'designation',
        'job_title',
      ], fallback: fallback.cadre),
      department: _pickString(normalized, const [
        'department',
        'department_name',
        'section_name',
      ], fallback: fallback.department),
      facility: _pickString(normalized, const [
        'facility',
        'facility_name',
        'working_station_name',
      ], fallback: fallback.facility),
    );
  }

  final String employeeId;
  final String personalInformationId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phoneNo;
  final String gender;
  final String dateOfBirth;
  final String cadre;
  final String department;
  final String facility;

  String get fullName {
    return [
      firstName,
      middleName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  String get roleLabel => cadre.trim().isEmpty ? 'Staff' : cadre.trim();

  Map<String, dynamic> toUpdatePayload() {
    final payload = <String, dynamic>{};

    void addValue(String key, String value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        payload[key] = normalized;
      }
    }

    addValue('employee_id', employeeId);
    addValue('personal_information_id', personalInformationId);
    addValue('first_name', firstName);
    addValue('middle_name', middleName);
    addValue('last_name', lastName);
    addValue('gender', gender);
    addValue('phone_no', phoneNo);
    addValue('date_of_birth', dateOfBirth);
    addValue('email', email);

    return payload;
  }

  UserModel applyToUser(UserModel user) {
    return user.copyWith(
      fullName: fullName.isEmpty ? user.fullName : fullName,
      email: email.isEmpty ? user.email : email,
    );
  }

  ProfileDetails copyWith({
    String? employeeId,
    String? personalInformationId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phoneNo,
    String? gender,
    String? dateOfBirth,
    String? cadre,
    String? department,
    String? facility,
  }) {
    return ProfileDetails(
      employeeId: employeeId ?? this.employeeId,
      personalInformationId:
          personalInformationId ?? this.personalInformationId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNo: phoneNo ?? this.phoneNo,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cadre: cadre ?? this.cadre,
      department: department ?? this.department,
      facility: facility ?? this.facility,
    );
  }

  static Map<String, dynamic> decodePayload(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          return decodePayload(decoded);
        } catch (_) {
          return <String, dynamic>{};
        }
      }
    }
    if (value is List && value.isNotEmpty) {
      return decodePayload(value.first);
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> input) {
    final normalized = <String, dynamic>{};
    input.forEach((key, value) {
      normalized[key.toString()] = value;
    });
    return normalized;
  }

  static String _pickString(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  static (String, String, String) _splitName(String value) {
    final parts = value
        .split(' ')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) return ('', '', '');
    if (parts.length == 1) return (parts[0], '', '');
    if (parts.length == 2) return (parts[0], '', parts[1]);

    return (
      parts.first,
      parts.sublist(1, parts.length - 1).join(' '),
      parts.last,
    );
  }
}

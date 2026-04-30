import 'dart:developer';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/profile_details.dart';
import '../model/staff_portal_access.dart';
import '../model/user_model.dart';
import '../model/registration_model.dart';
import '../utils/api_call.dart';

class AuthRepository {
  static const _activePortalModeKey = 'active_portal_mode';
  static const _authStorageKeys = <String>[
    'token',
    'user_id',
    'email',
    'full_name',
    'login_status',
    'working_station_id',
    'working_station_name',
    'working_station_type',
    'personal_information_id',
    'employment_information_id',
    'payroll',
    'roles',
    'role_ids',
    'permissions',
    'permission_ids',
    'is_logged_in',
    _activePortalModeKey,
  ];

  final ApiService _apiService;
  final Dio _authorizedDio = Dio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  AuthRepository(this._apiService);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      log(response.data.toString());
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = UserModel.fromJson(response.data['data']);
        await _saveUserData(userData);
        return userData;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  Future<Map<String, dynamic>> getPersonalInfo(
    String payroll,
    String dateOfBirth,
  ) async {
    try {
      final response = await _apiService.getPersonalInfo(payroll, dateOfBirth);
      final payload = _asMap(response.data);
      final statusCode = payload['statusCode'];

      if (response.statusCode == 200 && statusCode == 200) {
        return payload;
      }

      throw Exception(
        payload['message']?.toString() ??
            'Failed to fetch personal information',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch personal information',
        );
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  Future<Map<String, dynamic>> register(
    RegistrationModel registrationModel,
  ) async {
    try {
      final response = await _apiService.createAccount(
        registrationModel.toJson(),
      );
      final payload = _asMap(response.data);
      final statusCode = payload['statusCode'];

      if (response.statusCode == 200 &&
          (statusCode == 200 || statusCode == 201)) {
        return payload;
      }

      final messages = payload['messages'];
      if (messages is Map && messages.isNotEmpty) {
        final firstError = messages.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
        throw Exception(firstError.toString());
      }

      throw Exception(payload['message']?.toString() ?? 'Registration failed');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await _clearAuthStorage(prefs);
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.userId);
    await prefs.setString('email', user.email);
    await prefs.setString('full_name', user.fullName);
    await prefs.setString('login_status', user.loginStatus);
    await prefs.setString('working_station_id', user.workingStationId);
    await prefs.setString('working_station_name', user.workingStationName);
    if ((user.workingStationType ?? '').trim().isNotEmpty) {
      await prefs.setString('working_station_type', user.workingStationType!);
    } else {
      await prefs.remove('working_station_type');
    }
    await prefs.setString(
      'personal_information_id',
      user.personalInformationId,
    );
    await prefs.setString(
      'employment_information_id',
      user.employmentInformationId,
    );
    await prefs.setString('payroll', user.payroll);
    await prefs.setStringList('roles', user.roles);
    await prefs.setStringList('role_ids', user.roleIds);
    await prefs.setStringList('permissions', user.permissions);
    await prefs.setStringList('permission_ids', user.permissionIds);
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> persistUser(UserModel user) async {
    await _saveUserData(user);
  }

  Future<void> persistActivePortalMode(StaffPortalMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePortalModeKey, mode.storageValue);
  }

  Future<StaffPortalMode> getSavedActivePortalMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activePortalModeKey)?.trim();
    if (value == StaffPortalMode.approver.storageValue) {
      return StaffPortalMode.approver;
    }
    return StaffPortalMode.employee;
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn || token == null || token.trim().isEmpty) {
      return null;
    }

    return UserModel(
      userId: prefs.getString('user_id') ?? '',
      email: prefs.getString('email') ?? '',
      fullName: prefs.getString('full_name') ?? '',
      loginStatus: prefs.getString('login_status') ?? '',
      workingStationId: prefs.getString('working_station_id') ?? '',
      workingStationName: prefs.getString('working_station_name') ?? '',
      workingStationType: prefs.getString('working_station_type'),
      personalInformationId: prefs.getString('personal_information_id') ?? '',
      employmentInformationId:
          prefs.getString('employment_information_id') ?? '',
      payroll: prefs.getString('payroll') ?? '',
      token: token,
      roles: prefs.getStringList('roles') ?? const <String>[],
      roleIds: prefs.getStringList('role_ids') ?? const <String>[],
      permissions: prefs.getStringList('permissions') ?? const <String>[],
      permissionIds: prefs.getStringList('permission_ids') ?? const <String>[],
    );
  }

  Future<UserModel?> resolveEmployeeUser(UserModel? user) async {
    if (user == null || user.personalInformationId.trim().isNotEmpty) {
      return user;
    }

    try {
      final profile = await fetchProfileDetails(user);
      final personalInformationId = profile.personalInformationId.trim();
      if (personalInformationId.isEmpty) {
        return user;
      }

      final updated = profile.applyToUser(
        user.copyWith(personalInformationId: personalInformationId),
      );
      await persistUser(updated);
      return updated;
    } catch (_) {
      return user;
    }
  }

  Future<ProfileDetails> fetchProfileDetails(UserModel user) async {
    final candidates = [user.userId, user.personalInformationId]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    for (final id in candidates) {
      try {
        final response = await _authorizedDio.get(
          '/getEmployeeDetail/$id',
          options: await _authorizedOptions(),
        );
        final payload = _extractProfilePayload(response.data);
        if (payload.isNotEmpty) {
          return ProfileDetails.fromApi(payload, fallbackUser: user);
        }
      } on DioException {
        continue;
      } catch (_) {
        continue;
      }
    }

    return ProfileDetails.fromUser(user);
  }

  Future<void> updatePersonalProfile(ProfileDetails details) async {
    try {
      await _authorizedDio.post(
        '/updatePersonalInfo',
        data: FormData.fromMap(details.toUpdatePayload()),
        options: await _authorizedOptions(
          extraHeaders: const {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 200 ||
          error.response?.statusCode == 201) {
        return;
      }
      throw Exception(_resolveMessage(error));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearAuthStorage(prefs);
  }

  Future<void> _clearAuthStorage(SharedPreferences prefs) async {
    for (final key in _authStorageKeys) {
      await prefs.remove(key);
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Options> _authorizedOptions({
    Map<String, String>? extraHeaders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    return Options(
      headers: {'Authorization': 'Bearer $token', ...?extraHeaders},
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _extractProfilePayload(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final direct = ProfileDetails.decodePayload(responseData['data']);
      if (direct.isNotEmpty) return direct;

      final merged = <String, dynamic>{};
      for (final key in ['data', 'employee', 'user', 'profile']) {
        merged.addAll(ProfileDetails.decodePayload(responseData[key]));
      }
      return merged;
    }

    if (responseData is Map) {
      return _extractProfilePayload(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    if (responseData is String) {
      final trimmed = responseData.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          return _extractProfilePayload(decoded);
        } catch (_) {
          return <String, dynamic>{};
        }
      }
    }

    return <String, dynamic>{};
  }

  String _resolveMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return error.message ?? 'Something went wrong while contacting the server.';
  }

  final NetworkApiService _networkApiService = NetworkApiService();

  Future<dynamic> loginApi(dynamic data) async {
    try {
      dynamic response = await _networkApiService.getPostApiResponse(
        ApiCall.loginApi,
        data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> defaultDashboard() async {
    try {
      dynamic response = await _networkApiService.getGetApiResponseWithToken(
        ApiCall.defaultDashboard,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> selectedDashboard(int id) async {
    try {
      dynamic response = await _networkApiService
          .getGetApiResponseWithTokenById(ApiCall.selectedDashboard, id);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getWorkStation() async {
    try {
      dynamic response = await _networkApiService.getGetApiResponseWithToken(
        ApiCall.getWorkStation,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

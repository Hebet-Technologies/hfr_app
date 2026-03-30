import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/user_model.dart';
import '../model/registration_model.dart';
import '../utils/api_call.dart';

class AuthRepository {
  final ApiService _apiService;

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

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch personal information');
      }
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

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Registration failed');
      }
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
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.userId);
    await prefs.setString('email', user.email);
    await prefs.setString('full_name', user.fullName);
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://hris-api.hezo.co.tz/api';
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  Future<Response> login(String email, String password) async {
    try {
      return await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getPersonalInfo(String payroll, String dateOfBirth) async {
    try {
      return await _dio.post(
        '/getPersonalInfo',
        data: {
          'payroll': payroll,
          'date_of_birth': dateOfBirth,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> createAccount(Map<String, dynamic> registrationData) async {
    try {
      return await _dio.post(
        '/createAccount',
        data: registrationData,
      );
    } catch (e) {
      rethrow;
    }
  }
}

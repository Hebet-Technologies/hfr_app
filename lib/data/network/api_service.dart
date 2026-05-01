import 'dart:developer';

import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://hris-api.hezo.co.tz/api';
  final Dio _dio;

  ApiService()
    : _dio = createLoggedDio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  Future<Response> login(Map<String, dynamic> payload) async {
    try {
      return await _dio.post('/login', data: payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getPersonalInfo(String payroll, String dateOfBirth) async {
    try {
      return await _dio.post(
        '/getPersonalInfo',
        data: {'payroll': payroll, 'date_of_birth': dateOfBirth},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> createAccount(Map<String, dynamic> registrationData) async {
    try {
      return await _dio.post('/createAccount', data: registrationData);
    } catch (e) {
      rethrow;
    }
  }
}

Dio createLoggedDio(BaseOptions options) {
  final dio = Dio(options);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final payload = <String, dynamic>{
          'method': options.method,
          'url': options.uri.toString(),
        };
        if (options.queryParameters.isNotEmpty) {
          payload['query'] = options.queryParameters;
        }
        if (options.data != null) {
          payload['body'] = _normalizeLogValue(options.data);
        }
        log('API REQUEST: $payload', name: 'API');
        handler.next(options);
      },
      onResponse: (response, handler) {
        log(
          'API RESPONSE: ${response.requestOptions.method} ${response.requestOptions.uri} '
          '[${response.statusCode}] body=${_normalizeLogValue(response.data)}',
          name: 'API',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        log(
          'API ERROR: ${error.requestOptions.method} ${error.requestOptions.uri} '
          '[${error.response?.statusCode ?? 'no-status'}] '
          'response=${_normalizeLogValue(error.response?.data)}',
          name: 'API',
        );
        handler.next(error);
      },
    ),
  );
  return dio;
}

dynamic _normalizeLogValue(dynamic value) {
  if (value is FormData) {
    return {
      'fields': {for (final field in value.fields) field.key: field.value},
      'files': [for (final file in value.files) file.key],
    };
  }
  return value;
}

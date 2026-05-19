import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:staffportal/core/services/app_session_store.dart';
import 'package:staffportal/core/services/session_expiry_service.dart';

class ApiService {
  static const String baseUrl = 'https://hris-api.hezo.co.tz/api';
  static const Duration defaultConnectTimeout = Duration(seconds: 30);
  static const Duration defaultReceiveTimeout = Duration(seconds: 90);
  final Dio _dio;

  ApiService()
    : _dio = createLoggedDio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: defaultConnectTimeout,
          receiveTimeout: defaultReceiveTimeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  Future<Response> login(Map<String, dynamic> payload) async {
    try {
      return await _dio.post('/login', data: payload, options: skipAuth());
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getPersonalInfo(String payroll, String dateOfBirth) async {
    try {
      return await _dio.post(
        '/getPersonalInfo',
        data: {'payroll': payroll, 'date_of_birth': dateOfBirth},
        options: skipAuth(),
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
        options: skipAuth(),
      );
    } catch (e) {
      rethrow;
    }
  }
}

const String skipAuthExtraKey = 'skip_auth';
const String requireAuthExtraKey = 'require_auth';

Options skipAuth({Map<String, String>? headers}) {
  return Options(headers: headers, extra: const {skipAuthExtraKey: true});
}

Options requireAuth({Map<String, String>? headers, String? contentType}) {
  return Options(
    headers: headers,
    contentType: contentType,
    extra: const {requireAuthExtraKey: true},
  );
}

Dio createLoggedDio(BaseOptions options) {
  final dio = Dio(options);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final skipAuth = options.extra[skipAuthExtraKey] == true;
        final requireAuth = options.extra[requireAuthExtraKey] == true;

        if (!skipAuth) {
          final token = await AppSessionStore.getToken();
          final authorization = options.headers['Authorization']?.toString();
          final hasBearerToken =
              authorization != null &&
              authorization.trim().startsWith('Bearer ');

          if (!hasBearerToken && token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (requireAuth && token == null && !hasBearerToken) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: 'Authentication token not found. Please sign in again.',
              ),
            );
          }

          final effectiveAuthorization = options.headers['Authorization']
              ?.toString();
          final hasEffectiveBearerToken =
              effectiveAuthorization != null &&
              effectiveAuthorization.trim().startsWith('Bearer ');
          if (hasEffectiveBearerToken &&
              !options.headers.containsKey('X-Device-UUID')) {
            final deviceUuid = await AppSessionStore.getDeviceUuid();
            if (deviceUuid != null) {
              options.headers['X-Device-UUID'] = deviceUuid;
            }
          }
        }

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
        final authorization = error.requestOptions.headers['Authorization']
            ?.toString();
        final hasBearerToken =
            authorization != null && authorization.trim().startsWith('Bearer ');
        if (hasBearerToken && error.response?.statusCode == 401) {
          SessionExpiryService.handleUnauthorized();
        }
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

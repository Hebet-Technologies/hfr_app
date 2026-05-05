import 'dart:io';
import 'package:dio/dio.dart';
import 'package:staffportal/data/app_exception.dart';
import 'package:staffportal/data/network/api_service.dart';
import 'package:staffportal/data/network/base_api_service.dart';
import 'package:staffportal/services/session_expiry_service.dart';

class NetworkApiService extends BaseApiService {
  final Dio _dio = createLoggedDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept': 'application/json'},
    ),
  );

  @override
  Future<dynamic> getGetApiResponse(String url) async {
    try {
      final response = await _dio.getUri(Uri.parse(url), options: skipAuth());
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getPostApiResponse(String url, data) async {
    try {
      final response = await _dio.postUri(
        Uri.parse(url),
        data: data,
        options: skipAuth(),
      );
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getGetApiResponseWithToken(String url) async {
    try {
      final response = await _dio.getUri(
        Uri.parse(url),
        options: requireAuth(),
      );
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getGetApiResponseWithTokenById(String url, id) async {
    try {
      final response = await _dio.getUri(
        Uri.parse('$url/$id'),
        options: requireAuth(),
      );
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getPostApiResponseWithToken(String url, data) async {
    try {
      final response = await _dio.postUri(
        Uri.parse(url),
        data: data,
        options: requireAuth(),
      );
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getLogoutApiResponseWithToken(String url) async {
    try {
      final response = await _dio.postUri(
        Uri.parse(url),
        options: requireAuth(),
      );
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  dynamic returnResponse(Response<dynamic> response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return response.data;
      case 400:
      case 403:
      case 404:
      case 422:
      case 500:
        throw ExceptionHandling(_messageFromData(response.data));
      case 401:
        SessionExpiryService.handleUnauthorized();
        throw ExceptionHandling(_messageFromData(response.data));
      default:
        throw ExceptionHandling(
          'Error while communicating with server with status code ${response.statusCode}',
        );
    }
  }

  ExceptionHandling _handleDioException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return ExceptionHandling('No Internet Connection');
    }

    final response = error.response;
    if (response != null) {
      if (response.statusCode == 401) {
        SessionExpiryService.handleUnauthorized();
      }
      return ExceptionHandling(_messageFromData(response.data));
    }

    return ExceptionHandling(
      error.message ?? 'Something went wrong while contacting the server.',
    );
  }

  String _messageFromData(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
      final messages = data['messages'];
      if (messages is Map && messages.isNotEmpty) {
        final first = messages.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return 'Something went wrong while contacting the server.';
  }
}

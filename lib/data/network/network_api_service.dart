import 'dart:io';
import 'package:dio/dio.dart';
import 'package:staffportal/data/app_exception.dart';
import 'package:staffportal/data/network/api_service.dart';
import 'package:staffportal/data/network/base_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final response = await _dio.getUri(Uri.parse(url));
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
      final response = await _dio.postUri(Uri.parse(url), data: data);
      return returnResponse(response);
    } on DioException catch (error) {
      throw _handleDioException(error);
    } on SocketException {
      throw ExceptionHandling('No Internet Connection');
    }
  }

  @override
  Future<dynamic> getGetApiResponseWithToken(String url) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token')!;

    try {
      final response = await _dio.getUri(
        Uri.parse(url),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token')!;

    try {
      final response = await _dio.getUri(
        Uri.parse('$url/$id'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token')!;

    try {
      final response = await _dio.postUri(
        Uri.parse(url),
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString('token')!;

    try {
      final response = await _dio.postUri(
        Uri.parse(url),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      case 401:
      case 403:
      case 404:
      case 422:
      case 500:
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

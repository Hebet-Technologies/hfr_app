import 'package:dio/dio.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/profile/models/profile_record_models.dart';

class ProfileRecordsRepository {
  ProfileRecordsRepository();

  final Dio _dio = createLoggedDio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: ApiService.defaultConnectTimeout,
      receiveTimeout: ApiService.defaultReceiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<List<ProfileRecord>> fetchRecords({
    required ProfileRecordModule module,
    required String personalInformationId,
  }) async {
    final response = await _dio.get(
      '/${module.route}/$personalInformationId',
      options: await _authorizedOptions(),
    );
    return _extractList(response.data)
        .map(
          (item) =>
              ProfileRecord(id: _stringValue(item[module.idKey]), values: item),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<ProfileLookupOption>> fetchLookup(
    ProfileLookupConfig config,
  ) async {
    final response = await _dio.get(
      config.path,
      options: await _authorizedOptions(),
    );
    return _extractList(response.data)
        .map(
          (item) => ProfileLookupOption(
            id: _stringValue(item[config.idKey]),
            label: _stringValue(item[config.labelKey]),
          ),
        )
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList()
      ..sort((first, second) => first.label.compareTo(second.label));
  }

  Future<String> saveRecord({
    required ProfileRecordModule module,
    required String personalInformationId,
    required Map<String, String> values,
    ProfileRecord? existing,
    String? filePath,
    String? fileName,
  }) async {
    final payload = <String, dynamic>{
      'personal_information_id': personalInformationId,
      ...values,
    };

    if (filePath != null && filePath.trim().isNotEmpty) {
      payload['upload_file_name'] = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );
    }

    final Response<dynamic> response;
    if (existing == null) {
      response = await _postForm('/${module.route}', data: payload);
    } else if (module.key == 'refferees') {
      payload['refferee_id'] = existing.id;
      response = await _postForm('/${module.route}', data: payload);
    } else if (module.key == 'experiences') {
      payload['experience_id'] = existing.id;
      response = await _postForm('/${module.route}', data: payload);
    } else {
      response = await _putForm(
        '/${module.route}/${existing.id}',
        data: payload,
      );
    }

    _ensureSuccessfulResponse(
      response,
      fallback: '${module.title} was not saved.',
    );
    return _extractMessage(response.data, fallback: '${module.title} saved.');
  }

  Future<String> deleteRecord({
    required ProfileRecordModule module,
    required ProfileRecord record,
  }) async {
    final response = await _dio.delete(
      '/${module.route}/${record.id}',
      options: await _authorizedOptions(),
    );
    _ensureSuccessfulResponse(
      response,
      fallback: '${module.title} record could not be deleted.',
    );
    return _extractMessage(
      response.data,
      fallback: '${module.title} record deleted.',
    );
  }

  Future<Response<dynamic>> _postForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    return _dio.post(
      path,
      data: FormData.fromMap(data),
      options: await _authorizedOptions(
        extraHeaders: const {'Content-Type': 'multipart/form-data'},
      ),
    );
  }

  Future<Response<dynamic>> _putForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    return _dio.put(
      path,
      data: FormData.fromMap(data),
      options: await _authorizedOptions(
        extraHeaders: const {'Content-Type': 'multipart/form-data'},
      ),
    );
  }

  Future<Options> _authorizedOptions({
    Map<String, String>? extraHeaders,
  }) async {
    return requireAuth(headers: extraHeaders);
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return _extractList(responseData['data']);
    }
    if (responseData is Map) {
      return _extractList(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (responseData is List) {
      return responseData
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }
    return const [];
  }

  String _extractMessage(dynamic responseData, {required String fallback}) {
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }
    if (responseData is Map) {
      return _extractMessage(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
        fallback: fallback,
      );
    }
    return fallback;
  }

  void _ensureSuccessfulResponse(
    Response<dynamic> response, {
    required String fallback,
  }) {
    final httpStatus = response.statusCode;
    if (httpStatus != null && (httpStatus < 200 || httpStatus >= 300)) {
      throw Exception(_extractMessage(response.data, fallback: fallback));
    }
    final statusCode = _extractStatusCode(response.data);
    if (statusCode == null || statusCode == 200 || statusCode == 201) return;
    throw Exception(_extractMessage(response.data, fallback: fallback));
  }

  int? _extractStatusCode(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final value = responseData['statusCode'];
      if (value is int) return value;
      return int.tryParse(value?.toString().trim() ?? '');
    }
    if (responseData is Map) {
      return _extractStatusCode(
        responseData.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  String _stringValue(dynamic value) => value?.toString().trim() ?? '';
}

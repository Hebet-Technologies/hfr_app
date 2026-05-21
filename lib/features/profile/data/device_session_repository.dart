import 'package:dio/dio.dart';

import 'package:staffportal/core/network/api_service.dart';
import 'package:staffportal/features/profile/models/device_session_models.dart';

class DeviceSessionRepository {
  DeviceSessionRepository();

  final Dio _dio = createLoggedDio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: ApiService.defaultConnectTimeout,
      receiveTimeout: ApiService.defaultReceiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<List<UserDeviceSession>> fetchDevices() async {
    final response = await _dio.get('/devices', options: requireAuth());
    return _extractList(
      response.data,
    ).map(_deviceFromApi).where((device) => device.id.isNotEmpty).toList();
  }

  Future<void> deleteDevice(String id) async {
    await _dio.delete('/devices/$id', options: requireAuth());
  }

  Future<void> deleteSession(String id) async {
    await _dio.delete('/device-sessions/$id', options: requireAuth());
  }

  UserDeviceSession _deviceFromApi(Map<String, dynamic> item) {
    final id = _stringValue(
      item['uuid'],
      fallback: _stringValue(
        item['id'],
        fallback: _stringValue(item['device_uuid']),
      ),
    );
    final sessionId = _stringValue(
      item['session_id'],
      fallback: _stringValue(item['device_session_id']),
    );
    final platform = _stringValue(
      item['platform'],
      fallback: _stringValue(item['device_platform']),
    );
    final model = _stringValue(
      item['model'],
      fallback: _stringValue(item['device_model']),
    );
    final appVersion = _stringValue(item['app_version']);
    final lastSeen = _stringValue(
      item['last_seen_at'],
      fallback: _stringValue(item['updated_at']),
    );
    final title = [
      platform,
      model,
    ].where((value) => value.isNotEmpty).join(' ');
    final subtitle = [
      if (appVersion.isNotEmpty) 'App $appVersion',
      if (lastSeen.isNotEmpty) 'Last seen $lastSeen',
    ].join(' • ');

    return UserDeviceSession(
      id: sessionId.isNotEmpty ? sessionId : id,
      deviceUuid: id,
      title: title.isEmpty ? 'Signed-in device' : title,
      subtitle: subtitle.isEmpty ? 'Active session' : subtitle,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      for (final key in ['devices', 'device_sessions', 'sessions', 'data']) {
        final value = responseData[key];
        final list = _extractList(value);
        if (list.isNotEmpty) return list;
      }
      return const [];
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

  String _stringValue(dynamic value, {String fallback = ''}) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }
}

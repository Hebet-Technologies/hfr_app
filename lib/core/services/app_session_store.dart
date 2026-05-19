import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppSessionStore {
  static const tokenKey = 'token';
  static const userIdKey = 'user_id';
  static const deviceUuidKey = 'device_uuid';
  static const sessionUuidKey = 'session_uuid';
  static const fcmTokenKey = 'fcm_token';
  static const pendingPushPayloadKey = 'pending_push_payload';
  static const authStorageKeys = <String>[
    tokenKey,
    userIdKey,
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
    'active_portal_mode',
    deviceUuidKey,
    sessionUuidKey,
  ];

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(userIdKey)?.trim();
    return userId == null || userId.isEmpty ? null : userId;
  }

  static Future<String?> getDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString(deviceUuidKey)?.trim();
    return uuid == null || uuid.isEmpty ? null : uuid;
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(fcmTokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<void> saveFcmToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(fcmTokenKey, normalized);
  }

  static Future<void> saveRealtimeSession({
    String? deviceUuid,
    String? sessionUuid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (deviceUuid != null && deviceUuid.trim().isNotEmpty) {
      await prefs.setString(deviceUuidKey, deviceUuid.trim());
    }
    if (sessionUuid != null && sessionUuid.trim().isNotEmpty) {
      await prefs.setString(sessionUuidKey, sessionUuid.trim());
    }
  }

  static Future<void> saveLoginPayload(Map<String, dynamic>? data) async {
    if (data == null) return;

    String? deviceUuid;
    String? sessionUuid;

    final device = data['device'];
    if (device is Map) {
      final normalized = device['uuid']?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        deviceUuid = normalized;
      }
    }

    final session = data['session'];
    if (session is Map) {
      final normalized = session['uuid']?.toString().trim();
      if (normalized != null && normalized.isNotEmpty) {
        sessionUuid = normalized;
      }
    }

    await saveRealtimeSession(deviceUuid: deviceUuid, sessionUuid: sessionUuid);
  }

  static Future<Map<String, String>> authorizedHeaders({
    Map<String, String>? extraHeaders,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };

    final deviceUuid = await getDeviceUuid();
    if (deviceUuid != null) {
      headers['X-Device-UUID'] = deviceUuid;
    }

    return headers;
  }

  static Future<void> savePendingPushPayload(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingPushPayloadKey, jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> takePendingPushPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(pendingPushPayloadKey);
    if (raw == null || raw.trim().isEmpty) return null;

    await prefs.remove(pendingPushPayloadKey);

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    return null;
  }

  static Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in authStorageKeys) {
      await prefs.remove(key);
    }
  }
}

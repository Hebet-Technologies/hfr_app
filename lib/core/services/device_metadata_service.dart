import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_session_store.dart';

class DeviceMetadataService {
  DeviceMetadataService._();

  static final DeviceMetadataService instance = DeviceMetadataService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<Map<String, dynamic>> buildLoginPayload({
    required String email,
    required String password,
  }) async {
    return {
      'email': email,
      'password': password,
      ...await buildDeviceRegistrationPayload(),
    };
  }

  Future<Map<String, dynamic>> buildDeviceRegistrationPayload() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final fcmToken = await AppSessionStore.getFcmToken();

    return _cleanMap({
      'fcm_token': fcmToken,
      'platform': _platformName(),
      'device_id': await _deviceId(),
      'device_name': await _deviceName(),
      'app_version': packageInfo.version,
      'timezone': DateTime.now().timeZoneName,
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
    });
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    return Platform.operatingSystem;
  }

  Future<String?> _deviceId() async {
    if (kIsWeb) return null;

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id;
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor;
      }
      if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return info.systemGUID;
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _deviceName() async {
    if (kIsWeb) return 'Web Browser';

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return [
          info.brand,
          info.model,
        ].where((part) => part.trim().isNotEmpty).join(' ');
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
      if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return info.model;
      }
    } catch (_) {}

    return null;
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> values) {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      result[entry.key] = value;
    }
    return result;
  }
}

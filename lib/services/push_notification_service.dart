import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/network/api_service.dart';
import '../model/user_model.dart';
import 'app_navigation_service.dart';
import 'app_session_store.dart';
import 'device_metadata_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final normalized = PushNotificationService.normalizeData(message.data);
  await AppSessionStore.savePendingPushPayload(normalized);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Dio _dio = createLoggedDio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  bool _initialized = false;
  bool _firebaseReady = false;
  String? _registeredBearerToken;

  Future<void> initialize() async {
    if (_initialized) {
      await _consumePendingLaunchPayload();
      return;
    }

    await _initializeLocalNotifications();

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (error) {
      log(
        'PushNotificationService Firebase init skipped: $error',
        name: 'PUSH',
      );
      _initialized = true;
      await _consumePendingLaunchPayload();
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await AppSessionStore.saveFcmToken(token);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    _messaging.onTokenRefresh.listen((token) async {
      if (token.trim().isEmpty) return;
      await AppSessionStore.saveFcmToken(token);
      final bearerToken = await AppSessionStore.getToken();
      if (bearerToken != null) {
        await registerCurrentDevice(bearerToken: bearerToken);
      }
    });

    _initialized = true;
    await _consumePendingLaunchPayload();
  }

  Future<void> registerCurrentDevice({
    required String bearerToken,
    bool force = false,
  }) async {
    if (!_firebaseReady) return;
    if (!force && _registeredBearerToken == bearerToken) return;

    final payload = await DeviceMetadataService.instance
        .buildDeviceRegistrationPayload();
    if ((payload['fcm_token']?.toString().trim() ?? '').isEmpty) {
      return;
    }

    final response = await _dio.post(
      '/devices',
      data: payload,
      options: Options(
        headers: {
          ...await AppSessionStore.authorizedHeaders(),
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final device = data['device'];
      if (device is Map) {
        final uuid = device['uuid']?.toString().trim();
        if (uuid != null && uuid.isNotEmpty) {
          await AppSessionStore.saveRealtimeSession(deviceUuid: uuid);
        }
      }
    }

    _registeredBearerToken = bearerToken;
  }

  Future<void> handleAuthenticatedSession(UserModel user) async {
    await initialize();
    await registerCurrentDevice(bearerToken: user.token, force: true);
  }

  Future<void> clearSessionBinding() async {
    _registeredBearerToken = null;
  }

  static Map<String, dynamic> normalizeData(Map<String, dynamic> source) {
    final routeParams = _decodeJsonMap(source['route_params']);
    final quickActions = _decodeJsonList(source['quick_actions']);
    final extra = _decodeJsonMap(source['extra']);

    return {
      for (final entry in source.entries) entry.key.toString(): entry.value,
      'route_params': routeParams,
      'quick_actions': quickActions,
      'extra': extra,
    };
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            await _openNormalizedPayload(decoded);
          } else if (decoded is Map) {
            await _openNormalizedPayload(
              decoded.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        } catch (_) {}
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final normalized = normalizeData(message.data);
    final title =
        message.notification?.title ??
        normalized['title']?.toString() ??
        'Notification';
    final body =
        message.notification?.body ??
        normalized['message']?.toString() ??
        '';

    await _localNotifications.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hris_realtime',
          'HRIS Notifications',
          channelDescription: 'Realtime and push notifications for HRIS',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(normalized),
    );
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    await _openNormalizedPayload(normalizeData(message.data));
  }

  Future<void> _consumePendingLaunchPayload() async {
    if (!_firebaseReady) {
      final pending = await AppSessionStore.takePendingPushPayload();
      if (pending != null) {
        await _openNormalizedPayload(pending);
      }
      return;
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _openNormalizedPayload(normalizeData(initialMessage.data));
      return;
    }

    final pending = await AppSessionStore.takePendingPushPayload();
    if (pending != null) {
      await _openNormalizedPayload(pending);
    }
  }

  Future<void> _openNormalizedPayload(Map<String, dynamic> payload) async {
    final routeName = payload['route_name']?.toString();
    final routeParams = _decodeRouteParams(payload['route_params']);
    final title = payload['title']?.toString();

    await AppNavigationService.openRoute(
      routeName: routeName,
      routeParams: routeParams,
      title: title,
    );
  }

  static Map<String, dynamic> _decodeRouteParams(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return _decodeJsonMap(value);
  }

  static Map<String, dynamic> _decodeJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, item) => MapEntry(key.toString(), item));
        }
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _decodeJsonList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.map((key, itemValue) => MapEntry(key.toString(), itemValue)))
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => item.map((key, itemValue) => MapEntry(key.toString(), itemValue)))
              .toList();
        }
      } catch (_) {}
    }
    return const <Map<String, dynamic>>[];
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import '../data/network/api_service.dart';
import '../model/user_model.dart';
import 'app_session_store.dart';

class RealtimeEnvelope {
  const RealtimeEnvelope({
    required this.channelName,
    required this.eventName,
    required this.payload,
  });

  final String channelName;
  final String eventName;
  final Map<String, dynamic> payload;
}

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();
  static const String _defaultReverbKey = 'VoiUz8527kEv5w9pSSqtaaz';
  static const String _defaultReverbHost = 'hris-api.hezo.co.tz';
  static const String _defaultReverbScheme = 'https';
  static const int _defaultReverbPort = 443;
  static const String _defaultAuthEndpoint = '/broadcasting/auth';

  final Dio _dio = createLoggedDio(
    BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  final StreamController<RealtimeEnvelope> _eventsController =
      StreamController<RealtimeEnvelope>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  String? _connectedToken;
  int? _connectedUserId;
  String? _socketId;
  bool _initialized = false;
  final Set<String> _subscribedChannels = <String>{};

  Stream<RealtimeEnvelope> get events => _eventsController.stream;

  Future<void> connect(UserModel user) async {
    final userId = int.tryParse(user.userId);
    if (userId == null) {
      throw Exception('Invalid user ID for realtime connection.');
    }

    if (_initialized &&
        _connectedToken == user.token &&
        _connectedUserId == userId) {
      return;
    }

    await disconnect();

    final config = await _fetchConfig(user.token);
    final appKey = (config['key']?.toString() ?? _defaultReverbKey).trim();
    final host = (config['host']?.toString() ?? _defaultReverbHost).trim();
    final scheme = (config['scheme']?.toString() ?? _defaultReverbScheme)
        .trim();
    final port =
        int.tryParse(config['port']?.toString() ?? '') ??
        (scheme == 'https' ? _defaultReverbPort : 80);
    final authEndpoint =
        (config['auth_endpoint']?.toString() ?? _defaultAuthEndpoint).trim();

    if (appKey.isEmpty || host.isEmpty || authEndpoint.isEmpty) {
      throw Exception('Realtime configuration is incomplete.');
    }

    final socketScheme = scheme == 'https' ? 'wss' : 'ws';
    final socketUri = Uri(
      scheme: socketScheme,
      host: host,
      port: port,
      path: '/app/$appKey',
      queryParameters: const {
        'protocol': '7',
        'client': 'flutter',
        'version': '1.0',
        'flash': 'false',
      },
    );

    final socket = await WebSocket.connect(socketUri.toString());
    _socket = socket;
    _socketSubscription = socket.listen(
      _handleSocketMessage,
      onError: (Object error, StackTrace stackTrace) {
        log('Realtime socket error: $error', name: 'REALTIME');
      },
      onDone: () {
        log(
          'Realtime socket disconnected: ${socket.closeCode} ${socket.closeReason}',
          name: 'REALTIME',
        );
        _socket = null;
        _socketId = null;
        _subscribedChannels.clear();
      },
      cancelOnError: false,
    );

    _initialized = true;
    _connectedToken = user.token;
    _connectedUserId = userId;

    await _awaitConnectionEstablished();
    await subscribe('private-users.$userId');
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      for (final channel in _subscribedChannels.toList()) {
        try {
          await unsubscribe(channel);
        } catch (_) {}
      }
      try {
        await _socketSubscription?.cancel();
      } catch (_) {}
      try {
        await _socket!.close();
      } catch (_) {}
    }

    _socket = null;
    _socketSubscription = null;
    _socketId = null;
    _subscribedChannels.clear();
    _initialized = false;
    _connectedToken = null;
    _connectedUserId = null;
  }

  Future<void> subscribeConversation(String conversationUuid) {
    return subscribe('private-conversations.$conversationUuid');
  }

  Future<void> unsubscribeConversation(String conversationUuid) {
    return unsubscribe('private-conversations.$conversationUuid');
  }

  Future<void> subscribe(String channelName) async {
    if (!_initialized ||
        _socket == null ||
        _subscribedChannels.contains(channelName)) {
      return;
    }

    final authPayload = channelName.startsWith('private-')
        ? await _authorizeChannel(channelName)
        : const <String, dynamic>{};
    final data = <String, dynamic>{'channel': channelName, ...authPayload};
    _socket!.add(jsonEncode({'event': 'pusher:subscribe', 'data': data}));
    _subscribedChannels.add(channelName);
  }

  Future<void> unsubscribe(String channelName) async {
    if (_socket == null || !_subscribedChannels.contains(channelName)) return;
    _socket?.add(
      jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      }),
    );
    _subscribedChannels.remove(channelName);
  }

  Future<Map<String, dynamic>> _fetchConfig(String token) async {
    try {
      final response = await _dio.get(
        '/realtime/config',
        options: Options(
          headers: {
            ...await AppSessionStore.authorizedHeaders(),
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final reverb = payload['reverb'];
          if (reverb is Map<String, dynamic>) return reverb;
          if (reverb is Map) {
            return reverb.map((key, value) => MapEntry(key.toString(), value));
          }
        }
      }
    } catch (error) {
      log('Using default realtime config: $error', name: 'REALTIME');
    }

    return const {
      'key': _defaultReverbKey,
      'host': _defaultReverbHost,
      'scheme': _defaultReverbScheme,
      'port': _defaultReverbPort,
      'auth_endpoint': _defaultAuthEndpoint,
    };
  }

  Map<String, dynamic> _decodePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  Future<void> _awaitConnectionEstablished() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (_socketId != null && _socketId!.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw Exception('Realtime connection handshake timed out.');
  }

  Future<Map<String, dynamic>> _authorizeChannel(String channelName) async {
    final socketId = _socketId;
    if (socketId == null || socketId.isEmpty) {
      throw Exception('Realtime socket is not ready for channel auth.');
    }

    final response = await _dio.post(
      '/broadcasting/auth',
      data: {'socket_id': socketId, 'channel_name': channelName},
      options: Options(headers: await AppSessionStore.authorizedHeaders()),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception('Invalid broadcast auth response.');
  }

  void _handleSocketMessage(dynamic raw) {
    final message = _decodePayload(raw);
    final eventName = message['event']?.toString() ?? '';
    final channelName = message['channel']?.toString() ?? '';
    final payload = _decodePayload(message['data']);

    if (eventName == 'pusher:connection_established') {
      _socketId = payload['socket_id']?.toString();
      return;
    }

    if (eventName == 'pusher:ping') {
      _socket?.add(
        jsonEncode({'event': 'pusher:pong', 'data': const <String, dynamic>{}}),
      );
      return;
    }

    if (eventName.startsWith('pusher_internal:')) {
      return;
    }

    _eventsController.add(
      RealtimeEnvelope(
        channelName: channelName,
        eventName: eventName,
        payload: payload,
      ),
    );
  }
}

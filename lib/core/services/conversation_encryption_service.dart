import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:staffportal/core/services/app_session_store.dart';

class ConversationEncryptionService {
  ConversationEncryptionService._();

  static final ConversationEncryptionService instance =
      ConversationEncryptionService._();

  static const publicKeyAlgorithm = 'X25519_AES_GCM_256';
  static const encryptionVersion = 1;

  static const _privateKeyKey = 'conversation_x25519_private_key';
  static const _publicKeyKey = 'conversation_x25519_public_key';
  static const _storage = FlutterSecureStorage();

  final X25519 _keyExchange = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<ConversationDeviceKey> ensureDeviceKey() async {
    final storedPrivateKey = await _storage.read(key: _privateKeyKey);
    final storedPublicKey = await _storage.read(key: _publicKeyKey);
    if (storedPrivateKey != null &&
        storedPrivateKey.isNotEmpty &&
        storedPublicKey != null &&
        storedPublicKey.isNotEmpty) {
      return ConversationDeviceKey(
        publicKey: storedPublicKey,
        publicKeyAlgorithm: publicKeyAlgorithm,
      );
    }

    final keyPair = await _keyExchange.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyValue = base64Encode(publicKey.bytes);

    await _storage.write(
      key: _privateKeyKey,
      value: base64Encode(privateBytes),
    );
    await _storage.write(key: _publicKeyKey, value: publicKeyValue);

    return ConversationDeviceKey(
      publicKey: publicKeyValue,
      publicKeyAlgorithm: publicKeyAlgorithm,
    );
  }

  Future<Map<String, dynamic>?> encryptMessage({
    required String conversationUuid,
    required String message,
    required List<Map<String, dynamic>> devices,
  }) async {
    final normalized = message.trim();
    if (normalized.isEmpty || devices.isEmpty) return null;

    final localKeyPair = await _loadKeyPair();
    if (localKeyPair == null) return null;

    final messageKey = await _aesGcm.newSecretKey();
    final messageKeyBytes = await messageKey.extractBytes();
    final messageBox = await _aesGcm.encrypt(
      utf8.encode(normalized),
      secretKey: messageKey,
    );
    final keyId =
        'msg_${DateTime.now().microsecondsSinceEpoch}_$conversationUuid';
    final envelopes = <Map<String, dynamic>>[];

    for (final device in devices) {
      final deviceUuid = _stringValue(device['uuid']);
      final publicKeyValue = _stringValue(device['public_key']);
      final algorithm = _stringValue(device['public_key_algorithm']);
      if (deviceUuid.isEmpty ||
          publicKeyValue.isEmpty ||
          !_isSupportedDeviceAlgorithm(algorithm)) {
        continue;
      }

      final remotePublicKey = SimplePublicKey(
        base64Decode(publicKeyValue),
        type: KeyPairType.x25519,
      );
      final sharedSecret = await _keyExchange.sharedSecretKey(
        keyPair: localKeyPair,
        remotePublicKey: remotePublicKey,
      );
      final keyBox = await _aesGcm.encrypt(
        messageKeyBytes,
        secretKey: sharedSecret,
      );
      envelopes.add({
        'user_device_uuid': deviceUuid,
        'encrypted_key': _encodeSecretBox(keyBox),
        'key_id': keyId,
        'algorithm': publicKeyAlgorithm,
      });
    }

    if (envelopes.isEmpty) return null;

    return {
      'ciphertext': _encodeSecretBox(messageBox),
      'nonce': base64Encode(messageBox.nonce),
      'encryption_version': encryptionVersion,
      'key_id': keyId,
      'encryption_envelopes': envelopes,
    };
  }

  Future<String?> decryptMessage({
    required String ciphertext,
    required String nonce,
    required List<Map<String, dynamic>> envelopes,
    required List<Map<String, dynamic>> candidateDevices,
  }) async {
    if (ciphertext.trim().isEmpty || envelopes.isEmpty) return null;

    final deviceUuid = await AppSessionStore.getDeviceUuid();
    if (deviceUuid == null || deviceUuid.isEmpty) return null;
    final localEnvelope = envelopes.firstWhere(
      (item) => _stringValue(item['user_device_uuid']) == deviceUuid,
      orElse: () => const <String, dynamic>{},
    );
    if (localEnvelope.isEmpty) return null;

    final localKeyPair = await _loadKeyPair();
    if (localKeyPair == null) return null;

    final encryptedKey = _stringValue(localEnvelope['encrypted_key']);
    if (encryptedKey.isEmpty) return null;

    for (final device in candidateDevices) {
      final publicKeyValue = _stringValue(device['public_key']);
      final algorithm = _stringValue(device['public_key_algorithm']);
      if (publicKeyValue.isEmpty || !_isSupportedDeviceAlgorithm(algorithm)) {
        continue;
      }

      try {
        final sharedSecret = await _keyExchange.sharedSecretKey(
          keyPair: localKeyPair,
          remotePublicKey: SimplePublicKey(
            base64Decode(publicKeyValue),
            type: KeyPairType.x25519,
          ),
        );
        final keyBytes = await _aesGcm.decrypt(
          _decodeSecretBox(encryptedKey),
          secretKey: sharedSecret,
        );
        final messageBytes = await _aesGcm.decrypt(
          _decodeSecretBox(ciphertext, fallbackNonce: nonce),
          secretKey: SecretKey(keyBytes),
        );
        return utf8.decode(messageBytes);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<SimpleKeyPair?> _loadKeyPair() async {
    final privateKeyValue = await _storage.read(key: _privateKeyKey);
    final publicKeyValue = await _storage.read(key: _publicKeyKey);
    if (privateKeyValue == null || publicKeyValue == null) {
      await ensureDeviceKey();
      return _loadKeyPair();
    }

    return SimpleKeyPairData(
      base64Decode(privateKeyValue),
      publicKey: SimplePublicKey(
        base64Decode(publicKeyValue),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }

  String _encodeSecretBox(SecretBox box) {
    return base64Encode(
      utf8.encode(
        jsonEncode({
          'ciphertext': base64Encode(box.cipherText),
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
        }),
      ),
    );
  }

  SecretBox _decodeSecretBox(String value, {String? fallbackNonce}) {
    final decoded = jsonDecode(utf8.decode(base64Decode(value)));
    if (decoded is! Map) {
      throw const FormatException('Invalid encrypted payload.');
    }
    return SecretBox(
      base64Decode(_stringValue(decoded['ciphertext'])),
      nonce: base64Decode(
        _stringValue(decoded['nonce'], fallback: fallbackNonce ?? ''),
      ),
      mac: Mac(base64Decode(_stringValue(decoded['mac']))),
    );
  }

  bool _isSupportedDeviceAlgorithm(String value) {
    final normalized = value.toUpperCase();
    return normalized.contains('X25519');
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }
}

class ConversationDeviceKey {
  const ConversationDeviceKey({
    required this.publicKey,
    required this.publicKeyAlgorithm,
  });

  final String publicKey;
  final String publicKeyAlgorithm;
}

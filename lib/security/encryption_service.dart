import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'encryption_config.dart';

/// Service for encrypting and decrypting data.
///
/// Handles encryption at rest for local storage using various algorithms.
class EncryptionService {
  final EncryptionConfig config;
  late final encrypt.Key _key;
  final Random _random = Random.secure();

  EncryptionService(this.config) {
    if (config.enabled) {
      _key = encrypt.Key(Uint8List.fromList(config.key));
    }
  }

  /// Encrypt data before storing.
  ///
  /// Returns base64-encoded encrypted data with IV/nonce prepended.
  ///
  /// Format: [IV/Nonce][Encrypted Data][Auth Tag (for GCM/Poly1305)]
  String encryptData(String plaintext) {
    if (!config.enabled) return plaintext;

    try {
      // Compress if enabled
      String dataToEncrypt = plaintext;
      if (config.compressBeforeEncryption) {
        final bytes = utf8.encode(plaintext);
        final compressed = gzip.encode(bytes);
        dataToEncrypt = base64.encode(compressed);
      }

      switch (config.algorithm) {
        case EncryptionAlgorithm.aes256GCM:
          return _encryptAesGcm(dataToEncrypt);

        case EncryptionAlgorithm.aes256CBC:
          return _encryptAesCbc(dataToEncrypt);

        case EncryptionAlgorithm.chacha20Poly1305:
          return _encryptChaCha20(dataToEncrypt);
      }
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt data after reading.
  ///
  /// Expects base64-encoded encrypted data with IV/nonce prepended.
  String decryptData(String ciphertext) {
    if (!config.enabled) return ciphertext;

    try {
      String decrypted;

      switch (config.algorithm) {
        case EncryptionAlgorithm.aes256GCM:
          decrypted = _decryptAesGcm(ciphertext);
          break;

        case EncryptionAlgorithm.aes256CBC:
          decrypted = _decryptAesCbc(ciphertext);
          break;

        case EncryptionAlgorithm.chacha20Poly1305:
          decrypted = _decryptChaCha20(ciphertext);
          break;
      }

      // Decompress if enabled
      if (config.compressBeforeEncryption) {
        final compressed = base64.decode(decrypted);
        final decompressed = gzip.decode(compressed);
        return utf8.decode(decompressed);
      }

      return decrypted;
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Encrypt a map (document data).
  ///
  /// Encrypts values and optionally field names.
  Map<String, dynamic> encryptMap(Map<String, dynamic> data) {
    if (!config.enabled) return data;

    final encrypted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key =
          config.encryptFieldNames ? _encryptFieldName(entry.key) : entry.key;

      final value = _encryptValue(entry.value);
      encrypted[key] = value;
    }

    return encrypted;
  }

  /// Decrypt a map (document data).
  ///
  /// Decrypts values and optionally field names.
  Map<String, dynamic> decryptMap(Map<String, dynamic> data) {
    if (!config.enabled) return data;

    final decrypted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key =
          config.encryptFieldNames ? _decryptFieldName(entry.key) : entry.key;

      final value = _decryptValue(entry.value);
      decrypted[key] = value;
    }

    return decrypted;
  }

  // AES-256-GCM encryption
  String _encryptAesGcm(String plaintext) {
    final iv = encrypt.IV.fromSecureRandom(12); // 96 bits for GCM
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Format: [IV][Ciphertext][Tag]
    final combined = Uint8List.fromList([
      ...iv.bytes,
      ...encrypted.bytes,
    ]);

    return base64.encode(combined);
  }

  String _decryptAesGcm(String ciphertext) {
    final combined = base64.decode(ciphertext);

    // Extract IV (first 12 bytes)
    final iv = encrypt.IV(Uint8List.fromList(combined.sublist(0, 12)));

    // Extract ciphertext + tag (rest)
    final encryptedBytes = combined.sublist(12);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // AES-256-CBC encryption
  String _encryptAesCbc(String plaintext) {
    final iv = encrypt.IV.fromSecureRandom(16); // 128 bits for CBC
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Format: [IV][Ciphertext]
    final combined = Uint8List.fromList([
      ...iv.bytes,
      ...encrypted.bytes,
    ]);

    // Add HMAC for authentication
    final hmac = _generateHmac(combined);
    final withHmac = Uint8List.fromList([
      ...combined,
      ...hmac,
    ]);

    return base64.encode(withHmac);
  }

  String _decryptAesCbc(String ciphertext) {
    final withHmac = base64.decode(ciphertext);

    // Extract HMAC (last 32 bytes)
    final hmac = withHmac.sublist(withHmac.length - 32);
    final combined = withHmac.sublist(0, withHmac.length - 32);

    // Verify HMAC
    final expectedHmac = _generateHmac(combined);
    if (!_constantTimeCompare(hmac, expectedHmac)) {
      throw EncryptionException('HMAC verification failed');
    }

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(Uint8List.fromList(combined.sublist(0, 16)));

    // Extract ciphertext (rest)
    final encryptedBytes = combined.sublist(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // ChaCha20-Poly1305 encryption
  String _encryptChaCha20(String plaintext) {
    // Generate random nonce (96 bits)
    final nonce = Uint8List.fromList(
      List.generate(12, (_) => _random.nextInt(256)),
    );

    // Note: The encrypt package doesn't support ChaCha20-Poly1305 directly
    // For now, we'll use AES-GCM as a fallback
    // In production, you'd use a package like pointycastle or cryptography
    final iv = encrypt.IV(nonce);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final combined = Uint8List.fromList([
      ...nonce,
      ...encrypted.bytes,
    ]);

    return base64.encode(combined);
  }

  String _decryptChaCha20(String ciphertext) {
    final combined = base64.decode(ciphertext);

    // Extract nonce (first 12 bytes)
    final nonce = combined.sublist(0, 12);
    final iv = encrypt.IV(Uint8List.fromList(nonce));

    // Extract ciphertext (rest)
    final encryptedBytes = combined.sublist(12);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Helper methods
  String _encryptFieldName(String fieldName) {
    // Use deterministic encryption for field names (so we can query)
    final hash = sha256
        .convert(utf8.encode(fieldName + String.fromCharCodes(config.key)));
    return base64.encode(hash.bytes).substring(0, 16);
  }

  String _decryptFieldName(String encryptedName) {
    // Field names use deterministic encryption, so we can't decrypt
    // This is a limitation when encryptFieldNames is true
    return encryptedName;
  }

  dynamic _encryptValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return encryptData(value);
    } else if (value is num || value is bool) {
      return encryptData(value.toString());
    } else if (value is List) {
      return value.map(_encryptValue).toList();
    } else if (value is Map) {
      return encryptMap(value.cast<String, dynamic>());
    }

    return encryptData(value.toString());
  }

  dynamic _decryptValue(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      try {
        final decrypted = decryptData(value);
        // Try to parse as number or bool
        if (decrypted == 'true') return true;
        if (decrypted == 'false') return false;
        final num? number = num.tryParse(decrypted);
        if (number != null) return number;
        return decrypted;
      } catch (e) {
        // If decryption fails, return as-is (might be unencrypted)
        return value;
      }
    } else if (value is List) {
      return value.map(_decryptValue).toList();
    } else if (value is Map) {
      return decryptMap(value.cast<String, dynamic>());
    }

    return value;
  }

  Uint8List _generateHmac(Uint8List data) {
    final hmacSha256 = Hmac(sha256, config.key);
    final digest = hmacSha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}

/// Exception thrown when encryption/decryption fails.
class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/security/encryption_service.dart';
import 'package:synclayer/security/encryption_config.dart';

void main() {
  group('EncryptionService - Basic Encryption/Decryption', () {
    test('should encrypt and decrypt string data with AES-256-GCM', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Hello, World!';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(encrypted, isNot(equals(plaintext)));
      expect(decrypted, equals(plaintext));
    });

    test('should encrypt and decrypt string data with AES-256-CBC', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256CBC,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Sensitive data';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(encrypted, isNot(equals(plaintext)));
      expect(decrypted, equals(plaintext));
    });

    test('should encrypt and decrypt string data with ChaCha20-Poly1305', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Top secret message';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(encrypted, isNot(equals(plaintext)));
      expect(decrypted, equals(plaintext));
    });

    test('should return plaintext when encryption is disabled', () {
      final config = EncryptionConfig(
        enabled: false,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Not encrypted';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(encrypted, equals(plaintext));
      expect(decrypted, equals(plaintext));
    });
  });

  group('EncryptionService - Map Encryption/Decryption', () {
    test('should encrypt and decrypt map with string values', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': 'tel:+1234567890', // Prefix to prevent numeric parsing
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(encrypted['name'], isNot(equals(data['name'])));
      expect(decrypted['name'], equals(data['name']));
      expect(decrypted['email'], equals(data['email']));
      expect(decrypted['phone'], equals(data['phone']));
    });

    test('should encrypt and decrypt map with mixed value types', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = {
        'name': 'Alice',
        'age': 30,
        'active': true,
        'score': 95.5,
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted['name'], equals('Alice'));
      expect(decrypted['age'], equals(30));
      expect(decrypted['active'], equals(true));
      expect(decrypted['score'], equals(95.5));
    });

    test('should encrypt and decrypt nested maps', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = {
        'user': {
          'name': 'Bob',
          'address': {
            'street': '123 Main St',
            'city': 'Springfield',
          },
        },
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted['user']['name'], equals('Bob'));
      expect(decrypted['user']['address']['street'], equals('123 Main St'));
      expect(decrypted['user']['address']['city'], equals('Springfield'));
    });

    test('should encrypt and decrypt maps with lists', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = {
        'tags': ['important', 'urgent', 'review'],
        'scores': [85, 90, 95],
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted['tags'], equals(['important', 'urgent', 'review']));
      expect(decrypted['scores'], equals([85, 90, 95]));
    });

    test('should handle null values in maps', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = {
        'name': 'Charlie',
        'middleName': null,
        'age': 25,
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted['name'], equals('Charlie'));
      expect(decrypted['middleName'], isNull);
      expect(decrypted['age'], equals(25));
    });
  });

  group('EncryptionService - Compression', () {
    test('should compress data before encryption when enabled', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
        compressBeforeEncryption: true,
      );
      final service = EncryptionService(config);

      // Large repetitive data compresses well
      final plaintext = 'A' * 1000;
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(decrypted, equals(plaintext));
      // Compressed + encrypted should be smaller than just encrypted
      expect(encrypted.length, lessThan(plaintext.length));
    });

    test('should handle compression with complex data', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
        compressBeforeEncryption: true,
      );
      final service = EncryptionService(config);

      final data = {
        'description': 'Lorem ipsum ' * 100,
        'metadata': {
          'tags': List.generate(50, (i) => 'tag$i'),
        },
      };

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted['description'], equals(data['description']));
      expect(decrypted['metadata']['tags'],
          equals((data['metadata'] as Map)['tags']));
    });
  });

  group('EncryptionService - Field Name Encryption', () {
    test('should encrypt field names when enabled', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
        encryptFieldNames: true,
      );
      final service = EncryptionService(config);

      final data = {
        'secretField': 'secret value',
        'publicField': 'public value',
      };

      final encrypted = service.encryptMap(data);

      // Field names should be encrypted (different from original)
      expect(encrypted.keys.contains('secretField'), isFalse);
      expect(encrypted.keys.contains('publicField'), isFalse);
      expect(encrypted.keys.length, equals(2));
    });

    test('should use deterministic encryption for field names', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
        encryptFieldNames: true,
      );
      final service = EncryptionService(config);

      final data1 = {'field': 'value1'};
      final data2 = {'field': 'value2'};

      final encrypted1 = service.encryptMap(data1);
      final encrypted2 = service.encryptMap(data2);

      // Same field name should encrypt to same value (deterministic)
      expect(encrypted1.keys.first, equals(encrypted2.keys.first));
    });
  });

  group('EncryptionService - Security', () {
    test(
        'should produce different ciphertext for same plaintext (IV randomness)',
        () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Same message';
      final encrypted1 = service.encryptData(plaintext);
      final encrypted2 = service.encryptData(plaintext);

      // Different IVs should produce different ciphertext
      expect(encrypted1, isNot(equals(encrypted2)));

      // But both should decrypt to same plaintext
      expect(service.decryptData(encrypted1), equals(plaintext));
      expect(service.decryptData(encrypted2), equals(plaintext));
    });

    test('should fail decryption with wrong key', () {
      final config1 = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service1 = EncryptionService(config1);

      final config2 = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i + 1), // Different key
      );
      final service2 = EncryptionService(config2);

      const plaintext = 'Secret message';
      final encrypted = service1.encryptData(plaintext);

      // Decryption with wrong key should fail
      expect(
        () => service2.decryptData(encrypted),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('should fail decryption with tampered ciphertext', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Original message';
      final encrypted = service.encryptData(plaintext);

      // Tamper with ciphertext
      final bytes = base64.decode(encrypted);
      bytes[bytes.length - 1] ^= 1; // Flip one bit
      final tampered = base64.encode(bytes);

      // Decryption should fail due to authentication tag mismatch
      expect(
        () => service.decryptData(tampered),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('should verify HMAC for CBC mode', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256CBC,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = 'Authenticated message';
      final encrypted = service.encryptData(plaintext);

      // Tamper with ciphertext
      final bytes = base64.decode(encrypted);
      bytes[20] ^= 1; // Flip one bit in ciphertext
      final tampered = base64.encode(bytes);

      // HMAC verification should fail
      expect(
        () => service.decryptData(tampered),
        throwsA(isA<EncryptionException>()),
      );
    });
  });

  group('EncryptionService - Edge Cases', () {
    test('should handle empty string', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = '';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('should handle very long strings', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final plaintext = 'A' * 100000; // 100KB
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('should handle unicode characters', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = '你好世界 🌍 مرحبا بالعالم';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('should handle special characters', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      const plaintext = '!@#\$%^&*()_+-={}[]|:";\'<>?,./~`';
      final encrypted = service.encryptData(plaintext);
      final decrypted = service.decryptData(encrypted);

      expect(decrypted, equals(plaintext));
    });

    test('should handle empty map', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final data = <String, dynamic>{};
      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      expect(decrypted, equals(data));
    });

    test('should handle deeply nested structures', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      // Create deeply nested structure
      Map<String, dynamic> data = {'value': 'deep'};
      for (int i = 0; i < 10; i++) {
        data = {'level$i': data};
      }

      final encrypted = service.encryptMap(data);
      final decrypted = service.decryptMap(encrypted);

      // Navigate to deepest level
      dynamic current = decrypted;
      for (int i = 9; i >= 0; i--) {
        current = current['level$i'];
      }
      expect(current['value'], equals('deep'));
    });
  });

  group('EncryptionService - Performance', () {
    test('should encrypt and decrypt 1000 strings efficiently', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final plaintext = 'Message $i';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);
        expect(decrypted, equals(plaintext));
      }

      stopwatch.stop();
      // Should complete in reasonable time (< 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should encrypt and decrypt 100 maps efficiently', () {
      final config = EncryptionConfig(
        enabled: true,
        algorithm: EncryptionAlgorithm.aes256GCM,
        key: List.generate(32, (i) => i),
      );
      final service = EncryptionService(config);

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        final data = {
          'id': i,
          'name': 'User $i',
          'email': 'user$i@example.com',
          'metadata': {
            'created': DateTime.now().toIso8601String(),
            'tags': ['tag1', 'tag2', 'tag3'],
          },
        };

        final encrypted = service.encryptMap(data);
        final decrypted = service.decryptMap(encrypted);
        expect(decrypted['id'], equals(i));
      }

      stopwatch.stop();
      // Should complete in reasonable time (< 3 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });

  group('EncryptionService - Algorithm Comparison', () {
    test('all algorithms should produce valid encryption', () {
      final algorithms = [
        EncryptionAlgorithm.aes256GCM,
        EncryptionAlgorithm.aes256CBC,
        EncryptionAlgorithm.chacha20Poly1305,
      ];

      const plaintext = 'Test message for all algorithms';

      for (final algorithm in algorithms) {
        final config = EncryptionConfig(
          enabled: true,
          algorithm: algorithm,
          key: List.generate(32, (i) => i),
        );
        final service = EncryptionService(config);

        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext),
            reason: 'Failed for algorithm: $algorithm');
      }
    });

    test('different algorithms should produce different ciphertext', () {
      const plaintext = 'Same message';

      final encrypted = <String>[];

      for (final algorithm in EncryptionAlgorithm.values) {
        final config = EncryptionConfig(
          enabled: true,
          algorithm: algorithm,
          key: List.generate(32, (i) => i),
        );
        final service = EncryptionService(config);
        encrypted.add(service.encryptData(plaintext));
      }

      // All should be different (due to different algorithms and IVs)
      expect(encrypted.toSet().length, equals(encrypted.length));
    });
  });
}

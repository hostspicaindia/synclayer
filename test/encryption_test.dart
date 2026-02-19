import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Encryption', () {
    late List<int> encryptionKey;

    setUp(() {
      // Generate a test encryption key (32 bytes)
      encryptionKey = List.generate(32, (i) => i);
    });

    group('EncryptionConfig', () {
      test('creates disabled config', () {
        final config = EncryptionConfig.disabled();

        expect(config.enabled, false);
        expect(config.key, isEmpty);
      });

      test('creates enabled config with AES-256-GCM', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
        );

        expect(config.enabled, true);
        expect(config.key, encryptionKey);
        expect(config.algorithm, EncryptionAlgorithm.aes256GCM);
      });

      test('creates enabled config with AES-256-CBC', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256CBC,
        );

        expect(config.algorithm, EncryptionAlgorithm.aes256CBC);
      });

      test('creates enabled config with ChaCha20-Poly1305', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.chacha20Poly1305,
        );

        expect(config.algorithm, EncryptionAlgorithm.chacha20Poly1305);
      });

      test('requires 32-byte key when enabled', () {
        expect(
          () => EncryptionConfig(
            enabled: true,
            key: [1, 2, 3], // Too short
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('allows any key length when disabled', () {
        final config = EncryptionConfig(
          enabled: false,
          key: [1, 2, 3], // Short key is OK when disabled
        );

        expect(config.enabled, false);
      });

      test('toString does not expose key', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
        );

        final str = config.toString();
        expect(str, isNot(contains(encryptionKey.toString())));
        expect(str, contains('enabled: true'));
        expect(str, contains('aes256GCM'));
      });
    });

    group('EncryptionService - AES-256-GCM', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
          compressBeforeEncryption: false, // Disable for predictable tests
        );
        service = EncryptionService(config);
      });

      test('encrypts and decrypts string data', () {
        final plaintext = 'Hello, World!';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(encrypted, isNot(equals(plaintext)));
        expect(decrypted, equals(plaintext));
      });

      test('produces different ciphertext for same plaintext', () {
        final plaintext = 'Hello, World!';
        final encrypted1 = service.encryptData(plaintext);
        final encrypted2 = service.encryptData(plaintext);

        // Different IVs should produce different ciphertext
        expect(encrypted1, isNot(equals(encrypted2)));

        // But both decrypt to same plaintext
        expect(service.decryptData(encrypted1), equals(plaintext));
        expect(service.decryptData(encrypted2), equals(plaintext));
      });

      test('handles empty string', () {
        final plaintext = '';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('handles long text', () {
        final plaintext = 'A' * 10000;
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('handles special characters', () {
        final plaintext = '🎉 Hello! @#\$%^&*() 你好';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('throws on invalid ciphertext', () {
        expect(
          () => service.decryptData('invalid-base64'),
          throwsA(isA<EncryptionException>()),
        );
      });

      test('throws on tampered ciphertext', () {
        final plaintext = 'Hello, World!';
        final encrypted = service.encryptData(plaintext);

        // Tamper with the ciphertext
        final tampered = encrypted.substring(0, encrypted.length - 5) + 'XXXXX';

        expect(
          () => service.decryptData(tampered),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('EncryptionService - AES-256-CBC', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256CBC,
          compressBeforeEncryption: false,
        );
        service = EncryptionService(config);
      });

      test('encrypts and decrypts with CBC mode', () {
        final plaintext = 'Hello, CBC!';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('verifies HMAC on decryption', () {
        final plaintext = 'Hello, World!';
        final encrypted = service.encryptData(plaintext);

        // Tamper with HMAC (last 32 bytes)
        final bytes = Uint8List.fromList(encrypted.codeUnits);
        bytes[bytes.length - 1] ^= 0xFF;
        final tampered = String.fromCharCodes(bytes);

        expect(
          () => service.decryptData(tampered),
          throwsA(isA<EncryptionException>()),
        );
      });
    });

    group('EncryptionService - ChaCha20-Poly1305', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.chacha20Poly1305,
          compressBeforeEncryption: false,
        );
        service = EncryptionService(config);
      });

      test('encrypts and decrypts with ChaCha20', () {
        final plaintext = 'Hello, ChaCha20!';
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });
    });

    group('EncryptionService - Compression', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
          compressBeforeEncryption: true,
        );
        service = EncryptionService(config);
      });

      test('compresses before encryption', () {
        final plaintext = 'A' * 1000; // Highly compressible
        final encrypted = service.encryptData(plaintext);
        final decrypted = service.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
        // Encrypted size should be smaller due to compression
        expect(encrypted.length, lessThan(plaintext.length));
      });
    });

    group('EncryptionService - Map Encryption', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
          compressBeforeEncryption: false,
        );
        service = EncryptionService(config);
      });

      test('encrypts and decrypts map', () {
        final data = {
          'name': 'John Doe',
          'age': 30,
          'active': true,
        };

        final encrypted = service.encryptMap(data);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted['name'], equals('John Doe'));
        expect(decrypted['age'], equals(30));
        expect(decrypted['active'], equals(true));
      });

      test('encrypts nested maps', () {
        final data = {
          'user': {
            'name': 'John',
            'profile': {
              'bio': 'Developer',
            },
          },
        };

        final encrypted = service.encryptMap(data);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted['user']['name'], equals('John'));
        expect(decrypted['user']['profile']['bio'], equals('Developer'));
      });

      test('encrypts arrays', () {
        final data = {
          'tags': ['flutter', 'dart', 'mobile'],
        };

        final encrypted = service.encryptMap(data);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted['tags'], equals(['flutter', 'dart', 'mobile']));
      });

      test('handles null values', () {
        final data = {
          'name': 'John',
          'email': null,
        };

        final encrypted = service.encryptMap(data);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted['name'], equals('John'));
        expect(decrypted['email'], isNull);
      });
    });

    group('EncryptionService - Field Name Encryption', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
          encryptFieldNames: true,
          compressBeforeEncryption: false,
        );
        service = EncryptionService(config);
      });

      test('encrypts field names', () {
        final data = {
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        final encrypted = service.encryptMap(data);

        // Field names should be encrypted (not visible)
        expect(encrypted.containsKey('name'), false);
        expect(encrypted.containsKey('email'), false);

        // Note: Field name encryption uses deterministic hashing,
        // so we can't decrypt field names back to original
        // This is a known limitation when encryptFieldNames is true
        // Values are still encrypted and can be decrypted
      });
    });

    group('EncryptionService - Disabled', () {
      late EncryptionService service;

      setUp(() {
        final config = EncryptionConfig.disabled();
        service = EncryptionService(config);
      });

      test('returns plaintext when disabled', () {
        final plaintext = 'Hello, World!';
        final encrypted = service.encryptData(plaintext);

        expect(encrypted, equals(plaintext));
      });

      test('returns map as-is when disabled', () {
        final data = {'name': 'John'};
        final encrypted = service.encryptMap(data);

        expect(encrypted, equals(data));
      });
    });

    group('Real-world scenarios', () {
      test('healthcare data encryption', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
        );
        final service = EncryptionService(config);

        final patientData = {
          'patientId': 'P12345',
          'name': 'John Doe',
          'ssn': '123-45-6789',
          'diagnosis': 'Hypertension',
          'medications': ['Lisinopril', 'Aspirin'],
        };

        final encrypted = service.encryptMap(patientData);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted, equals(patientData));
        // Verify sensitive data is encrypted
        expect(encrypted['ssn'], isNot(equals('123-45-6789')));
      });

      test('financial data encryption', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
        );
        final service = EncryptionService(config);

        final transactionData = {
          'accountNumber': '1234567890',
          'amount': 1000.50,
          'currency': 'USD',
          'cardNumber': '4111-1111-1111-1111',
        };

        final encrypted = service.encryptMap(transactionData);
        final decrypted = service.decryptMap(encrypted);

        // Values are preserved
        expect(decrypted['amount'], equals(1000.50));
        expect(decrypted['currency'], equals('USD'));
        // Verify sensitive data is encrypted
        expect(encrypted['cardNumber'], isNot(contains('4111')));
      });

      test('legal document encryption', () {
        final config = EncryptionConfig(
          enabled: true,
          key: encryptionKey,
          algorithm: EncryptionAlgorithm.aes256GCM,
          compressBeforeEncryption: true, // Compress large documents
        );
        final service = EncryptionService(config);

        final legalDoc = {
          'caseNumber': 'CASE-2024-001',
          'clientName': 'John Doe',
          'document': 'A' * 10000, // Large document
          'confidential': true,
        };

        final encrypted = service.encryptMap(legalDoc);
        final decrypted = service.decryptMap(encrypted);

        expect(decrypted, equals(legalDoc));
      });
    });
  });
}

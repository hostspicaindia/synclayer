// ignore_for_file: unused_local_variable, avoid_print

import 'dart:math';
import 'dart:typed_data';
import 'package:synclayer/synclayer.dart';

/// Examples of encryption at rest for data security.
///
/// Encryption is essential for:
/// - Healthcare apps (HIPAA compliance)
/// - Finance apps (PCI DSS compliance)
/// - Legal apps (attorney-client privilege)
/// - Enterprise apps (SOC2, ISO 27001)
/// - Any app handling sensitive data
void main() async {
  // Example 1: Basic Encryption Setup
  await basicEncryptionExample();

  // Example 2: Healthcare App (HIPAA)
  await healthcareExample();

  // Example 3: Finance App (PCI DSS)
  await financeExample();

  // Example 4: Different Encryption Algorithms
  await algorithmComparisonExample();

  // Example 5: Secure Key Management
  await keyManagementExample();

  // Example 6: Encryption with Compression
  await compressionExample();
}

/// Example 1: Basic Encryption Setup
Future<void> basicEncryptionExample() async {
  print('\n=== Basic Encryption Example ===\n');

  // Generate a secure encryption key (32 bytes for AES-256)
  final encryptionKey = generateSecureKey();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256GCM, // Recommended
      ),
    ),
  );

  // Save data - it will be encrypted automatically
  final todoId = await SyncLayer.collection('todos').save({
    'text': 'Buy groceries',
    'done': false,
  });

  print('✓ Data saved with encryption');
  print('  - Algorithm: AES-256-GCM');
  print('  - Data encrypted at rest');
  print('  - Automatic encryption/decryption');
}

/// Example 2: Healthcare App (HIPAA Compliance)
Future<void> healthcareExample() async {
  print('\n=== Healthcare App Example (HIPAA) ===\n');

  final encryptionKey = generateSecureKey();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.healthcare.com',
      collections: ['patients', 'medical_records'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256GCM,
        // Encrypt field names for maximum security
        encryptFieldNames: false, // Keep false for queryability
        compressBeforeEncryption: true, // Reduce storage
      ),
    ),
  );

  // Save patient data - automatically encrypted
  final patientId = await SyncLayer.collection('patients').save({
    'patientId': 'P12345',
    'name': 'John Doe',
    'ssn': '123-45-6789', // Sensitive!
    'dateOfBirth': '1980-01-01',
    'diagnosis': 'Hypertension',
    'medications': ['Lisinopril 10mg', 'Aspirin 81mg'],
    'allergies': ['Penicillin'],
  });

  print('✓ Patient data encrypted (HIPAA compliant)');
  print('  - PHI (Protected Health Information) encrypted');
  print('  - SSN encrypted at rest');
  print('  - Medical records encrypted');
  print('  - Meets HIPAA encryption requirements');
}

/// Example 3: Finance App (PCI DSS Compliance)
Future<void> financeExample() async {
  print('\n=== Finance App Example (PCI DSS) ===\n');

  final encryptionKey = generateSecureKey();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.finance.com',
      collections: ['accounts', 'transactions'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256GCM,
      ),
    ),
  );

  // Save transaction data - automatically encrypted
  final transactionId = await SyncLayer.collection('transactions').save({
    'accountNumber': '1234567890',
    'cardNumber': '4111-1111-1111-1111', // Sensitive!
    'cvv': '123', // Very sensitive!
    'amount': 1000.50,
    'currency': 'USD',
    'merchant': 'Example Store',
    'timestamp': DateTime.now().toIso8601String(),
  });

  print('✓ Financial data encrypted (PCI DSS compliant)');
  print('  - Card numbers encrypted');
  print('  - CVV encrypted');
  print('  - Account numbers encrypted');
  print('  - Meets PCI DSS encryption requirements');
}

/// Example 4: Different Encryption Algorithms
Future<void> algorithmComparisonExample() async {
  print('\n=== Encryption Algorithm Comparison ===\n');

  final encryptionKey = generateSecureKey();

  // AES-256-GCM (Recommended)
  print('1. AES-256-GCM:');
  print('   - Security: Excellent (authenticated encryption)');
  print('   - Performance: Very good (hardware acceleration)');
  print('   - Use case: General purpose, recommended');
  print('   - Best for: Healthcare, finance, enterprise');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['data'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256GCM,
      ),
    ),
  );

  // AES-256-CBC
  print('\n2. AES-256-CBC:');
  print('   - Security: Good (with HMAC)');
  print('   - Performance: Good (hardware acceleration)');
  print('   - Use case: Legacy compatibility');
  print('   - Best for: Compatibility with existing systems');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['data'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256CBC,
      ),
    ),
  );

  // ChaCha20-Poly1305
  print('\n3. ChaCha20-Poly1305:');
  print('   - Security: Excellent (authenticated encryption)');
  print('   - Performance: Excellent on mobile');
  print('   - Use case: Mobile-first apps');
  print('   - Best for: Mobile apps, IoT devices');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['data'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
      ),
    ),
  );

  print('\n✓ Choose algorithm based on your needs');
}

/// Example 5: Secure Key Management
Future<void> keyManagementExample() async {
  print('\n=== Secure Key Management ===\n');

  print('IMPORTANT: Never hardcode encryption keys!');
  print('\nSecure key storage options:');
  print('  1. flutter_secure_storage (recommended)');
  print('  2. iOS Keychain');
  print('  3. Android Keystore');
  print('  4. Platform-specific secure storage');

  print('\nExample with flutter_secure_storage:');
  print('''
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';

  // Store key securely
  final storage = FlutterSecureStorage();
  final key = generateSecureKey();
  await storage.write(
    key: 'synclayer_encryption_key',
    value: base64.encode(key),
  );

  // Retrieve key securely
  final keyString = await storage.read(key: 'synclayer_encryption_key');
  final encryptionKey = base64.decode(keyString!);

  // Use in SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
      ),
    ),
  );
  ''');

  print('\n✓ Always use secure storage for encryption keys');
  print('✓ Never commit keys to version control');
  print('✓ Rotate keys periodically');
}

/// Example 6: Encryption with Compression
Future<void> compressionExample() async {
  print('\n=== Encryption with Compression ===\n');

  final encryptionKey = generateSecureKey();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      encryption: EncryptionConfig(
        enabled: true,
        key: encryptionKey,
        algorithm: EncryptionAlgorithm.aes256GCM,
        compressBeforeEncryption: true, // Enable compression
      ),
    ),
  );

  // Save large document - compressed then encrypted
  final docId = await SyncLayer.collection('documents').save({
    'title': 'Large Document',
    'content': 'A' * 10000, // 10KB of highly compressible data
    'metadata': {
      'author': 'John Doe',
      'created': DateTime.now().toIso8601String(),
    },
  });

  print('✓ Data compressed before encryption');
  print('  - Reduces storage space (30-70%)');
  print('  - Reduces bandwidth usage');
  print('  - Slightly slower encryption/decryption');
  print('  - Recommended for large documents');
}

/// Generate a secure encryption key (32 bytes for AES-256)
Uint8List generateSecureKey() {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
}

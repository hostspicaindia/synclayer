/// Encryption algorithms supported by SyncLayer.
///
/// Each algorithm has different characteristics:
/// - AES-256-GCM: Best balance of security and performance (recommended)
/// - AES-256-CBC: Standard AES encryption
/// - ChaCha20-Poly1305: Modern, fast, mobile-optimized
enum EncryptionAlgorithm {
  /// AES-256-GCM (Galois/Counter Mode)
  ///
  /// - Security: Excellent (authenticated encryption)
  /// - Performance: Very good (hardware acceleration)
  /// - Use case: General purpose, recommended for most apps
  /// - Key size: 256 bits
  /// - IV size: 96 bits (12 bytes)
  ///
  /// Best for: Healthcare, finance, enterprise apps
  aes256GCM,

  /// AES-256-CBC (Cipher Block Chaining)
  ///
  /// - Security: Good (requires HMAC for authentication)
  /// - Performance: Good (hardware acceleration)
  /// - Use case: Legacy compatibility
  /// - Key size: 256 bits
  /// - IV size: 128 bits (16 bytes)
  ///
  /// Best for: Compatibility with existing systems
  aes256CBC,

  /// ChaCha20-Poly1305
  ///
  /// - Security: Excellent (authenticated encryption)
  /// - Performance: Excellent on mobile (no hardware needed)
  /// - Use case: Mobile-first apps
  /// - Key size: 256 bits
  /// - Nonce size: 96 bits (12 bytes)
  ///
  /// Best for: Mobile apps, IoT devices
  chacha20Poly1305,
}

/// Configuration for data encryption at rest.
///
/// SyncLayer encrypts data before storing it locally and decrypts it
/// when reading. This ensures data security even if the device is
/// compromised.
///
/// Example:
/// ```dart
/// final encryptionKey = await generateSecureKey();
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://api.example.com',
///     encryption: EncryptionConfig(
///       enabled: true,
///       key: encryptionKey,
///       algorithm: EncryptionAlgorithm.aes256GCM,
///     ),
///   ),
/// );
/// ```
class EncryptionConfig {
  /// Whether encryption is enabled.
  final bool enabled;

  /// Encryption key (must be 32 bytes for AES-256 and ChaCha20).
  ///
  /// IMPORTANT: Store this key securely using:
  /// - flutter_secure_storage
  /// - Platform keychain (iOS Keychain, Android Keystore)
  /// - Never hardcode in source code
  /// - Never commit to version control
  ///
  /// Generate using:
  /// ```dart
  /// import 'dart:math';
  /// import 'dart:typed_data';
  ///
  /// Uint8List generateSecureKey() {
  ///   final random = Random.secure();
  ///   return Uint8List.fromList(
  ///     List.generate(32, (_) => random.nextInt(256)),
  ///   );
  /// }
  /// ```
  final List<int> key;

  /// Encryption algorithm to use.
  ///
  /// Default: AES-256-GCM (recommended for most use cases)
  ///
  /// Choose based on your needs:
  /// - AES-256-GCM: Best balance (recommended)
  /// - AES-256-CBC: Legacy compatibility
  /// - ChaCha20-Poly1305: Mobile-optimized
  final EncryptionAlgorithm algorithm;

  /// Whether to encrypt field names (in addition to values).
  ///
  /// Default: false
  ///
  /// When true:
  /// - More secure (field names are hidden)
  /// - Slightly slower
  /// - Cannot query by field name without decryption
  ///
  /// When false:
  /// - Faster
  /// - Field names visible (but values encrypted)
  /// - Can query by field name
  ///
  /// Recommended: false for most apps, true for maximum security
  final bool encryptFieldNames;

  /// Whether to compress data before encryption.
  ///
  /// Default: true
  ///
  /// Benefits:
  /// - Reduces storage space (30-70% reduction)
  /// - Reduces bandwidth usage
  /// - Slightly slower encryption/decryption
  ///
  /// Recommended: true for most apps
  final bool compressBeforeEncryption;

  const EncryptionConfig({
    required this.enabled,
    required this.key,
    this.algorithm = EncryptionAlgorithm.aes256GCM,
    this.encryptFieldNames = false,
    this.compressBeforeEncryption = true,
  }) : assert(
          !enabled || key.length == 32,
          'Encryption key must be exactly 32 bytes (256 bits)',
        );

  /// Create a disabled encryption config.
  const EncryptionConfig.disabled()
      : enabled = false,
        key = const [],
        algorithm = EncryptionAlgorithm.aes256GCM,
        encryptFieldNames = false,
        compressBeforeEncryption = true;

  @override
  String toString() {
    return 'EncryptionConfig('
        'enabled: $enabled, '
        'algorithm: $algorithm, '
        'encryptFieldNames: $encryptFieldNames, '
        'compressBeforeEncryption: $compressBeforeEncryption'
        ')';
  }
}

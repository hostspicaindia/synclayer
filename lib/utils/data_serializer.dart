import 'dart:convert';

/// Abstract serializer interface for data transformation
/// Allows for encryption, compression, schema validation in the future
abstract class DataSerializer {
  /// Serialize data to string
  String serialize(Map<String, dynamic> data);

  /// Deserialize string to data
  Map<String, dynamic> deserialize(String serialized);
}

/// Default JSON serializer
class JsonDataSerializer implements DataSerializer {
  @override
  String serialize(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  @override
  Map<String, dynamic> deserialize(String serialized) {
    return jsonDecode(serialized) as Map<String, dynamic>;
  }
}

/// Future: Encrypted serializer
/// class EncryptedDataSerializer implements DataSerializer {
///   final String encryptionKey;
///
///   EncryptedDataSerializer(this.encryptionKey);
///
///   @override
///   String serialize(Map<String, dynamic> data) {
///     final json = jsonEncode(data);
///     return encrypt(json, encryptionKey);
///   }
///
///   @override
///   Map<String, dynamic> deserialize(String serialized) {
///     final json = decrypt(serialized, encryptionKey);
///     return jsonDecode(json) as Map<String, dynamic>;
///   }
/// }

/// Future: Compressed serializer
/// class CompressedDataSerializer implements DataSerializer {
///   @override
///   String serialize(Map<String, dynamic> data) {
///     final json = jsonEncode(data);
///     return compress(json);
///   }
///
///   @override
///   Map<String, dynamic> deserialize(String serialized) {
///     final json = decompress(serialized);
///     return jsonDecode(json) as Map<String, dynamic>;
///   }
/// }

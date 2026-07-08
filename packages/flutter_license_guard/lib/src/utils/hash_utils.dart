import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Utility class for hashing operations.
class HashUtils {
  HashUtils._();

  /// Computes SHA-256 of [input] string and returns hex output.
  static String sha256Hex(String input) {
    final digest = crypto.sha256.convert(utf8.encode(input));
    return digest.toString();
  }

  /// Computes SHA-256 of [data] bytes and returns the digest bytes.
  static Uint8List sha256Bytes(Uint8List data) {
    final digest = crypto.sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Computes SHA-256 of multiple strings combined.
  static String sha256OfStrings(List<String> parts) {
    final combined = parts.join();
    return sha256Hex(combined);
  }
}

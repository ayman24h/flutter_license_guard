import 'dart:convert';
import 'dart:typed_data';

/// Utility class for Base64 encoding/decoding.
class Base64Utils {
  Base64Utils._();

  /// Encodes bytes to a Base64 string (no line breaks).
  static String encode(List<int> bytes) {
    return base64Encode(bytes);
  }

  /// Decodes a Base64 string to bytes.
  static Uint8List decode(String input) {
    return base64Decode(input.trim());
  }

  /// Encodes a string to Base64.
  static String encodeString(String input) {
    return base64Encode(utf8.encode(input));
  }

  /// Decodes a Base64 string to a regular string.
  static String decodeString(String input) {
    return utf8.decode(base64Decode(input.trim()));
  }
}

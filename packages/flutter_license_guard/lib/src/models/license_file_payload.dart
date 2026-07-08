import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// Represents the encrypted license file payload.
///
/// The license file format is:
/// ```
/// [4 bytes: magic header "FLGV"]
/// [1 byte: format version]
/// [4 bytes: payload length (big-endian)]
/// [N bytes: encrypted payload (AES-256-GCM)]
/// [4 bytes: signature length (big-endian)]
/// [M bytes: Ed25519 signature of the canonical license JSON]
/// [32 bytes: SHA-256 checksum of everything above]
/// ```
class LicenseFilePayload {
  /// Creates a [LicenseFilePayload].
  const LicenseFilePayload({
    required this.encryptedPayload,
    required this.signature,
    required this.checksum,
  });

  /// Magic header bytes that identify a license file.
  static const List<int> magicHeader = [0x46, 0x4C, 0x47, 0x56]; // "FLGV"

  /// Current format version.
  static const int formatVersion = 1;

  /// AES-256-GCM encrypted license data.
  final Uint8List encryptedPayload;

  /// Ed25519 signature of the canonical (unencrypted) license JSON.
  final Uint8List signature;

  /// SHA-256 checksum of the entire file (for tamper detection).
  final Uint8List checksum;

  /// Serializes this payload into a binary license file.
  Uint8List toBytes() {
    final builder = BytesBuilder();

    // Magic header
    builder.add(Uint8List.fromList(magicHeader));

    // Format version
    builder.addByte(formatVersion);

    // Encrypted payload length + payload
    final payloadLen = _intToBytes(encryptedPayload.length, 4);
    builder.add(payloadLen);
    builder.add(encryptedPayload);

    // Signature length + signature
    final sigLen = _intToBytes(signature.length, 4);
    builder.add(sigLen);
    builder.add(signature);

    // Checksum (SHA-256 of everything so far)
    final dataSoFar = builder.toBytes();
    final computedChecksum = _sha256(dataSoFar);
    builder.add(computedChecksum);

    return builder.toBytes();
  }

  /// Deserializes a binary license file into a [LicenseFilePayload].
  ///
  /// Throws [FormatException] if the file is malformed or the checksum
  /// does not match (tamper detection).
  factory LicenseFilePayload.fromBytes(Uint8List bytes) {
    // Validate minimum length
    if (bytes.length < magicHeader.length + 1 + 4 + 4 + 32) {
      throw FormatException('License file is too short to be valid');
    }

    // Validate magic header
    for (var i = 0; i < magicHeader.length; i++) {
      if (bytes[i] != magicHeader[i]) {
        throw FormatException('Invalid license file header');
      }
    }

    var offset = magicHeader.length;

    // Read format version
    final version = bytes[offset];
    if (version != formatVersion) {
      throw FormatException('Unsupported license file version: $version');
    }
    offset += 1;

    // Read encrypted payload
    final payloadLen = _bytesToInt(bytes, offset, 4);
    offset += 4;
    if (offset + payloadLen > bytes.length) {
      throw FormatException('License file payload is truncated');
    }
    final encryptedPayload =
        Uint8List.sublistView(bytes, offset, offset + payloadLen);
    offset += payloadLen;

    // Read signature
    final sigLen = _bytesToInt(bytes, offset, 4);
    offset += 4;
    if (offset + sigLen > bytes.length) {
      throw FormatException('License file signature is truncated');
    }
    final signature = Uint8List.sublistView(bytes, offset, offset + sigLen);
    offset += sigLen;

    // Read checksum (last 32 bytes)
    if (offset + 32 > bytes.length) {
      throw FormatException('License file checksum is missing');
    }
    final storedChecksum = Uint8List.sublistView(bytes, offset, offset + 32);

    // Verify checksum (SHA-256 of everything before the checksum)
    final dataToVerify = Uint8List.sublistView(bytes, 0, offset);
    final computedChecksum = _sha256(dataToVerify);

    if (!_constantTimeEquals(storedChecksum, computedChecksum)) {
      throw FormatException(
          'License file checksum mismatch — file has been tampered with');
    }

    return LicenseFilePayload(
      encryptedPayload: encryptedPayload,
      signature: signature,
      checksum: storedChecksum,
    );
  }

  /// Converts an integer to a big-endian byte array of [length] bytes.
  static Uint8List _intToBytes(int value, int length) {
    final result = Uint8List(length);
    for (var i = length - 1; i >= 0; i--) {
      result[i] = value & 0xFF;
      value >>= 8;
    }
    return result;
  }

  /// Reads a big-endian integer from [bytes] starting at [offset].
  static int _bytesToInt(Uint8List bytes, int offset, int length) {
    var value = 0;
    for (var i = 0; i < length; i++) {
      value = (value << 8) | bytes[offset + i];
    }
    return value;
  }

  /// Computes SHA-256 hash of [data].
  static Uint8List _sha256(Uint8List data) {
    final digest = crypto.sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Constant-time byte array comparison to prevent timing attacks.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

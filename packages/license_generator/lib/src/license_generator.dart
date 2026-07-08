import 'dart:convert';
import 'dart:typed_data';

import 'license_crypto.dart';
import 'license_entity.dart';
import 'license_type.dart';
import 'license_feature.dart';

/// Generates signed, encrypted license files.
///
/// This is the core of the license_generator tool. It:
/// 1. Creates a [LicenseEntity] from the input parameters
/// 2. Signs the canonical JSON with the Ed25519 private key
/// 3. Encrypts the JSON with AES-256-GCM
/// 4. Packs everything into a binary license file with checksum
class LicenseGenerator {
  /// Creates a [LicenseGenerator].
  ///
  /// [privateKeyBase64] is the Base64-encoded Ed25519 private key seed.
  /// [encryptionKey] is the optional Base64-encoded AES-256 key.
  /// If [encryptionKey] is null, a key is derived from the device ID.
  LicenseGenerator({
    required this.privateKeyBase64,
    this.encryptionKey,
  });

  /// Base64-encoded Ed25519 private key seed.
  final String privateKeyBase64;

  /// Optional Base64-encoded AES-256 encryption key.
  final String? encryptionKey;

  /// File writer function. Set this before calling [generateToFile].
  static void Function(String path, List<int> bytes)? fileWriter;

  /// Generates a license file and returns the binary bytes.
  Future<Uint8List> generate({
    String? id,
    required String customerName,
    String? companyName,
    required String deviceId,
    required LicenseType licenseType,
    DateTime? expiryDate,
    List<LicenseFeature> features = const [],
    Map<String, dynamic>? metadata,
  }) async {
    final licenseId = id ?? _generateId();
    final effectiveExpiry = expiryDate ?? _defaultExpiry(licenseType);

    final license = LicenseEntity(
      id: licenseId,
      customerName: customerName,
      companyName: companyName,
      deviceId: deviceId,
      licenseType: licenseType,
      issueDate: DateTime.now(),
      expiryDate: effectiveExpiry,
      features: features.map((f) => f.value).toList(),
      metadata: metadata,
    );

    // Get canonical JSON for signing
    final signedData = utf8.encode(license.toSignedDataJson());
    final signedDataBytes = Uint8List.fromList(signedData);

    // Sign with Ed25519
    final signature = await LicenseCrypto.sign(
      data: signedDataBytes,
      privateKeyBase64: privateKeyBase64,
    );

    // Encrypt the JSON with AES-256-GCM
    final key = _getEncryptionKey(deviceId);
    final encryptedPayload = await LicenseCrypto.encrypt(
      plaintext: signedDataBytes,
      key: key,
    );

    // Compute checksum
    final checksum = LicenseCrypto.sha256(
      _buildFileBytes(encryptedPayload, signature, includeChecksum: false),
    );

    // Build final file
    return _buildFileBytes(
      encryptedPayload,
      signature,
      checksum: checksum,
    );
  }

  /// Generates a license and saves it to [outputPath].
  Future<String> generateToFile({
    required String outputPath,
    String? id,
    required String customerName,
    String? companyName,
    required String deviceId,
    required LicenseType licenseType,
    DateTime? expiryDate,
    List<LicenseFeature> features = const [],
    Map<String, dynamic>? metadata,
  }) async {
    final bytes = await generate(
      id: id,
      customerName: customerName,
      companyName: companyName,
      deviceId: deviceId,
      licenseType: licenseType,
      expiryDate: expiryDate,
      features: features,
      metadata: metadata,
    );

    if (LicenseGenerator.fileWriter == null) {
      throw StateError(
        'No file writer configured. Call LicenseGenerator.fileWriter = ... '
        'before generating to a file.',
      );
    }
    LicenseGenerator.fileWriter!(outputPath, bytes);
    return outputPath;
  }

  /// Returns the public key corresponding to the private key.
  Future<String> getPublicKey() async {
    return LicenseCrypto.derivePublicKey(privateKeyBase64);
  }

  Uint8List _getEncryptionKey(String deviceId) {
    if (encryptionKey != null) {
      return base64Decode(encryptionKey!);
    }
    return LicenseCrypto.deriveKey(deviceId);
  }

  DateTime? _defaultExpiry(LicenseType type) {
    switch (type) {
      case LicenseType.trial:
        return DateTime.now().add(const Duration(days: 30));
      case LicenseType.monthly:
        return DateTime.now().add(const Duration(days: 30));
      case LicenseType.yearly:
        return DateTime.now().add(const Duration(days: 365));
      case LicenseType.lifetime:
        return null;
      case LicenseType.enterprise:
        return null;
    }
  }

  String _generateId() {
    final now = DateTime.now();
    final hash = LicenseCrypto.sha256(
      Uint8List.fromList(
        utf8.encode('${now.toIso8601String()}${now.millisecond}'),
      ),
    );
    return hash
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Uint8List _buildFileBytes(
    Uint8List encryptedPayload,
    Uint8List signature, {
    Uint8List? checksum,
    bool includeChecksum = true,
  }) {
    final builder = BytesBuilder();

    // Magic header "FLGV"
    builder.add(Uint8List.fromList([0x46, 0x4C, 0x47, 0x56]));

    // Format version
    builder.addByte(1);

    // Encrypted payload length + payload
    builder.add(_intToBytes(encryptedPayload.length, 4));
    builder.add(encryptedPayload);

    // Signature length + signature
    builder.add(_intToBytes(signature.length, 4));
    builder.add(signature);

    if (includeChecksum && checksum != null) {
      builder.add(checksum);
    }

    return builder.toBytes();
  }

  Uint8List _intToBytes(int value, int length) {
    final result = Uint8List(length);
    for (var i = length - 1; i >= 0; i--) {
      result[i] = value & 0xFF;
      value >>= 8;
    }
    return result;
  }
}

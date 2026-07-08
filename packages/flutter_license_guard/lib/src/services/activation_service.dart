import 'dart:convert';
import 'dart:typed_data';

import '../crypto/aes_gcm_encryption_service.dart';
import '../crypto/ed25519_signature_service.dart';
import '../crypto/signature_service.dart';
import '../enums/license_error_code.dart';
import '../enums/license_status.dart';
import '../exceptions/activation_exception.dart';
import '../exceptions/license_corrupted_exception.dart';
import '../exceptions/license_signature_invalid_exception.dart';
import '../models/license_entity.dart';
import '../models/license_file_payload.dart';
import '../models/license_validation_result.dart';
import '../services/device_fingerprint_service.dart';
import '../storage/license_storage.dart';
import '../validators/license_validator.dart';

/// Manages the license activation workflow.
///
/// The activation flow:
/// 1. Application starts → no license found
/// 2. Generate device ID
/// 3. Show activation screen with device ID
/// 4. User enters activation code (license.dat file or Base64 string)
/// 5. Validate the license against the device and public key
/// 6. Save the license locally
/// 7. Application opens
class ActivationService {
  /// Creates an [ActivationService].
  ActivationService({
    required this.storage,
    required this.deviceFingerprintService,
    required this.signatureService,
    required this.publicKey,
    this.encryptionKey,
  });

  /// Local license storage.
  final LicenseStorage storage;

  /// Device fingerprint service.
  final DeviceFingerprintService deviceFingerprintService;

  /// Signature service for verification.
  final SignatureService signatureService;

  /// Base64-encoded Ed25519 public key.
  final String publicKey;

  /// Optional Base64-encoded AES-256 encryption key.
  final String? encryptionKey;

  /// Returns the device ID for display on the activation screen.
  Future<String> getDeviceId() async {
    return deviceFingerprintService.getDeviceId();
  }

  /// Activates a license from a Base64-encoded license file string.
  ///
  /// The [licenseData] should be a Base64-encoded binary license file
  /// as produced by the license generator tool.
  ///
  /// Returns the validation result. If successful, the license is
  /// saved to local storage.
  Future<LicenseValidationResult> activateFromBase64(
    String licenseData,
  ) async {
    try {
      final bytes = base64Decode(licenseData.trim());
      return await activateFromBytes(bytes);
    } catch (e) {
      return LicenseValidationResult.failure(
        status: LicenseStatus.corrupted,
        errorCode: LicenseErrorCode.fileCorrupted,
        message: 'Invalid license data format: $e',
      );
    }
  }

  /// Activates a license from raw binary license file bytes.
  ///
  /// Returns the validation result. If successful, the license is
  /// saved to local storage.
  Future<LicenseValidationResult> activateFromBytes(
    Uint8List bytes,
  ) async {
    try {
      // Parse the license file payload
      final payload = LicenseFilePayload.fromBytes(bytes);

      // Decrypt the license data
      final key = await _getEncryptionKey();
      final encryptionService = AesGcmEncryptionService();
      final decryptedJson = await encryptionService.decrypt(
        ciphertext: payload.encryptedPayload,
        key: key,
      );

      // Parse the license entity
      final jsonStr = utf8.decode(decryptedJson);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final license = LicenseEntity.fromJson(jsonMap);

      // Verify the signature
      final signedData = Uint8List.fromList(
        utf8.encode(license.toSignedDataJson()),
      );
      final isSignatureValid = await signatureService.verify(
        data: signedData,
        signature: payload.signature,
        publicKeyBase64: publicKey,
      );

      if (!isSignatureValid) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.invalidSignature,
          errorCode: LicenseErrorCode.signatureInvalid,
          message: 'License signature is invalid — the license may have '
              'been tampered with',
        );
      }

      // Verify device match
      final deviceId = await deviceFingerprintService.getDeviceId();
      if (license.deviceId != deviceId) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.deviceMismatch,
          errorCode: LicenseErrorCode.deviceMismatch,
          message: 'License is not valid for this device',
        );
      }

      // Check expiry
      if (license.isExpired) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.expired,
          errorCode: LicenseErrorCode.expired,
          message: 'License has expired',
        );
      }

      // Save the license file
      await storage.save(bytes);

      return LicenseValidationResult.success(
        license: license.copyWith(
          signature: base64Encode(payload.signature),
        ),
        message: 'License activated successfully',
      );
    } on FormatException catch (e) {
      return LicenseValidationResult.failure(
        status: LicenseStatus.corrupted,
        errorCode: LicenseErrorCode.fileCorrupted,
        message: e.message,
      );
    } catch (e) {
      return LicenseValidationResult.failure(
        status: LicenseStatus.corrupted,
        errorCode: LicenseErrorCode.internalError,
        message: 'Activation failed: $e',
      );
    }
  }

  /// Deactivates the current license by deleting the local file.
  ///
  /// Returns `true` if a license was removed.
  Future<bool> deactivate() async {
    return storage.delete();
  }

  Future<Uint8List> _getEncryptionKey() async {
    if (encryptionKey != null) {
      return base64Decode(encryptionKey!);
    }
    // Derive key from device fingerprint
    final deviceId = await deviceFingerprintService.getDeviceId();
    return AesGcmEncryptionService.deriveKey(deviceId);
  }
}

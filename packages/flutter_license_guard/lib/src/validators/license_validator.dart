import 'dart:convert';
import 'dart:typed_data';

import '../crypto/aes_gcm_encryption_service.dart';
import '../crypto/signature_service.dart';
import '../enums/license_error_code.dart';
import '../enums/license_status.dart';
import '../exceptions/license_corrupted_exception.dart';
import '../exceptions/license_not_found_exception.dart';
import '../models/license_entity.dart';
import '../models/license_file_payload.dart';
import '../models/license_validation_result.dart';
import '../services/device_fingerprint_service.dart';
import '../storage/license_storage.dart';

/// Validates license files against multiple security checks.
///
/// The validator performs the following checks in order:
/// 1. **File existence** — license file must exist
/// 2. **File integrity** — checksum must match (tamper detection)
/// 3. **File format** — magic header and version must be valid
/// 4. **Decryption** — payload must decrypt successfully
/// 5. **Signature** — Ed25519 signature must verify against public key
/// 6. **Device match** — license device ID must match this device
/// 7. **Expiry** — license must not be expired (with optional grace period)
class LicenseValidator {
  /// Creates a [LicenseValidator].
  LicenseValidator({
    required this.storage,
    required this.deviceFingerprintService,
    required this.signatureService,
    required this.publicKey,
    this.encryptionKey,
    this.allowOfflineGrace = false,
    this.gracePeriodDays = 0,
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

  /// Whether to allow a grace period after license expiry.
  final bool allowOfflineGrace;

  /// Number of days of grace period after expiry.
  final int gracePeriodDays;

  /// Validates the locally stored license file.
  ///
  /// Returns a [LicenseValidationResult] indicating success or the
  /// specific failure reason.
  Future<LicenseValidationResult> validate() async {
    try {
      // 1. Check file existence
      if (!await storage.exists()) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.notFound,
          errorCode: LicenseErrorCode.fileNotFound,
          message: 'No license file found. Activation is required.',
        );
      }

      // 2. Read the file
      final bytes = await storage.read();
      if (bytes == null) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.notFound,
          errorCode: LicenseErrorCode.fileNotFound,
          message: 'License file is empty or unreadable.',
        );
      }

      // 3. Parse and verify checksum (tamper detection)
      final LicenseFilePayload payload;
      try {
        payload = LicenseFilePayload.fromBytes(bytes);
      } on FormatException catch (e) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.corrupted,
          errorCode: e.message.contains('checksum')
              ? LicenseErrorCode.checksumMismatch
              : LicenseErrorCode.fileCorrupted,
          message: e.message,
        );
      }

      // 4. Decrypt the payload
      final key = await _getEncryptionKey();
      final encryptionService = AesGcmEncryptionService();

      final Uint8List decryptedJson;
      try {
        decryptedJson = await encryptionService.decrypt(
          ciphertext: payload.encryptedPayload,
          key: key,
        );
      } catch (e) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.corrupted,
          errorCode: LicenseErrorCode.fileCorrupted,
          message: 'Failed to decrypt license data: $e',
        );
      }

      // 5. Parse the license entity
      final LicenseEntity license;
      try {
        final jsonStr = utf8.decode(decryptedJson);
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        license = LicenseEntity.fromJson(jsonMap);
      } catch (e) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.corrupted,
          errorCode: LicenseErrorCode.fileCorrupted,
          message: 'Failed to parse license data: $e',
        );
      }

      // 6. Verify the digital signature
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
          message: 'License signature verification failed. '
              'The license may have been tampered with.',
        );
      }

      // 7. Verify device match
      final deviceId = await deviceFingerprintService.getDeviceId();
      if (license.deviceId != deviceId) {
        return LicenseValidationResult.failure(
          status: LicenseStatus.deviceMismatch,
          errorCode: LicenseErrorCode.deviceMismatch,
          message: 'License is bound to a different device.',
        );
      }

      // 8. Check expiry (with optional grace period)
      if (license.hasExpiry && license.expiryDate != null) {
        final now = DateTime.now();
        if (now.isAfter(license.expiryDate!)) {
          if (allowOfflineGrace && gracePeriodDays > 0) {
            final graceEnd = license.expiryDate!.add(
              Duration(days: gracePeriodDays),
            );
            if (now.isAfter(graceEnd)) {
              return LicenseValidationResult.failure(
                status: LicenseStatus.expired,
                errorCode: LicenseErrorCode.expired,
                message: 'License has expired and the grace period '
                    'has ended.',
              );
            }
            // Within grace period — allow but warn
            return LicenseValidationResult.success(
              license: license,
              message: 'License is within the grace period. '
                  'Please renew before ${license.expiryDate!.toIso8601String()}.',
            );
          }
          return LicenseValidationResult.failure(
            status: LicenseStatus.expired,
            errorCode: LicenseErrorCode.expired,
            message: 'License expired on '
                '${license.expiryDate!.toIso8601String()}.',
          );
        }
      }

      // All checks passed
      return LicenseValidationResult.success(
        license: license.copyWith(
          signature: base64Encode(payload.signature),
        ),
      );
    } catch (e) {
      return LicenseValidationResult.failure(
        status: LicenseStatus.corrupted,
        errorCode: LicenseErrorCode.internalError,
        message: 'Unexpected error during validation: $e',
      );
    }
  }

  /// Checks whether the license includes a specific feature.
  ///
  /// Returns `true` only if the license is valid and includes the
  /// given [feature] string.
  Future<bool> hasFeature(String feature) async {
    final result = await validate();
    if (!result.success || result.license == null) return false;
    return result.license!.hasFeature(feature);
  }

  Future<Uint8List> _getEncryptionKey() async {
    if (encryptionKey != null) {
      return base64Decode(encryptionKey!);
    }
    final deviceId = await deviceFingerprintService.getDeviceId();
    return AesGcmEncryptionService.deriveKey(deviceId);
  }
}

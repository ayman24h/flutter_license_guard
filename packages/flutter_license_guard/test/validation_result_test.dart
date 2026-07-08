import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/enums/license_error_code.dart';
import 'package:flutter_license_guard/src/enums/license_status.dart';
import 'package:flutter_license_guard/src/models/license_validation_result.dart';
import 'package:flutter_license_guard/src/enums/license_type.dart';
import 'package:flutter_license_guard/src/models/license_entity.dart';

void main() {
  group('LicenseValidationResult', () {
    test('success result has correct properties', () {
      final license = LicenseEntity(
        id: 'test-001',
        customerName: 'Test',
        deviceId: 'dev-123',
        licenseType: LicenseType.yearly,
        issueDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2030, 1, 1),
      );

      final result = LicenseValidationResult.success(license: license);

      expect(result.success, isTrue);
      expect(result.status, LicenseStatus.valid);
      expect(result.errorCode, LicenseErrorCode.none);
      expect(result.license, isNotNull);
      expect(result.hasLicense, isTrue);
    });

    test('failure result has correct properties', () {
      final result = LicenseValidationResult.failure(
        status: LicenseStatus.expired,
        errorCode: LicenseErrorCode.expired,
        message: 'License has expired',
      );

      expect(result.success, isFalse);
      expect(result.status, LicenseStatus.expired);
      expect(result.errorCode, LicenseErrorCode.expired);
      expect(result.message, 'License has expired');
      expect(result.license, isNull);
      expect(result.hasLicense, isFalse);
    });

    test('failure result for device mismatch', () {
      final result = LicenseValidationResult.failure(
        status: LicenseStatus.deviceMismatch,
        errorCode: LicenseErrorCode.deviceMismatch,
        message: 'Device does not match',
      );

      expect(result.success, isFalse);
      expect(result.status, LicenseStatus.deviceMismatch);
    });

    test('failure result for invalid signature', () {
      final result = LicenseValidationResult.failure(
        status: LicenseStatus.invalidSignature,
        errorCode: LicenseErrorCode.signatureInvalid,
      );

      expect(result.success, isFalse);
      expect(result.status, LicenseStatus.invalidSignature);
    });

    test('failure result for not found', () {
      final result = LicenseValidationResult.failure(
        status: LicenseStatus.notFound,
        errorCode: LicenseErrorCode.fileNotFound,
      );

      expect(result.success, isFalse);
      expect(result.status, LicenseStatus.notFound);
    });

    test('failure result for corrupted', () {
      final result = LicenseValidationResult.failure(
        status: LicenseStatus.corrupted,
        errorCode: LicenseErrorCode.fileCorrupted,
      );

      expect(result.success, isFalse);
      expect(result.status, LicenseStatus.corrupted);
    });
  });

  group('LicenseErrorCode', () {
    test('fromCode parses known codes', () {
      expect(LicenseErrorCode.fromCode('LIC_NONE'), LicenseErrorCode.none);
      expect(
        LicenseErrorCode.fromCode('LIC_ERR_EXPIRED'),
        LicenseErrorCode.expired,
      );
      expect(
        LicenseErrorCode.fromCode('LIC_ERR_SIGNATURE_INVALID'),
        LicenseErrorCode.signatureInvalid,
      );
    });

    test('fromCode returns internalError for unknown codes', () {
      expect(
        LicenseErrorCode.fromCode('UNKNOWN'),
        LicenseErrorCode.internalError,
      );
    });
  });
}

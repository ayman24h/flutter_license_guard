import '../enums/license_error_code.dart';
import '../enums/license_status.dart';
import 'license_entity.dart';

/// The result of a license validation operation.
///
/// Contains the overall success state, a human-readable message,
/// a machine-readable error code, and (on success) the validated
/// [LicenseEntity].
class LicenseValidationResult {
  /// Creates a successful validation result.
  LicenseValidationResult.success({
    required this.license,
    this.message = 'License is valid',
  })  : success = true,
        status = LicenseStatus.valid,
        errorCode = LicenseErrorCode.none;

  /// Creates a failed validation result.
  LicenseValidationResult.failure({
    required this.status,
    required this.errorCode,
    this.message = 'License validation failed',
    this.license,
  }) : success = false;

  /// Whether validation succeeded.
  final bool success;

  /// The license status.
  final LicenseStatus status;

  /// Machine-readable error code.
  final LicenseErrorCode errorCode;

  /// Human-readable message describing the result.
  final String message;

  /// The validated license entity, if available.
  final LicenseEntity? license;

  /// Convenience getter for whether a license was present.
  bool get hasLicense => license != null;

  @override
  String toString() {
    return 'LicenseValidationResult(success: $success, status: $status, '
        'errorCode: ${errorCode.code}, message: $message)';
  }
}

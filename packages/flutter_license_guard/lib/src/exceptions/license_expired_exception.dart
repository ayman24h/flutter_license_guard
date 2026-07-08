import 'license_exception.dart';

/// Thrown when a license has passed its expiry date.
class LicenseExpiredException extends LicenseException {
  /// Creates a [LicenseExpiredException].
  LicenseExpiredException({DateTime? expiryDate})
      : super(
          'License has expired${expiryDate != null ? " on ${expiryDate.toIso8601String()}" : ""}',
          code: 'LIC_ERR_EXPIRED',
        );
}

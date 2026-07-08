import 'license_exception.dart';

/// Thrown when a requested feature is not included in the license.
class LicenseFeatureNotLicensedException extends LicenseException {
  /// Creates a [LicenseFeatureNotLicensedException].
  LicenseFeatureNotLicensedException(String feature)
      : super(
          'Feature "$feature" is not licensed',
          code: 'LIC_ERR_FEATURE_NOT_LICENSED',
        );
}

import 'license_exception.dart';

/// Thrown when a license file cannot be found at the expected path.
class LicenseFileNotFoundException extends LicenseException {
  /// Creates a [LicenseFileNotFoundException].
  LicenseFileNotFoundException({String path = ''})
      : super(
          'License file not found${path.isNotEmpty ? " at: $path" : ""}',
          code: 'LIC_ERR_FILE_NOT_FOUND',
        );
}

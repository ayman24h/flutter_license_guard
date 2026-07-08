import 'license_exception.dart';

/// Thrown when a license file is corrupted, malformed, or cannot be parsed.
class LicenseCorruptedException extends LicenseException {
  /// Creates a [LicenseCorruptedException].
  LicenseCorruptedException({String detail = ''})
      : super(
          'License file is corrupted${detail.isNotEmpty ? ": $detail" : ""}',
          code: 'LIC_ERR_FILE_CORRUPTED',
        );
}

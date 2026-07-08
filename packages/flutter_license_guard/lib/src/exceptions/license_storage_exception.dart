import 'license_exception.dart';

/// Thrown when local license storage operations fail.
class LicenseStorageException extends LicenseException {
  /// Creates a [LicenseStorageException].
  LicenseStorageException(String detail)
      : super('License storage error: $detail');
}

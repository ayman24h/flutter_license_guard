import 'license_exception.dart';

/// Thrown when digital signature verification fails.
class LicenseSignatureInvalidException extends LicenseException {
  /// Creates a [LicenseSignatureInvalidException].
  const LicenseSignatureInvalidException()
      : super(
          'License signature verification failed — the license may '
          'have been tampered with',
          code: 'LIC_ERR_SIGNATURE_INVALID',
        );
}

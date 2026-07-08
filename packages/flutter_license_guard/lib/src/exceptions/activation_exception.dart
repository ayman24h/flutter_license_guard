import 'license_exception.dart';

/// Thrown when an activation code is invalid or cannot be processed.
class ActivationException extends LicenseException {
  /// Creates an [ActivationException].
  ActivationException(String detail)
      : super('Activation failed: $detail');
}

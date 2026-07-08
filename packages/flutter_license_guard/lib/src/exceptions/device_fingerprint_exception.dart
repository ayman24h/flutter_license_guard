import 'license_exception.dart';

/// Thrown when the device fingerprint cannot be generated.
class DeviceFingerprintException extends LicenseException {
  /// Creates a [DeviceFingerprintException].
  DeviceFingerprintException(String detail)
      : super('Failed to generate device fingerprint: $detail');
}

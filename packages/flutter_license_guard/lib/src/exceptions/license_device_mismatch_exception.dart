import 'license_exception.dart';

/// Thrown when the device ID in the license does not match the current device.
class LicenseDeviceMismatchException extends LicenseException {
  /// Creates a [LicenseDeviceMismatchException].
  const LicenseDeviceMismatchException({
    String expected = '',
    String actual = '',
  }) : super(
          'Device mismatch — license is not valid for this device',
          code: 'LIC_ERR_DEVICE_MISMATCH',
        );
}

import 'license_exception.dart';

/// Thrown when the SDK has not been initialized before use.
class LicenseNotInitializedException extends LicenseException {
  /// Creates a [LicenseNotInitializedException].
  const LicenseNotInitializedException()
      : super(
          'LicenseGuard has not been initialized. '
          'Call LicenseGuard.initialize() first.',
        );
}

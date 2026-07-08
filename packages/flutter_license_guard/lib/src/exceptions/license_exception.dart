/// Base exception for all license-related errors.
///
/// All custom exceptions in the SDK extend this class so callers can
/// catch any license error with a single catch clause.
class LicenseException implements Exception {
  /// Creates a [LicenseException] with an optional [message] and [code].
  const LicenseException(this.message, {this.code});

  /// Human-readable description of the error.
  final String message;

  /// Machine-readable error code (see [LicenseErrorCode]).
  final String? code;

  @override
  String toString() {
    if (code != null) {
      return 'LicenseException($code): $message';
    }
    return 'LicenseException: $message';
  }
}

/// Error codes that describe specific license validation failures.
///
/// Used by [LicenseValidationResult] to provide machine-readable
/// error information.
enum LicenseErrorCode {
  /// No error — validation succeeded.
  none('LIC_NONE'),

  /// License file not found.
  fileNotFound('LIC_ERR_FILE_NOT_FOUND'),

  /// License file could not be read or parsed.
  fileCorrupted('LIC_ERR_FILE_CORRUPTED'),

  /// Digital signature verification failed.
  signatureInvalid('LIC_ERR_SIGNATURE_INVALID'),

  /// License device ID does not match this device.
  deviceMismatch('LIC_ERR_DEVICE_MISMATCH'),

  /// License has expired.
  expired('LIC_ERR_EXPIRED'),

  /// License type is unknown or unsupported.
  unknownType('LIC_ERR_UNKNOWN_TYPE'),

  /// A required feature is not licensed.
  featureNotLicensed('LIC_ERR_FEATURE_NOT_LICENSED'),

  /// Checksum mismatch — file has been tampered with.
  checksumMismatch('LIC_ERR_CHECKSUM_MISMATCH'),

  /// Internal error during validation.
  internalError('LIC_ERR_INTERNAL'),

  /// License has been revoked.
  revoked('LIC_ERR_REVOKED');

  const LicenseErrorCode(this.code);

  /// The machine-readable error code string.
  final String code;

  /// Parses a code string into a [LicenseErrorCode].
  static LicenseErrorCode fromCode(String code) {
    return LicenseErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => LicenseErrorCode.internalError,
    );
  }
}

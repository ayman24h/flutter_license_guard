/// Represents the status of a license after validation.
enum LicenseStatus {
  /// The license is valid and active.
  valid,

  /// The license has expired.
  expired,

  /// The license does not match the current device.
  deviceMismatch,

  /// The license signature is invalid (tampered or wrong key).
  invalidSignature,

  /// The license file is corrupted or malformed.
  corrupted,

  /// No license file was found.
  notFound,

  /// A required feature is not included in the license.
  featureNotLicensed,

  /// The license has been revoked (future use).
  revoked,
}

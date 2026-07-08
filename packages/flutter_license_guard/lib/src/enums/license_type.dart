/// Represents the type of license issued to a customer.
///
/// Each type may carry different validation rules (e.g. trial licenses
/// expire, lifetime licenses do not).
enum LicenseType {
  /// A time-limited evaluation license.
  trial('trial'),

  /// A subscription license valid for one month from issue date.
  monthly('monthly'),

  /// A subscription license valid for one year from issue date.
  yearly('yearly'),

  /// A perpetual license with no expiry.
  lifetime('lifetime'),

  /// An enterprise license with extended features and no expiry.
  enterprise('enterprise');

  const LicenseType(this.value);

  /// The string value stored in the license file.
  final String value;

  /// Parses a [value] string into a [LicenseType].
  ///
  /// Throws [ArgumentError] if the value does not match any type.
  static LicenseType fromString(String value) {
    return LicenseType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown license type: $value'),
    );
  }

  /// Whether this license type has an expiry date.
  bool get hasExpiry => this != LicenseType.lifetime && this != LicenseType.enterprise;
}

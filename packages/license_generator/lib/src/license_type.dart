/// Represents the type of license issued to a customer.
enum LicenseType {
  trial('trial'),
  monthly('monthly'),
  yearly('yearly'),
  lifetime('lifetime'),
  enterprise('enterprise');

  const LicenseType(this.value);

  final String value;

  static LicenseType fromString(String value) {
    return LicenseType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown license type: $value'),
    );
  }

  bool get hasExpiry =>
      this != LicenseType.lifetime && this != LicenseType.enterprise;
}

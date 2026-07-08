/// Represents a feature that can be enabled per license.
enum LicenseFeature {
  crm('crm'),
  sales('sales'),
  inventory('inventory'),
  reports('reports'),
  accounting('accounting'),
  printing('printing'),
  backup('backup'),
  multiBranch('multi_branch');

  const LicenseFeature(this.value);

  final String value;

  static LicenseFeature fromString(String value) {
    return LicenseFeature.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown license feature: $value'),
    );
  }

  static Set<LicenseFeature> fromStringList(List<String> values) {
    return values.map(fromString).toSet();
  }
}

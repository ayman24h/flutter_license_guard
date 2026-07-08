/// Represents a feature that can be enabled or disabled per license.
///
/// Features allow granular permission control so that different license
/// tiers can unlock different parts of the application.
enum LicenseFeature {
  /// Customer Relationship Management module.
  crm('crm'),

  /// Sales module.
  sales('sales'),

  /// Inventory management module.
  inventory('inventory'),

  /// Reporting module.
  reports('reports'),

  /// Accounting module.
  accounting('accounting'),

  /// Printing module.
  printing('printing'),

  /// Backup module.
  backup('backup'),

  /// Multi-branch support.
  multiBranch('multi_branch');

  const LicenseFeature(this.value);

  /// The string value stored in the license file.
  final String value;

  /// Parses a [value] string into a [LicenseFeature].
  ///
  /// Throws [ArgumentError] if the value does not match any feature.
  static LicenseFeature fromString(String value) {
    return LicenseFeature.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown license feature: $value'),
    );
  }

  /// Converts a list of string values to a set of [LicenseFeature].
  static Set<LicenseFeature> fromStringList(List<String> values) {
    return values.map(fromString).toSet();
  }
}

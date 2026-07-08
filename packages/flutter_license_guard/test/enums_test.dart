import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/enums/license_type.dart';
import 'package:flutter_license_guard/src/enums/license_feature.dart';

void main() {
  group('LicenseType', () {
    test('fromString parses valid types correctly', () {
      expect(LicenseType.fromString('trial'), LicenseType.trial);
      expect(LicenseType.fromString('monthly'), LicenseType.monthly);
      expect(LicenseType.fromString('yearly'), LicenseType.yearly);
      expect(LicenseType.fromString('lifetime'), LicenseType.lifetime);
      expect(LicenseType.fromString('enterprise'), LicenseType.enterprise);
    });

    test('fromString is case-insensitive', () {
      expect(LicenseType.fromString('TRIAL'), LicenseType.trial);
      expect(LicenseType.fromString('Lifetime'), LicenseType.lifetime);
    });

    test('fromString throws on unknown type', () {
      expect(
        () => LicenseType.fromString('unknown'),
        throwsArgumentError,
      );
    });

    test('hasExpiry returns correct values', () {
      expect(LicenseType.trial.hasExpiry, isTrue);
      expect(LicenseType.monthly.hasExpiry, isTrue);
      expect(LicenseType.yearly.hasExpiry, isTrue);
      expect(LicenseType.lifetime.hasExpiry, isFalse);
      expect(LicenseType.enterprise.hasExpiry, isFalse);
    });

    test('value returns correct string', () {
      expect(LicenseType.trial.value, 'trial');
      expect(LicenseType.enterprise.value, 'enterprise');
    });
  });

  group('LicenseFeature', () {
    test('fromString parses valid features correctly', () {
      expect(LicenseFeature.fromString('crm'), LicenseFeature.crm);
      expect(LicenseFeature.fromString('sales'), LicenseFeature.sales);
      expect(LicenseFeature.fromString('inventory'), LicenseFeature.inventory);
      expect(LicenseFeature.fromString('reports'), LicenseFeature.reports);
      expect(LicenseFeature.fromString('accounting'), LicenseFeature.accounting);
      expect(LicenseFeature.fromString('printing'), LicenseFeature.printing);
      expect(LicenseFeature.fromString('backup'), LicenseFeature.backup);
      expect(LicenseFeature.fromString('multi_branch'), LicenseFeature.multiBranch);
    });

    test('fromString is case-insensitive', () {
      expect(LicenseFeature.fromString('CRM'), LicenseFeature.crm);
      expect(LicenseFeature.fromString('SALES'), LicenseFeature.sales);
    });

    test('fromString throws on unknown feature', () {
      expect(
        () => LicenseFeature.fromString('unknown'),
        throwsArgumentError,
      );
    });

    test('fromStringList converts a list of strings', () {
      final features = LicenseFeature.fromStringList(['crm', 'sales', 'inventory']);
      expect(features, hasLength(3));
      expect(features.contains(LicenseFeature.crm), isTrue);
      expect(features.contains(LicenseFeature.sales), isTrue);
      expect(features.contains(LicenseFeature.inventory), isTrue);
    });

    test('value returns correct string', () {
      expect(LicenseFeature.crm.value, 'crm');
      expect(LicenseFeature.multiBranch.value, 'multi_branch');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/enums/license_type.dart';
import 'package:flutter_license_guard/src/models/license_entity.dart';

void main() {
  group('LicenseEntity', () {
    late LicenseEntity license;

    setUp(() {
      license = LicenseEntity(
        id: 'test-001',
        customerName: 'John Doe',
        companyName: 'ACME Corp',
        deviceId: 'device-hash-abc123',
        licenseType: LicenseType.yearly,
        issueDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2030, 1, 1),
        features: ['sales', 'inventory', 'reports'],
        metadata: {'plan': 'pro'},
      );
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'test-001',
        'customer': 'John Doe',
        'company': 'ACME Corp',
        'deviceId': 'device-hash-abc123',
        'type': 'yearly',
        'issueDate': '2025-01-01T00:00:00.000',
        'expiry': '2030-01-01T00:00:00.000',
        'features': ['sales', 'inventory', 'reports'],
        'metadata': {'plan': 'pro'},
      };

      final parsed = LicenseEntity.fromJson(json);
      expect(parsed.id, 'test-001');
      expect(parsed.customerName, 'John Doe');
      expect(parsed.companyName, 'ACME Corp');
      expect(parsed.deviceId, 'device-hash-abc123');
      expect(parsed.licenseType, LicenseType.yearly);
      expect(parsed.features, ['sales', 'inventory', 'reports']);
      expect(parsed.metadata, {'plan': 'pro'});
    });

    test('toJson serializes all fields correctly', () {
      final json = license.toJson();
      expect(json['id'], 'test-001');
      expect(json['customer'], 'John Doe');
      expect(json['company'], 'ACME Corp');
      expect(json['deviceId'], 'device-hash-abc123');
      expect(json['type'], 'yearly');
      expect(json['features'], ['sales', 'inventory', 'reports']);
    });

    test('toJson with includeSignature=false omits signature', () {
      final licenseWithSig = license.copyWith(signature: 'abc');
      final json = licenseWithSig.toJson(includeSignature: false);
      expect(json.containsKey('signature'), isFalse);
    });

    test('hasExpiry returns true when expiryDate is set', () {
      expect(license.hasExpiry, isTrue);
    });

    test('hasExpiry returns false when expiryDate is null', () {
      final lifetime = license.copyWith(clearExpiry: true);
      expect(lifetime.hasExpiry, isFalse);
    });

    test('isExpired returns false for future expiry', () {
      expect(license.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final expired = license.copyWith(
        expiryDate: DateTime(2020, 1, 1),
      );
      expect(expired.isExpired, isTrue);
    });

    test('isExpired returns false when no expiryDate', () {
      final lifetime = license.copyWith(clearExpiry: true);
      expect(lifetime.isExpired, isFalse);
    });

    test('hasFeature returns true for included features', () {
      expect(license.hasFeature('sales'), isTrue);
      expect(license.hasFeature('inventory'), isTrue);
      expect(license.hasFeature('reports'), isTrue);
    });

    test('hasFeature returns false for non-included features', () {
      expect(license.hasFeature('crm'), isFalse);
      expect(license.hasFeature('accounting'), isFalse);
    });

    test('toSignedDataJson produces deterministic output', () {
      final json1 = license.toSignedDataJson();
      final json2 = license.toSignedDataJson();
      expect(json1, json2);
    });

    test('toSignedDataJson does not include signature field', () {
      final licenseWithSig = license.copyWith(signature: 'test-sig');
      final json = licenseWithSig.toSignedDataJson();
      expect(json.contains('signature'), isFalse);
    });

    test('toSignedDataJson has sorted keys', () {
      final json = license.toSignedDataJson();
      final companyPos = json.indexOf('"company"');
      final customerPos = json.indexOf('"customer"');
      final deviceIdPos = json.indexOf('"deviceId"');
      expect(companyPos, lessThan(customerPos));
      expect(customerPos, lessThan(deviceIdPos));
    });

    test('copyWith creates a modified copy', () {
      final copy = license.copyWith(customerName: 'Jane Doe');
      expect(copy.customerName, 'Jane Doe');
      expect(copy.id, license.id);
      expect(copy.deviceId, license.deviceId);
    });

    test('copyWith clearExpiry sets expiryDate to null', () {
      final copy = license.copyWith(clearExpiry: true);
      expect(copy.expiryDate, isNull);
      expect(copy.hasExpiry, isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-002',
        'customer': 'Jane',
        'deviceId': 'dev-002',
        'type': 'lifetime',
        'issueDate': '2025-06-01T00:00:00.000',
      };

      final parsed = LicenseEntity.fromJson(json);
      expect(parsed.companyName, isNull);
      expect(parsed.expiryDate, isNull);
      expect(parsed.features, isEmpty);
      expect(parsed.metadata, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/services/stub_device_fingerprint_service.dart';
import 'package:flutter_license_guard/src/exceptions/device_fingerprint_exception.dart';

void main() {
  group('StubDeviceFingerprintService', () {
    test('generates deterministic ID from same seed', () async {
      final service1 = StubDeviceFingerprintService(seed: 'test-device-1');
      final service2 = StubDeviceFingerprintService(seed: 'test-device-1');

      final id1 = await service1.getDeviceId();
      final id2 = await service2.getDeviceId();

      expect(id1, id2);
      expect(id1.length, 64); // SHA-256 hex
    });

    test('generates different IDs from different seeds', () async {
      final service1 = StubDeviceFingerprintService(seed: 'device-A');
      final service2 = StubDeviceFingerprintService(seed: 'device-B');

      final id1 = await service1.getDeviceId();
      final id2 = await service2.getDeviceId();

      expect(id1, isNot(id2));
    });

    test('throws when no seed is provided', () async {
      final service = StubDeviceFingerprintService();

      expect(
        () => service.getDeviceId(),
        throwsA(isA<DeviceFingerprintException>()),
      );
    });

    test('generated ID is a valid hex string', () async {
      final service = StubDeviceFingerprintService(seed: 'hex-test');
      final id = await service.getDeviceId();

      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(id), isTrue);
    });
  });
}

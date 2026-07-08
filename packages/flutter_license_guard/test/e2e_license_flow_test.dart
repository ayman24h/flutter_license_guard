import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/crypto/ed25519_signature_service.dart';
import 'package:flutter_license_guard/src/crypto/aes_gcm_encryption_service.dart';
import 'package:flutter_license_guard/src/enums/license_type.dart';
import 'package:flutter_license_guard/src/enums/license_feature.dart';
import 'package:flutter_license_guard/src/models/license_entity.dart';
import 'package:flutter_license_guard/src/models/license_file_payload.dart';
import 'package:flutter_license_guard/src/services/stub_device_fingerprint_service.dart';
import 'package:flutter_license_guard/src/storage/license_storage.dart';
import 'package:flutter_license_guard/src/validators/license_validator.dart';

/// Full end-to-end test: generate a license with the same crypto as
/// the CLI tool, then validate it through the LicenseValidator.
void main() {
  group('End-to-End License Flow', () {
    test('generate -> save -> validate -> check features', () async {
      // 1. Generate key pair
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      // 2. Device ID
      const deviceId = 'test-device-hash-001';
      final fingerprintService =
          StubDeviceFingerprintService(seed: deviceId);
      final actualDeviceId = await fingerprintService.getDeviceId();

      // 3. Create license entity
      final license = LicenseEntity(
        id: 'e2e-001',
        customerName: 'E2E Test Customer',
        companyName: 'Test Corp',
        deviceId: actualDeviceId,
        licenseType: LicenseType.yearly,
        issueDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2027, 1, 1),
        features: [
          LicenseFeature.sales.value,
          LicenseFeature.inventory.value,
          LicenseFeature.reports.value,
        ],
      );

      // 4. Sign
      final signedData = Uint8List.fromList(
        utf8.encode(license.toSignedDataJson()),
      );
      final signature = await Ed25519SignatureService().sign(
        data: signedData,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      // 5. Encrypt
      final key = AesGcmEncryptionService.deriveKey(actualDeviceId);
      final encrypted = await AesGcmEncryptionService().encrypt(
        plaintext: signedData,
        key: key,
      );

      // 6. Pack into license file
      final payload = LicenseFilePayload(
        encryptedPayload: encrypted,
        signature: signature,
        checksum: Uint8List(32),
      );
      final fileBytes = payload.toBytes();

      // 7. Save to in-memory storage
      final storage = _InMemoryLicenseStorage();
      await storage.save(fileBytes);

      // 8. Validate through LicenseValidator
      final validator = LicenseValidator(
        storage: storage,
        deviceFingerprintService: fingerprintService,
        signatureService: Ed25519SignatureService(),
        publicKey: keyPair.publicKeyBase64,
      );

      final result = await validator.validate();

      expect(result.success, isTrue, reason: result.message);
      expect(result.license, isNotNull);
      expect(result.license!.customerName, 'E2E Test Customer');
      expect(result.license!.licenseType, LicenseType.yearly);

      // 9. Check features
      final hasSales =
          await validator.hasFeature(LicenseFeature.sales.value);
      final hasInventory =
          await validator.hasFeature(LicenseFeature.inventory.value);
      final hasCrm =
          await validator.hasFeature(LicenseFeature.crm.value);

      expect(hasSales, isTrue);
      expect(hasInventory, isTrue);
      expect(hasCrm, isFalse);
    });

    test('expired license is detected', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      const deviceId = 'expired-device';
      final fingerprintService =
          StubDeviceFingerprintService(seed: deviceId);
      final actualDeviceId = await fingerprintService.getDeviceId();

      final license = LicenseEntity(
        id: 'expired-001',
        customerName: 'Expired Test',
        deviceId: actualDeviceId,
        licenseType: LicenseType.yearly,
        issueDate: DateTime(2020, 1, 1),
        expiryDate: DateTime(2020, 6, 1),
        features: ['sales'],
      );

      final signedData = Uint8List.fromList(
        utf8.encode(license.toSignedDataJson()),
      );
      final signature = await Ed25519SignatureService().sign(
        data: signedData,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      final key = AesGcmEncryptionService.deriveKey(actualDeviceId);
      final encrypted = await AesGcmEncryptionService().encrypt(
        plaintext: signedData,
        key: key,
      );

      final payload = LicenseFilePayload(
        encryptedPayload: encrypted,
        signature: signature,
        checksum: Uint8List(32),
      );

      final storage = _InMemoryLicenseStorage();
      await storage.save(payload.toBytes());

      final validator = LicenseValidator(
        storage: storage,
        deviceFingerprintService: fingerprintService,
        signatureService: Ed25519SignatureService(),
        publicKey: keyPair.publicKeyBase64,
      );

      final result = await validator.validate();

      expect(result.success, isFalse);
      expect(result.status.name, 'expired');
    });

    test('device mismatch is detected', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      final fingerprintA =
          StubDeviceFingerprintService(seed: 'device-A');
      final deviceAId = await fingerprintA.getDeviceId();

      final fingerprintB =
          StubDeviceFingerprintService(seed: 'device-B');

      final license = LicenseEntity(
        id: 'mismatch-001',
        customerName: 'Mismatch Test',
        deviceId: deviceAId,
        licenseType: LicenseType.lifetime,
        issueDate: DateTime(2025, 1, 1),
        features: ['sales'],
      );

      final signedData = Uint8List.fromList(
        utf8.encode(license.toSignedDataJson()),
      );
      final signature = await Ed25519SignatureService().sign(
        data: signedData,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      final key = AesGcmEncryptionService.deriveKey(deviceAId);
      final encrypted = await AesGcmEncryptionService().encrypt(
        plaintext: signedData,
        key: key,
      );

      final payload = LicenseFilePayload(
        encryptedPayload: encrypted,
        signature: signature,
        checksum: Uint8List(32),
      );

      final storage = _InMemoryLicenseStorage();
      await storage.save(payload.toBytes());

      final validator = LicenseValidator(
        storage: storage,
        deviceFingerprintService: fingerprintB,
        signatureService: Ed25519SignatureService(),
        publicKey: keyPair.publicKeyBase64,
      );

      final result = await validator.validate();

      expect(result.success, isFalse);
    });
  });
}

/// Simple in-memory storage for testing.
class _InMemoryLicenseStorage implements LicenseStorage {
  Uint8List? _bytes;

  @override
  Future<void> save(Uint8List bytes) async {
    _bytes = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> read() async {
    return _bytes;
  }

  @override
  Future<bool> delete() async {
    if (_bytes != null) {
      _bytes = null;
      return true;
    }
    return false;
  }

  @override
  Future<bool> exists() async {
    return _bytes != null;
  }

  @override
  Future<String> get licenseFilePath async => '/memory/license.dat';
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/crypto/ed25519_signature_service.dart';
import 'package:flutter_license_guard/src/crypto/aes_gcm_encryption_service.dart';
import 'package:flutter_license_guard/src/enums/license_type.dart';
import 'package:flutter_license_guard/src/models/license_entity.dart';
import 'package:flutter_license_guard/src/models/license_file_payload.dart';

/// Integration tests that verify the full license generation and
/// validation cycle: sign -> encrypt -> pack -> unpack -> decrypt -> verify.
void main() {
  group('License File Integration', () {
    test('full sign-encrypt-pack-unpack-verify cycle', () async {
      // 1. Generate key pair
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      // 2. Create a license entity
      final license = LicenseEntity(
        id: 'test-001',
        customerName: 'Test Customer',
        deviceId: 'device-hash-123',
        licenseType: LicenseType.yearly,
        issueDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2026, 1, 1),
        features: ['sales', 'inventory'],
      );

      // 3. Sign the canonical JSON
      final signedData = Uint8List.fromList(
        utf8.encode(license.toSignedDataJson()),
      );
      final signature = await Ed25519SignatureService().sign(
        data: signedData,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      // 4. Encrypt the JSON
      final key = AesGcmEncryptionService.deriveKey('device-hash-123');
      final encrypted = await AesGcmEncryptionService().encrypt(
        plaintext: signedData,
        key: key,
      );

      // 5. Pack into license file payload
      final payload = LicenseFilePayload(
        encryptedPayload: encrypted,
        signature: signature,
        checksum: Uint8List(32),
      );

      final fileBytes = payload.toBytes();

      // 6. Unpack the license file
      final restoredPayload = LicenseFilePayload.fromBytes(fileBytes);
      expect(restoredPayload.encryptedPayload, encrypted);
      expect(restoredPayload.signature, signature);

      // 7. Decrypt
      final decrypted = await AesGcmEncryptionService().decrypt(
        ciphertext: restoredPayload.encryptedPayload,
        key: key,
      );
      expect(decrypted, signedData);

      // 8. Verify signature
      final isValid = await Ed25519SignatureService().verify(
        data: decrypted,
        signature: restoredPayload.signature,
        publicKeyBase64: keyPair.publicKeyBase64,
      );
      expect(isValid, isTrue);

      // 9. Parse license
      final jsonStr = utf8.decode(decrypted);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restoredLicense = LicenseEntity.fromJson(jsonMap);

      expect(restoredLicense.id, 'test-001');
      expect(restoredLicense.customerName, 'Test Customer');
      expect(restoredLicense.deviceId, 'device-hash-123');
      expect(restoredLicense.licenseType, LicenseType.yearly);
      expect(restoredLicense.features, ['sales', 'inventory']);
    });

    test('tampered license file is detected', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      final license = LicenseEntity(
        id: 'test-002',
        customerName: 'Test',
        deviceId: 'dev-123',
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

      final key = AesGcmEncryptionService.deriveKey('dev-123');
      final encrypted = await AesGcmEncryptionService().encrypt(
        plaintext: signedData,
        key: key,
      );

      final payload = LicenseFilePayload(
        encryptedPayload: encrypted,
        signature: signature,
        checksum: Uint8List(32),
      );

      final fileBytes = Uint8List.fromList(payload.toBytes());

      // Tamper with a byte
      fileBytes[15] ^= 0xFF;

      expect(
        () => LicenseFilePayload.fromBytes(fileBytes),
        throwsFormatException,
      );
    });
  });
}

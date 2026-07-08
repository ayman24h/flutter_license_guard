import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/crypto/aes_gcm_encryption_service.dart';

void main() {
  late AesGcmEncryptionService service;

  setUp(() {
    service = AesGcmEncryptionService();
  });

  group('AesGcmEncryptionService', () {
    test('encrypt/decrypt round-trip succeeds', () async {
      final key = AesGcmEncryptionService.deriveKey('test-passphrase');
      final plaintext =
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      final ciphertext = await service.encrypt(plaintext: plaintext, key: key);
      final decrypted =
          await service.decrypt(ciphertext: ciphertext, key: key);

      expect(decrypted, equals(plaintext));
    });

    test('encrypt produces different ciphertext for same plaintext',
        () async {
      final key = AesGcmEncryptionService.deriveKey('test-passphrase');
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

      final ct1 = await service.encrypt(plaintext: plaintext, key: key);
      final ct2 = await service.encrypt(plaintext: plaintext, key: key);

      // Nonce is random, so ciphertext should differ
      expect(ct1, isNot(equals(ct2)));
    });

    test('decrypt fails with wrong key', () async {
      final key1 = AesGcmEncryptionService.deriveKey('passphrase1');
      final key2 = AesGcmEncryptionService.deriveKey('passphrase2');
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

      final ciphertext =
          await service.encrypt(plaintext: plaintext, key: key1);

      expect(
        () => service.decrypt(ciphertext: ciphertext, key: key2),
        throwsA(anything),
      );
    });

    test('encrypt throws on invalid key length', () async {
      final shortKey = Uint8List.fromList([1, 2, 3]);
      final plaintext = Uint8List.fromList([1, 2, 3]);

      expect(
        () => service.encrypt(plaintext: plaintext, key: shortKey),
        throwsArgumentError,
      );
    });

    test('deriveKey produces 32-byte key', () {
      final key = AesGcmEncryptionService.deriveKey('my-secret');
      expect(key.length, 32);
    });

    test('deriveKey is deterministic', () {
      final key1 = AesGcmEncryptionService.deriveKey('same-passphrase');
      final key2 = AesGcmEncryptionService.deriveKey('same-passphrase');
      expect(key1, equals(key2));
    });

    test('decrypt fails with tampered ciphertext', () async {
      final key = AesGcmEncryptionService.deriveKey('test-passphrase');
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      final ciphertext =
          await service.encrypt(plaintext: plaintext, key: key);
      // Tamper with ciphertext (after nonce)
      final tampered = Uint8List.fromList(ciphertext);
      tampered[15] ^= 0xFF;

      expect(
        () => service.decrypt(ciphertext: tampered, key: key),
        throwsA(anything),
      );
    });
  });
}

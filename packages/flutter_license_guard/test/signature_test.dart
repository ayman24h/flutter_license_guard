import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/crypto/ed25519_signature_service.dart';

void main() {
  late Ed25519SignatureService service;

  setUp(() {
    service = Ed25519SignatureService();
  });

  group('Ed25519SignatureService', () {
    test('generateKeyPair returns valid key pair', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();

      final privateKeyBytes = base64Decode(keyPair.privateKeyBase64);
      final publicKeyBytes = base64Decode(keyPair.publicKeyBase64);

      // cryptography package: private key seed = 32 bytes, public key = 32 bytes
      expect(privateKeyBytes.length, 32);
      expect(publicKeyBytes.length, 32);
    });

    test('derivePublicKey matches generated public key', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();
      final derived = await Ed25519SignatureService.derivePublicKey(
        keyPair.privateKeyBase64,
      );
      expect(derived, keyPair.publicKeyBase64);
    });

    test('sign and verify round-trip succeeds', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();
      final data = Uint8List.fromList(utf8.encode('test license data'));

      final signature = await service.sign(
        data: data,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      expect(signature.length, 64);

      final isValid = await service.verify(
        data: data,
        signature: signature,
        publicKeyBase64: keyPair.publicKeyBase64,
      );

      expect(isValid, isTrue);
    });

    test('verify fails with wrong data', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();
      final data = Uint8List.fromList(utf8.encode('original data'));
      final tampered = Uint8List.fromList(utf8.encode('tampered data'));

      final signature = await service.sign(
        data: data,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      final isValid = await service.verify(
        data: tampered,
        signature: signature,
        publicKeyBase64: keyPair.publicKeyBase64,
      );

      expect(isValid, isFalse);
    });

    test('verify fails with wrong public key', () async {
      final keyPair1 = await Ed25519SignatureService.generateKeyPair();
      final keyPair2 = await Ed25519SignatureService.generateKeyPair();
      final data = Uint8List.fromList(utf8.encode('test data'));

      final signature = await service.sign(
        data: data,
        privateKeyBase64: keyPair1.privateKeyBase64,
      );

      final isValid = await service.verify(
        data: data,
        signature: signature,
        publicKeyBase64: keyPair2.publicKeyBase64,
      );

      expect(isValid, isFalse);
    });

    test('verify fails with tampered signature', () async {
      final keyPair = await Ed25519SignatureService.generateKeyPair();
      final data = Uint8List.fromList(utf8.encode('test data'));

      final signature = await service.sign(
        data: data,
        privateKeyBase64: keyPair.privateKeyBase64,
      );

      final tamperedSig = Uint8List.fromList(signature);
      tamperedSig[0] ^= 0xFF;

      final isValid = await service.verify(
        data: data,
        signature: tamperedSig,
        publicKeyBase64: keyPair.publicKeyBase64,
      );

      expect(isValid, isFalse);
    });

    test('sha256 produces correct hash', () {
      final data = Uint8List.fromList(utf8.encode('hello'));
      final hash = Ed25519SignatureService.sha256(data);
      expect(hash.length, 32);
      final expected =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
      expect(bytesToHex(hash), expected);
    });

    test('sha256Hex produces correct hex string', () {
      final hash = Ed25519SignatureService.sha256Hex('hello');
      expect(hash,
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');
    });
  });
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

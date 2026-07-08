import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Handles Ed25519 signing and AES-256-GCM encryption for the
/// license generator tool.
class LicenseCrypto {
  /// Signs [data] with the Ed25519 private key.
  ///
  /// [privateKeyBase64] is the Base64-encoded 32-byte private key seed.
  static Future<Uint8List> sign({
    required Uint8List data,
    required String privateKeyBase64,
  }) async {
    final seed = base64Decode(privateKeyBase64);
    final keyPair = await Ed25519().newKeyPairFromSeed(seed);
    final signature = await Ed25519().sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verifies a signature (useful for testing).
  static Future<bool> verify({
    required Uint8List data,
    required Uint8List signature,
    required String publicKeyBase64,
  }) async {
    final publicKeyBytes = base64Decode(publicKeyBase64);
    final publicKey = SimplePublicKey(
      publicKeyBytes,
      type: KeyPairType.ed25519,
    );
    final sig = Signature(signature, publicKey: publicKey);
    return Ed25519().verify(data, signature: sig);
  }

  /// Encrypts [plaintext] with AES-256-GCM.
  ///
  /// [key] must be 32 bytes.
  /// Format: [nonce (12 bytes)][ciphertext][mac (16 bytes)]
  static Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    if (key.length != 32) {
      throw ArgumentError('AES-256 key must be 32 bytes');
    }

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(key);
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    return Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts [ciphertext] with AES-256-GCM.
  static Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
  }) async {
    if (key.length != 32) {
      throw ArgumentError('AES-256 key must be 32 bytes');
    }
    if (ciphertext.length < 12 + 16) {
      throw ArgumentError('Ciphertext too short');
    }

    final nonce = Uint8List.sublistView(ciphertext, 0, 12);
    final mac = Uint8List.sublistView(
      ciphertext,
      ciphertext.length - 16,
    );
    final encrypted = Uint8List.sublistView(
      ciphertext,
      12,
      ciphertext.length - 16,
    );

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(key);
    final secretBox = SecretBox(
      encrypted,
      nonce: nonce,
      mac: Mac(mac),
    );

    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(decrypted);
  }

  /// Computes SHA-256 of [data].
  static Uint8List sha256(Uint8List data) {
    final digest = crypto.sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Derives a 256-bit AES key from a passphrase using SHA-256.
  static Uint8List deriveKey(String passphrase) {
    final digest = crypto.sha256.convert(utf8.encode(passphrase));
    return Uint8List.fromList(digest.bytes);
  }

  /// Generates a new Ed25519 key pair.
  ///
  /// Returns a record with [privateKeyBase64] (32-byte seed) and
  /// [publicKeyBase64] (32 bytes).
  static Future<({String privateKeyBase64, String publicKeyBase64})>
      generateKeyPair() async {
    final keyPair = await Ed25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    return (
      privateKeyBase64: base64Encode(privateKeyBytes),
      publicKeyBase64: base64Encode(publicKey.bytes),
    );
  }

  /// Derives the public key from a private key seed.
  static Future<String> derivePublicKey(String privateKeyBase64) async {
    final seed = base64Decode(privateKeyBase64);
    final keyPair = await Ed25519().newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }
}

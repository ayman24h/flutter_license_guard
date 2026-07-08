import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'signature_service.dart';

/// Ed25519 implementation of [SignatureService].
///
/// Uses the `cryptography` package for Ed25519 sign/verify operations.
/// Ed25519 provides fast, secure digital signatures with small key
/// sizes (32-byte public key, 32-byte private key seed, 64-byte signature).
class Ed25519SignatureService implements SignatureService {
  /// Creates an [Ed25519SignatureService].
  Ed25519SignatureService();

  /// Ed25519 private key seed length in bytes.
  static const int privateKeyLength = 32;

  /// Ed25519 public key length in bytes.
  static const int publicKeyLength = 32;

  /// Ed25519 signature length in bytes.
  static const int signatureLength = 64;

  final _ed25519 = Ed25519();

  @override
  Future<bool> verify({
    required Uint8List data,
    required Uint8List signature,
    required String publicKeyBase64,
  }) async {
    try {
      final publicKeyBytes = base64Decode(publicKeyBase64);
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );
      final sig = Signature(signature, publicKey: publicKey);
      return _ed25519.verify(data, signature: sig);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List> sign({
    required Uint8List data,
    required String privateKeyBase64,
  }) async {
    final seed = base64Decode(privateKeyBase64);
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final signature = await _ed25519.sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Generates a new Ed25519 key pair.
  ///
  /// Returns a record with [privateKeyBase64] (32-byte seed) and
  /// [publicKeyBase64] (32 bytes).
  ///
  /// The private key must be kept secure and never embedded in the
  /// Flutter application. The public key is safe to embed.
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

  /// Computes SHA-256 hash of [data] and returns the digest bytes.
  static Uint8List sha256(Uint8List data) {
    final digest = crypto.sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Computes SHA-256 hash of a string and returns hex output.
  static String sha256Hex(String input) {
    final digest = crypto.sha256.convert(utf8.encode(input));
    return digest.toString();
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Abstract interface for encryption/decryption operations.
///
/// Used to encrypt the license file payload so it is not readable
/// as plain JSON on disk.
abstract class EncryptionService {
  /// Encrypts [plaintext] using the provided key.
  ///
  /// Returns the ciphertext with nonce prepended and MAC appended.
  Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  });

  /// Decrypts [ciphertext] using the provided key.
  ///
  /// The nonce is expected to be prepended and MAC appended.
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
  });
}

/// AES-256-GCM implementation of [EncryptionService].
///
/// GCM (Galois/Counter Mode) provides authenticated encryption,
/// meaning the ciphertext includes an authentication tag (MAC) that
/// detects any modification to the encrypted data.
///
/// Format: [nonce (12 bytes)][ciphertext][mac (16 bytes)]
class AesGcmEncryptionService implements EncryptionService {
  /// Creates an [AesGcmEncryptionService].
  AesGcmEncryptionService();

  /// AES-256 key length in bytes.
  static const int keyLength = 32;

  /// GCM nonce (IV) length in bytes.
  static const int nonceLength = 12;

  /// GCM authentication tag (MAC) length in bytes.
  static const int macLength = 16;

  @override
  Future<Uint8List> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    if (key.length != keyLength) {
      throw ArgumentError(
        'AES-256 key must be $keyLength bytes, got ${key.length}',
      );
    }

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(key);
    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    final nonce = secretBox.nonce;
    final cipherText = secretBox.cipherText;
    final mac = secretBox.mac.bytes;

    return Uint8List.fromList([...nonce, ...cipherText, ...mac]);
  }

  @override
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required Uint8List key,
  }) async {
    if (key.length != keyLength) {
      throw ArgumentError(
        'AES-256 key must be $keyLength bytes, got ${key.length}',
      );
    }
    if (ciphertext.length < nonceLength + macLength) {
      throw ArgumentError(
        'Ciphertext is too short to contain nonce and mac',
      );
    }

    final nonce = Uint8List.sublistView(ciphertext, 0, nonceLength);
    final mac = Uint8List.sublistView(
      ciphertext,
      ciphertext.length - macLength,
    );
    final encrypted = Uint8List.sublistView(
      ciphertext,
      nonceLength,
      ciphertext.length - macLength,
    );

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(key);
    final secretBox = SecretBox(
      encrypted,
      nonce: nonce,
      mac: Mac(mac),
    );

    final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decrypted);
  }

  /// Derives a 256-bit AES key from a passphrase using SHA-256.
  static Uint8List deriveKey(String passphrase) {
    final digest = crypto.sha256.convert(utf8.encode(passphrase));
    return Uint8List.fromList(digest.bytes);
  }
}

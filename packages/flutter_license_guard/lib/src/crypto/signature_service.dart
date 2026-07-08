import 'dart:typed_data';

/// Abstract interface for digital signature operations.
///
/// The SDK uses this interface to verify license signatures.
/// The application only needs the [verify] method (public key).
/// The [sign] method is used only by the license generator tool.
abstract class SignatureService {
  /// Verifies that [signature] is valid for [data] using the public key.
  ///
  /// Returns `true` if the signature is valid, `false` otherwise.
  Future<bool> verify({
    required Uint8List data,
    required Uint8List signature,
    required String publicKeyBase64,
  });

  /// Signs [data] with the private key and returns the signature.
  ///
  /// This method is only used by the license generator, never by the
  /// Flutter application.
  Future<Uint8List> sign({
    required Uint8List data,
    required String privateKeyBase64,
  });
}

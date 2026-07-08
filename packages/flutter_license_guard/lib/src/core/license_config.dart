/// Configuration for the [LicenseGuard] SDK.
///
/// Pass this to [LicenseGuard.initialize] to configure the licensing
/// system. All fields are required unless marked optional.
class LicenseConfig {
  /// Creates a [LicenseConfig].
  ///
  /// [licensePath] is the file name for the license file. It will be
  /// stored in the platform-appropriate application data directory.
  ///
  /// [publicKey] is the Base64-encoded Ed25519 public key used to
  /// verify license signatures. This key is safe to embed in the
  /// application — it cannot be used to forge licenses.
  ///
  /// [appName] is used in the activation UI and storage directory naming.
  ///
  /// [encryptionKey] is a Base64-encoded 256-bit key used for local
  /// encrypted storage of the license file. If not provided, a
  /// device-derived key will be used.
  const LicenseConfig({
    required this.licensePath,
    required this.publicKey,
    this.appName = 'FlutterApp',
    this.encryptionKey,
    this.enableTamperDetection = true,
    this.allowOfflineGrace = false,
    this.gracePeriodDays = 0,
  });

  /// The file name for the license file (e.g. "license.dat").
  final String licensePath;

  /// Base64-encoded Ed25519 public key for signature verification.
  final String publicKey;

  /// Application name used in UI and storage paths.
  final String appName;

  /// Optional Base64-encoded 256-bit AES encryption key.
  ///
  /// If not provided, a key is derived from the device fingerprint.
  final String? encryptionKey;

  /// Whether to enable tamper detection via checksum verification.
  final bool enableTamperDetection;

  /// Whether to allow a grace period after license expiry.
  final bool allowOfflineGrace;

  /// Number of days of grace period after expiry (if allowed).
  final int gracePeriodDays;
}

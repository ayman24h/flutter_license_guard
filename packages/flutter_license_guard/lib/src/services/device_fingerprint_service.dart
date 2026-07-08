/// Abstract interface for device fingerprint generation.
///
/// Each platform (Windows, macOS, Linux) provides its own
/// implementation that collects hardware identifiers and combines
/// them into a stable, unique device hash.
abstract class DeviceFingerprintService {
  /// Returns a stable, unique identifier for this device.
  ///
  /// The identifier is a SHA-256 hash of multiple hardware values
  /// and should remain consistent across reboots and app restarts.
  ///
  /// Throws [DeviceFingerprintException] if the fingerprint cannot
  /// be generated.
  Future<String> getDeviceId();
}

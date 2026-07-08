import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

import '../exceptions/device_fingerprint_exception.dart';
import 'device_fingerprint_service.dart';

/// A stub implementation of [DeviceFingerprintService] for testing
/// and non-desktop platforms.
///
/// Generates a deterministic device ID from a provided seed value,
/// or a random one if no seed is given. **Do not use in production.**
class StubDeviceFingerprintService implements DeviceFingerprintService {
  /// Creates a [StubDeviceFingerprintService] with an optional [seed].
  ///
  /// If [seed] is provided, the device ID is deterministic (same seed
  /// always produces the same ID). This is useful for unit tests.
  StubDeviceFingerprintService({this.seed});

  /// The seed value used to generate a deterministic device ID.
  final String? seed;

  @override
  Future<String> getDeviceId() async {
    if (seed != null) {
      final hash = crypto.sha256.convert(utf8.encode(seed!));
      return hash.toString();
    }
    throw DeviceFingerprintException(
      'StubDeviceFingerprintService requires a seed for testing, '
      'or a platform-specific implementation for production use.',
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../exceptions/device_fingerprint_exception.dart';
import 'device_fingerprint_service.dart';

/// macOS implementation of [DeviceFingerprintService].
///
/// Collects the following hardware identifiers:
/// - Hardware UUID (from iorext)
/// - Platform UUID
/// - Serial number
///
/// These values are combined and hashed with SHA-256 to produce
/// a stable device fingerprint.
class MacDeviceFingerprintService implements DeviceFingerprintService {
  /// Creates a [MacDeviceFingerprintService].
  MacDeviceFingerprintService();

  String? _cachedDeviceId;

  @override
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final hardwareUuid = await _getHardwareUuid();
      final serialNumber = await _getSerialNumber();

      final combined = '$hardwareUuid$serialNumber';
      final hash = crypto.sha256.convert(utf8.encode(combined));

      _cachedDeviceId = hash.toString();
      return _cachedDeviceId!;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException(e.toString());
    }
  }

  Future<String> _getHardwareUuid() async {
    try {
      final result = await Process.run('iorext', ['-l']);
      if (result.exitCode != 0) {
        // Fallback to system_profiler
        final result2 = await Process.run('system_profiler', [
          'SPHardwareDataType',
        ]);
        final output = result2.stdout as String;
        final match = RegExp(r'Hardware UUID:\s*(.+)').firstMatch(output);
        if (match == null) {
          throw DeviceFingerprintException('Hardware UUID not found');
        }
        return match.group(1)!.trim();
      }
      final output = result.stdout as String;
      final match = RegExp(r'"IOPlatformUUID"\s*=\s*"([^"]+)"').firstMatch(output);
      if (match == null) {
        throw DeviceFingerprintException('IOPlatformUUID not found');
      }
      return match.group(1)!.trim();
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to get hardware UUID: $e');
    }
  }

  Future<String> _getSerialNumber() async {
    try {
      final result = await Process.run('system_profiler', [
        'SPHardwareDataType',
      ]);
      if (result.exitCode != 0) {
        throw DeviceFingerprintException('Failed to query system_profiler');
      }
      final output = result.stdout as String;
      final match = RegExp(r'Serial Number.*:\s*(.+)').firstMatch(output);
      if (match == null) {
        throw DeviceFingerprintException('Serial number not found');
      }
      return match.group(1)!.trim();
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to get serial number: $e');
    }
  }
}

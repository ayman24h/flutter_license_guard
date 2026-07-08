import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../exceptions/device_fingerprint_exception.dart';
import 'device_fingerprint_service.dart';

/// Linux implementation of [DeviceFingerprintService].
///
/// Collects the following hardware identifiers:
/// - /etc/machine-id (or /var/lib/dbus/machine-id)
/// - DMI board serial (from /sys/class/dmi/id/board_serial)
/// - CPU model hash (from /proc/cpuinfo)
///
/// These values are combined and hashed with SHA-256 to produce
/// a stable device fingerprint.
class LinuxDeviceFingerprintService implements DeviceFingerprintService {
  /// Creates a [LinuxDeviceFingerprintService].
  LinuxDeviceFingerprintService();

  String? _cachedDeviceId;

  @override
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final machineId = await _getMachineId();
      final boardSerial = await _getBoardSerial();
      final cpuId = await _getCpuId();

      final combined = '$machineId$boardSerial$cpuId';
      final hash = crypto.sha256.convert(utf8.encode(combined));

      _cachedDeviceId = hash.toString();
      return _cachedDeviceId!;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException(e.toString());
    }
  }

  Future<String> _getMachineId() async {
    try {
      final file = File('/etc/machine-id');
      if (await file.exists()) {
        return (await file.readAsString()).trim();
      }
      final file2 = File('/var/lib/dbus/machine-id');
      if (await file2.exists()) {
        return (await file2.readAsString()).trim();
      }
      throw DeviceFingerprintException('machine-id not found');
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to read machine-id: $e');
    }
  }

  Future<String> _getBoardSerial() async {
    try {
      final file = File('/sys/class/dmi/id/board_serial');
      if (await file.exists()) {
        return (await file.readAsString()).trim();
      }
      // Fallback: return empty string if DMI not available
      return 'no-board-serial';
    } catch (e) {
      return 'no-board-serial';
    }
  }

  Future<String> _getCpuId() async {
    try {
      final file = File('/proc/cpuinfo');
      if (!await file.exists()) {
        return 'no-cpu-id';
      }
      final content = await file.readAsString();
      final match = RegExp(r'model name\s*:\s*(.+)').firstMatch(content);
      if (match == null) return 'no-cpu-id';
      final model = match.group(1)!.trim();
      final hash = crypto.sha256.convert(utf8.encode(model));
      return hash.toString().substring(0, 16);
    } catch (e) {
      return 'no-cpu-id';
    }
  }
}

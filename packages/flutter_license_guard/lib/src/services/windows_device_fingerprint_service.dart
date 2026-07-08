import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../exceptions/device_fingerprint_exception.dart';
import 'device_fingerprint_service.dart';

/// Windows implementation of [DeviceFingerprintService].
///
/// Collects the following hardware identifiers:
/// - Windows Machine GUID (from registry)
/// - BIOS UUID (from WMI)
/// - Motherboard UUID (from WMI)
/// - CPU identifier (from WMI)
///
/// These values are combined and hashed with SHA-256 to produce
/// a stable device fingerprint.
class WindowsDeviceFingerprintService implements DeviceFingerprintService {
  /// Creates a [WindowsDeviceFingerprintService].
  WindowsDeviceFingerprintService();

  /// Cache of the computed device ID.
  String? _cachedDeviceId;

  @override
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final machineGuid = await _getMachineGuid();
      final biosUuid = await _getBiosUuid();
      final motherboardUuid = await _getMotherboardUuid();
      final cpuId = await _getCpuId();

      final combined = '$machineGuid$biosUuid$motherboardUuid$cpuId';
      final hash = crypto.sha256.convert(utf8.encode(combined));

      _cachedDeviceId = hash.toString();
      return _cachedDeviceId!;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException(e.toString());
    }
  }

  /// Reads the Machine GUID from the Windows registry.
  Future<String> _getMachineGuid() async {
    try {
      final result = await Process.run('reg', [
        'query',
        'HKLM\\SOFTWARE\\Microsoft\\Cryptography',
        '/v',
        'MachineGuid',
      ]);
      if (result.exitCode != 0) {
        throw DeviceFingerprintException(
          'Failed to read MachineGuid from registry',
        );
      }
      final output = result.stdout as String;
      final match = RegExp(r'MachineGuid\s+REG_SZ\s+([^\s]+)').firstMatch(output);
      if (match == null) {
        throw DeviceFingerprintException(
          'MachineGuid not found in registry output',
        );
      }
      return match.group(1)!.trim();
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to read MachineGuid: $e');
    }
  }

  /// Queries the BIOS UUID via WMI.
  Future<String> _getBiosUuid() async {
    try {
      final result = await Process.run('wmic', [
        'csproduct',
        'get',
        'UUID',
      ]);
      if (result.exitCode != 0) {
        throw DeviceFingerprintException('Failed to query BIOS UUID via WMI');
      }
      final output = (result.stdout as String).trim();
      final lines = output.split('\n');
      if (lines.length < 2) {
        throw DeviceFingerprintException('BIOS UUID not found in WMI output');
      }
      final uuid = lines.last.trim();
      if (uuid.isEmpty || uuid == 'UUID') {
        throw DeviceFingerprintException('BIOS UUID is empty');
      }
      return uuid;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to query BIOS UUID: $e');
    }
  }

  /// Queries the motherboard serial number via WMI.
  Future<String> _getMotherboardUuid() async {
    try {
      final result = await Process.run('wmic', [
        'baseboard',
        'get',
        'SerialNumber',
      ]);
      if (result.exitCode != 0) {
        throw DeviceFingerprintException(
          'Failed to query motherboard serial via WMI',
        );
      }
      final output = (result.stdout as String).trim();
      final lines = output.split('\n');
      if (lines.length < 2) {
        throw DeviceFingerprintException(
          'Motherboard serial not found in WMI output',
        );
      }
      final serial = lines.last.trim();
      if (serial.isEmpty || serial == 'SerialNumber') {
        throw DeviceFingerprintException('Motherboard serial is empty');
      }
      return serial;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to query motherboard serial: $e');
    }
  }

  /// Queries the CPU processor ID via WMI.
  Future<String> _getCpuId() async {
    try {
      final result = await Process.run('wmic', [
        'cpu',
        'get',
        'ProcessorId',
      ]);
      if (result.exitCode != 0) {
        throw DeviceFingerprintException(
          'Failed to query CPU ProcessorId via WMI',
        );
      }
      final output = (result.stdout as String).trim();
      final lines = output.split('\n');
      if (lines.length < 2) {
        throw DeviceFingerprintException(
          'CPU ProcessorId not found in WMI output',
        );
      }
      final cpuId = lines.last.trim();
      if (cpuId.isEmpty || cpuId == 'ProcessorId') {
        throw DeviceFingerprintException('CPU ProcessorId is empty');
      }
      return cpuId;
    } catch (e) {
      if (e is DeviceFingerprintException) rethrow;
      throw DeviceFingerprintException('Failed to query CPU ProcessorId: $e');
    }
  }
}

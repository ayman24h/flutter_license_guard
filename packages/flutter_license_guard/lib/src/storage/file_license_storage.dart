import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../exceptions/license_storage_exception.dart';
import 'license_storage.dart';

/// File-based implementation of [LicenseStorage].
///
/// Stores the license file in the platform-appropriate application
/// data directory:
/// - **Windows**: `%APPDATA%/<appName>/`
/// - **macOS**: `~/Library/Application Support/<appName>/`
/// - **Linux**: `$XDG_DATA_HOME/<appName>/` (or `~/.local/share/<appName>/`)
class FileLicenseStorage implements LicenseStorage {
  /// Creates a [FileLicenseStorage] with the given [appName] and
  /// [licenseFileName].
  FileLicenseStorage({
    required this.appName,
    required this.licenseFileName,
  });

  /// The application name used for the storage directory.
  final String appName;

  /// The license file name (e.g. "license.dat").
  final String licenseFileName;

  String? _cachedPath;

  @override
  Future<void> save(Uint8List bytes) async {
    try {
      final path = await licenseFilePath;
      final file = File(path);
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw LicenseStorageException('Failed to save license file: $e');
    }
  }

  @override
  Future<Uint8List?> read() async {
    try {
      final path = await licenseFilePath;
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return Uint8List.fromList(bytes);
    } catch (e) {
      throw LicenseStorageException('Failed to read license file: $e');
    }
  }

  @override
  Future<bool> delete() async {
    try {
      final path = await licenseFilePath;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw LicenseStorageException('Failed to delete license file: $e');
    }
  }

  @override
  Future<bool> exists() async {
    final path = await licenseFilePath;
    return File(path).exists();
  }

  @override
  Future<String> get licenseFilePath async {
    if (_cachedPath != null) return _cachedPath!;
    final dir = await _getStorageDirectory();
    final path = '${dir.path}${Platform.pathSeparator}$licenseFileName';
    _cachedPath = path;
    return path;
  }

  Future<Directory> _getStorageDirectory() async {
    if (Platform.isWindows) {
      final appData = await getApplicationSupportDirectory();
      return Directory('${appData.path}${Platform.pathSeparator}$appName');
    } else if (Platform.isMacOS) {
      final appData = await getApplicationSupportDirectory();
      return Directory('${appData.path}${Platform.pathSeparator}$appName');
    } else if (Platform.isLinux) {
      final appData = await getApplicationSupportDirectory();
      return Directory('${appData.path}${Platform.pathSeparator}$appName');
    } else {
      final appData = await getApplicationSupportDirectory();
      return Directory('${appData.path}${Platform.pathSeparator}$appName');
    }
  }
}

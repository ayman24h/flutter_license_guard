import 'dart:typed_data';

/// Abstract interface for local license file storage.
///
/// Implementations must handle platform-specific directory resolution
/// (e.g. AppData on Windows, Application Support on macOS, etc.).
abstract class LicenseStorage {
  /// Saves the given [bytes] as the license file.
  ///
  /// Throws [LicenseStorageException] on I/O failure.
  Future<void> save(Uint8List bytes);

  /// Reads the license file and returns its bytes.
  ///
  /// Returns `null` if no license file exists.
  /// Throws [LicenseStorageException] on read failure.
  Future<Uint8List?> read();

  /// Deletes the license file if it exists.
  ///
  /// Returns `true` if a file was deleted, `false` if no file existed.
  /// Throws [LicenseStorageException] on deletion failure.
  Future<bool> delete();

  /// Returns whether a license file exists.
  Future<bool> exists();

  /// Returns the absolute path where the license file is stored.
  Future<String> get licenseFilePath;
}

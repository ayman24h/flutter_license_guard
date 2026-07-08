import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../crypto/aes_gcm_encryption_service.dart';
import '../crypto/ed25519_signature_service.dart';
import '../crypto/signature_service.dart';
import '../enums/license_error_code.dart';
import '../enums/license_feature.dart';
import '../enums/license_status.dart';
import '../exceptions/license_not_initialized_exception.dart';
import '../models/license_entity.dart';
import '../models/license_validation_result.dart';
import '../services/activation_service.dart';
import '../services/device_fingerprint_service.dart';
import '../services/linux_device_fingerprint_service.dart';
import '../services/mac_device_fingerprint_service.dart';
import '../services/stub_device_fingerprint_service.dart';
import '../services/windows_device_fingerprint_service.dart';
import '../storage/file_license_storage.dart';
import '../storage/license_storage.dart';
import '../validators/license_validator.dart';
import 'license_config.dart';

/// The main facade for the flutter_license_guard SDK.
///
/// This is the primary entry point for all licensing operations.
/// Call [initialize] once at application startup, then use the
/// static methods to check activation status, validate licenses,
/// and check feature permissions.
class LicenseGuard {
  LicenseGuard._();

  static LicenseGuard? _instance;

  static LicenseConfig? _config;
  static DeviceFingerprintService? _deviceFingerprintService;
  static LicenseStorage? _storage;
  static SignatureService? _signatureService;
  static LicenseValidator? _validator;
  static ActivationService? _activationService;
  static LicenseValidationResult? _cachedResult;
  static String? _cachedDeviceId;

  /// Initializes the SDK with the given [config].
  ///
  /// This must be called before any other [LicenseGuard] method.
  static Future<void> initialize({
    required LicenseConfig config,
    bool silent = false,
  }) async {
    _config = config;
    _cachedResult = null;
    _cachedDeviceId = null;

    _deviceFingerprintService = _createDeviceFingerprintService(
      silent: silent,
    );

    _storage = FileLicenseStorage(
      appName: config.appName,
      licenseFileName: config.licensePath,
    );

    _signatureService = Ed25519SignatureService();

    _validator = LicenseValidator(
      storage: _storage!,
      deviceFingerprintService: _deviceFingerprintService!,
      signatureService: _signatureService!,
      publicKey: config.publicKey,
      encryptionKey: config.encryptionKey,
      allowOfflineGrace: config.allowOfflineGrace,
      gracePeriodDays: config.gracePeriodDays,
    );

    _activationService = ActivationService(
      storage: _storage!,
      deviceFingerprintService: _deviceFingerprintService!,
      signatureService: _signatureService!,
      publicKey: config.publicKey,
      encryptionKey: config.encryptionKey,
    );

    _instance = LicenseGuard._();
  }

  /// Returns whether the SDK has been initialized.
  static bool get isInitialized => _instance != null;

  static void _ensureInitialized() {
    if (_instance == null) {
      throw const LicenseNotInitializedException();
    }
  }

  static LicenseConfig get config {
    _ensureInitialized();
    return _config!;
  }

  static DeviceFingerprintService get deviceFingerprintService {
    _ensureInitialized();
    return _deviceFingerprintService!;
  }

  static LicenseStorage get storage {
    _ensureInitialized();
    return _storage!;
  }

  static LicenseValidator get validator {
    _ensureInitialized();
    return _validator!;
  }

  static ActivationService get activationService {
    _ensureInitialized();
    return _activationService!;
  }

  /// Returns the device ID for this machine.
  static Future<String> getDeviceId() async {
    _ensureInitialized();
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    _cachedDeviceId = await _deviceFingerprintService!.getDeviceId();
    return _cachedDeviceId!;
  }

  /// Returns whether a valid license is currently activated.
  static Future<bool> get isActivated async {
    _ensureInitialized();
    final result = await validate();
    return result.success;
  }

  /// Validates the current license and returns the result.
  static Future<LicenseValidationResult> validate() async {
    _ensureInitialized();
    if (_cachedResult != null) return _cachedResult!;
    _cachedResult = await _validator!.validate();
    return _cachedResult!;
  }

  /// Clears the cached validation result and re-validates.
  static Future<LicenseValidationResult> refresh() async {
    _ensureInitialized();
    _cachedResult = null;
    return validate();
  }

  /// Returns the current license entity if valid.
  static Future<LicenseEntity?> get currentLicense async {
    _ensureInitialized();
    final result = await validate();
    return result.license;
  }

  /// Checks whether the current license includes a specific feature.
  static Future<bool> hasFeature(LicenseFeature feature) async {
    _ensureInitialized();
    final result = await validate();
    if (!result.success || result.license == null) return false;
    return result.license!.hasFeature(feature.value);
  }

  /// Activates a license from a Base64-encoded string.
  static Future<LicenseValidationResult> activate(
    String licenseData,
  ) async {
    _ensureInitialized();
    final result = await _activationService!.activateFromBase64(
      licenseData,
    );
    if (result.success) {
      _cachedResult = null;
    }
    return result;
  }

  /// Deactivates the current license by deleting the local file.
  static Future<bool> deactivate() async {
    _ensureInitialized();
    final deleted = await _activationService!.deactivate();
    if (deleted) {
      _cachedResult = null;
    }
    return deleted;
  }

  /// Returns the path where the license file is stored.
  static Future<String> get licenseFilePath async {
    _ensureInitialized();
    return _storage!.licenseFilePath;
  }

  /// Disposes of all resources and resets the singleton.
  static void dispose() {
    _instance = null;
    _config = null;
    _deviceFingerprintService = null;
    _storage = null;
    _signatureService = null;
    _validator = null;
    _activationService = null;
    _cachedResult = null;
    _cachedDeviceId = null;
  }

  static DeviceFingerprintService _createDeviceFingerprintService({
    bool silent = false,
  }) {
    if (Platform.isWindows) {
      return WindowsDeviceFingerprintService();
    } else if (Platform.isMacOS) {
      return MacDeviceFingerprintService();
    } else if (Platform.isLinux) {
      return LinuxDeviceFingerprintService();
    } else {
      if (silent) {
        return StubDeviceFingerprintService(seed: 'fallback-device-id');
      }
      throw UnsupportedError(
        'flutter_license_guard does not support this platform. '
        'Supported platforms: Windows, macOS, Linux.',
      );
    }
  }
}

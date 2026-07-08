/// flutter_license_guard — A reusable offline licensing SDK for
/// Flutter Desktop applications.
///
/// This is the public API. Import this file to use the SDK:
///
/// ```dart
/// import 'package:flutter_license_guard/flutter_license_guard.dart';
/// ```
library flutter_license_guard;

// Core
export 'src/core/license_config.dart';
export 'src/core/license_guard.dart';

// Enums
export 'src/enums/license_type.dart';
export 'src/enums/license_feature.dart';
export 'src/enums/license_status.dart';
export 'src/enums/license_error_code.dart';

// Models
export 'src/models/license_entity.dart';
export 'src/models/license_validation_result.dart';
export 'src/models/license_file_payload.dart';

// Services
export 'src/services/device_fingerprint_service.dart';
export 'src/services/windows_device_fingerprint_service.dart';
export 'src/services/mac_device_fingerprint_service.dart';
export 'src/services/linux_device_fingerprint_service.dart';
export 'src/services/stub_device_fingerprint_service.dart';
export 'src/services/activation_service.dart';

// Crypto
export 'src/crypto/signature_service.dart';
export 'src/crypto/ed25519_signature_service.dart';
export 'src/crypto/aes_gcm_encryption_service.dart';

// Storage
export 'src/storage/license_storage.dart';
export 'src/storage/file_license_storage.dart';

// Validators
export 'src/validators/license_validator.dart';

// Exceptions
export 'src/exceptions/license_exception.dart';
export 'src/exceptions/license_not_found_exception.dart';
export 'src/exceptions/license_corrupted_exception.dart';
export 'src/exceptions/license_signature_invalid_exception.dart';
export 'src/exceptions/license_device_mismatch_exception.dart';
export 'src/exceptions/license_expired_exception.dart';
export 'src/exceptions/license_feature_not_licensed_exception.dart';
export 'src/exceptions/device_fingerprint_exception.dart';
export 'src/exceptions/license_storage_exception.dart';
export 'src/exceptions/license_not_initialized_exception.dart';
export 'src/exceptions/activation_exception.dart';

// Utils
export 'src/utils/hash_utils.dart';
export 'src/utils/base64_utils.dart';
export 'src/utils/date_utils.dart';

// Admin models (for future online dashboard)
export 'src/models/license_record.dart';

// UI (optional activation widgets)
export 'src/ui/license_activation_page.dart';

# flutter_license_guard

A reusable, production-ready offline licensing SDK for Flutter Desktop applications (Windows first, with macOS/Linux support planned).

## Features

- 🔐 **Digital Signatures** — Ed25519 signature verification ensures licenses cannot be forged
- 💻 **Device Binding** — Licenses are locked to a specific device via hardware fingerprinting
- 🔒 **Encrypted Storage** — AES-256-GCM encrypted license files with tamper detection
- 📋 **Feature Management** — Granular per-license feature flags
- ⏰ **Expiration** — Trial, monthly, yearly, lifetime, and enterprise license types
- 🛡️ **Tamper Detection** — SHA-256 checksums detect any file modification
- 📴 **Offline Validation** — No internet connection required
- 🖥️ **Activation UI** — Customizable Flutter activation page widget
- 🔧 **CLI Generator** — Command-line tool for generating signed license files

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter Application                    │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ LicenseGuard │  │  Activation  │  │   Validator    │  │
│  │   (Facade)   │  │   Service    │  │                │  │
│  └──────┬───────┘  └──────┬───────┘  └───────┬────────┘  │
│         │                 │                  │           │
│  ┌──────┴─────────────────┴──────────────────┴────────┐  │
│  │                    Core Layer                       │  │
│  └──────┬─────────────────┬──────────────────┬────────┘  │
│         │                 │                  │           │
│  ┌──────┴──────┐  ┌───────┴───────┐  ┌───────┴────────┐  │
│  │   Crypto    │  │   Storage     │  │   Services     │  │
│  │  Ed25519    │  │  File-based   │  │  Fingerprint   │  │
│  │  AES-256    │  │  Encrypted    │  │  Activation    │  │
│  └─────────────┘  └───────────────┘  └────────────────┘  │
│                                                          │
│  PUBLIC KEY ONLY — No private key in the app             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              License Generator (CLI Tool)                │
│                                                          │
│  PRIVATE KEY → Signs license data → license.dat          │
│                                                          │
│  Kept secure on your server/admin machine                │
└─────────────────────────────────────────────────────────┘
```

### Cryptographic Flow

```
License Data (JSON)
       │
       ▼
  Canonical JSON Encoding (sorted keys)
       │
       ▼
  Ed25519 Sign (with PRIVATE KEY)
       │
       ▼
  AES-256-GCM Encrypt
       │
       ▼
  Pack: [Header][Encrypted Payload][Signature][Checksum]
       │
       ▼
  license.dat
       │
       ▼
  Flutter App reads license.dat
       │
       ▼
  Verify Checksum → Decrypt → Verify Signature (with PUBLIC KEY)
       │
       ▼
  Check Device ID → Check Expiry → Check Features
       │
       ▼
  License Valid ✓
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_license_guard:
    git:
      url: https://github.com/your-org/flutter_license_guard.git
      path: packages/flutter_license_guard
```

## Configuration

### 1. Generate Key Pair

Use the CLI tool to generate an Ed25519 key pair:

```bash
dart run license_generator generate-keys
```

This produces:
- `private_key.txt` — **KEEP SECRET** — used by the license generator
- `public_key.txt` — **EMBED IN APP** — used by the Flutter app for verification

### 2. Initialize the SDK

In your `main.dart`:

```dart
import 'package:flutter_license_guard/flutter_license_guard.dart';

const publicKey = 'YOUR_BASE64_PUBLIC_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LicenseGuard.initialize(
    config: LicenseConfig(
      licensePath: 'license.dat',
      publicKey: publicKey,
      appName: 'MyApp',
    ),
  );

  final isActivated = await LicenseGuard.isActivated;

  if (isActivated) {
    runApp(MyApp());
  } else {
    runApp(const ActivationApp());
  }
}
```

### 3. Build the Activation Page

Use the built-in widget or build your own:

```dart
import 'package:flutter_license_guard/flutter_license_guard.dart';

class ActivationApp extends StatelessWidget {
  const ActivationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LicenseActivationPage(
        title: 'Activate MyApp',
        subtitle: 'Enter your license key to continue',
        onSuccess: () {
          // Restart the app or navigate to main
          runApp(MyApp());
        },
        theme: LicenseActivationTheme(
          // Customize colors, styles, logo
        ),
      ),
    );
  }
}
```

## Creating Licenses

Use the CLI tool to generate license files:

```bash
# Generate a lifetime license with sales and inventory features
dart run license_generator create-license \
  --customer "John Doe" \
  --company "ACME Corp" \
  --device-id "DEVICE_FINGERPRINT_FROM_APP" \
  --type lifetime \
  --features sales,inventory,reports \
  --private-key "BASE64_PRIVATE_KEY" \
  --output license.dat
```

### License Types

| Type       | Expiry          | Use Case                        |
|------------|-----------------|---------------------------------|
| `trial`    | 30 days         | Free evaluation                 |
| `monthly`  | 30 days         | Monthly subscription            |
| `yearly`   | 365 days        | Annual subscription             |
| `lifetime` | Never           | One-time purchase               |
| `enterprise`| Never          | Enterprise with all features    |

### Available Features

`crm`, `sales`, `inventory`, `reports`, `accounting`, `printing`, `backup`, `multi_branch`

## Usage

### Check if activated

```dart
if (await LicenseGuard.isActivated) {
  // License is valid
}
```

### Check features

```dart
if (await LicenseGuard.hasFeature(LicenseFeature.inventory)) {
  // Show inventory module
}
```

### Get current license

```dart
final license = await LicenseGuard.currentLicense;
print(license?.customerName);
print(license?.licenseType);
print(license?.features);
```

### Activate a license

```dart
final result = await LicenseGuard.activate(licenseKey);
if (result.success) {
  // Activation successful
} else {
  print(result.message);
}
```

### Deactivate

```dart
await LicenseGuard.deactivate();
```

### Validate manually

```dart
final result = await LicenseGuard.validate();
if (!result.success) {
  print('Error: ${result.errorCode.code}');
  print(result.message);
}
```

## Security Architecture

### Key Separation

- **Private Key**: Used only by the license generator tool on your secure server/admin machine. **Never** embedded in the Flutter app.
- **Public Key**: Embedded in the Flutter app. Used only for verification — cannot forge licenses.

### License File Format

The `license.dat` file is a binary format:

```
[4 bytes:  Magic header "FLGV"]
[1 byte:   Format version]
[4 bytes:  Encrypted payload length]
[N bytes:  AES-256-GCM encrypted license JSON]
[4 bytes:  Signature length]
[M bytes:  Ed25519 signature of canonical JSON]
[32 bytes: SHA-256 checksum (tamper detection)]
```

The file is **not** readable as plain JSON. Any modification to any byte
is detected by the checksum and the GCM authentication tag.

### Multiple Validation Points

1. **File checksum** — SHA-256 detects any byte-level tampering
2. **AES-GCM authentication tag** — Detects ciphertext modification
3. **Ed25519 signature** — Cryptographic proof of authenticity
4. **Device fingerprint** — Prevents license sharing between devices
5. **Expiry check** — Prevents use of expired licenses

### Device Fingerprinting

On Windows, the device ID is a SHA-256 hash of:

- Windows Machine GUID (registry)
- BIOS UUID (WMI)
- Motherboard serial number (WMI)
- CPU Processor ID (WMI)

This produces a stable identifier that survives reboots and app reinstalls
but changes if the hardware is significantly modified.

### Obfuscation Friendly

- No hardcoded secrets in the app
- Public key is safe to embed (cannot forge licenses)
- All crypto uses standard, audited libraries (PointyCastle)
- Code is structured for ProGuard/R8 obfuscation

## Clean Architecture

The SDK follows Clean Architecture and SOLID principles:

```
lib/src/
├── core/           # LicenseGuard facade, config
├── models/         # Domain entities (License, ValidationResult)
├── enums/          # LicenseType, LicenseFeature, status codes
├── services/       # Device fingerprint, activation
├── crypto/         # Signature, encryption (abstract + impl)
├── storage/        # License file storage (abstract + impl)
├── validators/     # License validator
├── exceptions/     # Domain-specific exceptions
├── utils/          # Hash, Base64, date utilities
└── ui/             # Optional activation page widget
```

### Dependency Injection

All dependencies are injected via constructors:

```dart
// You can replace any implementation for testing
final validator = LicenseValidator(
  storage: myMockStorage,
  deviceFingerprintService: myMockFingerprintService,
  signatureService: myMockSignatureService,
  publicKey: publicKey,
);
```

## Testing

Run the test suite:

```bash
cd packages/flutter_license_guard
flutter test
```

Tests cover:
- Device fingerprint generation
- Ed25519 signature sign/verify
- AES-256-GCM encrypt/decrypt
- License file payload serialization
- License entity serialization
- License validation results
- Full integration cycle (sign → encrypt → pack → unpack → verify)

## License

MIT — See [LICENSE](LICENSE) for details.

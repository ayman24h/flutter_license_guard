# flutter_license_guard

A reusable, production-ready offline licensing SDK for Flutter Desktop applications.

## Monorepo Structure

```
flutter_license_guard/
├── packages/
│   ├── flutter_license_guard/    # The SDK (Flutter package)
│   └── license_generator/         # CLI tool for generating licenses
├── example/                       # Example Flutter Desktop app
└── README.md                      # This file
```

## Quick Start

### 1. Generate Keys

```bash
cd packages/license_generator
dart pub get
dart run license_generator generate-keys
```

Save the private key securely. Embed the public key in your app.

### 2. Add to Your App

```yaml
# pubspec.yaml
dependencies:
  flutter_license_guard:
    path: path/to/flutter_license_guard/packages/flutter_license_guard
```

### 3. Initialize

```dart
import 'package:flutter_license_guard/flutter_license_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LicenseGuard.initialize(
    config: LicenseConfig(
      licensePath: 'license.dat',
      publicKey: 'YOUR_PUBLIC_KEY',
      appName: 'MyApp',
    ),
  );

  if (await LicenseGuard.isActivated) {
    runApp(MyApp());
  } else {
    runApp(ActivationApp());
  }
}
```

### 4. Generate a License

```bash
dart run license_generator create-license \
  --customer "John Doe" \
  --device-id "DEVICE_ID_FROM_APP" \
  --type lifetime \
  --features sales,inventory,reports \
  --private-key "YOUR_PRIVATE_KEY" \
  --output license.dat
```

## Documentation

- [SDK README](packages/flutter_license_guard/README.md) — Full API docs, architecture, security
- [Generator README](packages/license_generator/README.md) — CLI tool usage
- [Example App](example/) — Complete working example

## Packages

### flutter_license_guard

The core SDK providing:
- Device fingerprinting (Windows, macOS, Linux)
- Ed25519 digital signature verification
- AES-256-GCM encrypted license storage
- License validation (signature, device, expiry, features, tamper)
- Activation workflow
- Customizable activation UI widget

### license_generator

A CLI tool for generating signed license files:
- `generate-keys` — Create Ed25519 key pairs
- `create-license` — Generate signed, encrypted license files

## Security Model

| Component          | Location             | Purpose                    |
|--------------------|----------------------|----------------------------|
| Private Key        | Your secure server   | Signs license data         |
| Public Key         | Embedded in app      | Verifies license signatures |
| License File       | Delivered to customer| Contains encrypted license |
| Device Fingerprint | Generated on device  | Binds license to hardware  |

The app **never** contains the private key. Licenses cannot be forged
without it, even if the app is reverse-engineered.

## License

MIT

# license_generator

CLI tool for generating digitally signed license files for `flutter_license_guard`.

## Installation

```bash
cd packages/license_generator
dart pub get
```

## Commands

### `generate-keys`

Generates a new Ed25519 key pair.

```bash
dart run license_generator generate-keys
```

Output:
```
Private Key (KEEP SECRET — use with license_generator):
<base64_encoded_private_key>

Public Key (EMBED IN FLUTTER APP):
<base64_encoded_public_key>
```

Keys are saved to `private_key.txt` and `public_key.txt`.

### `create-license`

Generates a signed, encrypted license file.

```bash
dart run license_generator create-license \
  --customer "John Doe" \
  --company "ACME Corp" \
  --device-id "abc123def456..." \
  --type lifetime \
  --features sales,inventory,reports \
  --expiry 2026-12-31 \
  --private-key "BASE64_PRIVATE_KEY" \
  --output license.dat
```

#### Required Arguments

| Argument         | Flag            | Description                                    |
|------------------|-----------------|------------------------------------------------|
| Customer name    | `--customer`    | Name of the license holder                     |
| Device ID        | `--device-id`   | Device fingerprint from the activation screen  |
| License type     | `--type`        | `trial`, `monthly`, `yearly`, `lifetime`, `enterprise` |
| Private key      | `--private-key` | Base64-encoded Ed25519 private key             |

#### Optional Arguments

| Argument         | Flag              | Description                                    |
|------------------|-------------------|------------------------------------------------|
| Company name     | `--company`       | Company name                                   |
| Expiry date      | `--expiry`        | YYYY-MM-DD (auto-calculated if omitted)        |
| Features         | `--features`      | Comma-separated feature list                   |
| Output path      | `--output`        | Output file path (default: `license.dat`)      |
| Encryption key   | `--encryption-key`| Base64-encoded AES-256 key                     |
| License ID       | `--id`            | Custom license ID (auto-generated if omitted)  |

#### Available Features

- `crm` — Customer Relationship Management
- `sales` — Sales module
- `inventory` — Inventory management
- `reports` — Reporting module
- `accounting` — Accounting module
- `printing` — Printing support
- `backup` — Backup functionality
- `multi_branch` — Multi-branch support

## Workflow

1. **Generate keys** (once):
   ```bash
   dart run license_generator generate-keys
   ```

2. **Embed public key** in your Flutter app:
   ```dart
   const publicKey = 'YOUR_PUBLIC_KEY_HERE';
   ```

3. **Get device ID** from the user's activation screen

4. **Generate license**:
   ```bash
   dart run license_generator create-license \
     --customer "Customer Name" \
     --device-id "DEVICE_ID_FROM_APP" \
     --type yearly \
     --features sales,inventory \
     --private-key "YOUR_PRIVATE_KEY" \
     --output license.dat
   ```

5. **Deliver license** to the customer (email, download link, etc.)

6. **Customer activates** by pasting the Base64-encoded license data
   into the activation screen, or by placing `license.dat` in the
   app's data directory.

## Security Notes

- **Never** share or commit the private key
- Store the private key in a secure vault (e.g. AWS Secrets Manager, HashiCorp Vault)
- The public key is safe to embed in the app — it can only verify, not forge
- Each license is bound to a specific device ID
- License files are encrypted and checksummed — any tampering is detected

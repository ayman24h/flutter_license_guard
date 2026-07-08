import 'dart:io';

import 'package:args/args.dart';
import 'package:license_generator/license_generator.dart';

/// CLI entry point for the license_generator tool.
Future<void> main(List<String> arguments) async {
  // Set up file writer for the generator library
  LicenseGenerator.fileWriter = (String path, List<int> bytes) {
    final file = File(path);
    file.writeAsBytesSync(bytes);
  };

  if (arguments.isEmpty) {
    _printHelp();
    exit(1);
  }

  final command = arguments[0];
  final args = arguments.sublist(1);

  try {
    switch (command) {
      case 'create-license':
        await _createLicense(args);
      case 'generate-keys':
        await _generateKeys(args);
      case '--help':
      case '-h':
      case 'help':
        _printHelp();
        exit(0);
      default:
        stderr.writeln('Unknown command: $command');
        _printHelp();
        exit(1);
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<void> _createLicense(List<String> args) async {
  final parser = ArgParser()
    ..addOption('customer', abbr: 'c', help: 'Customer name (required)')
    ..addOption('company', help: 'Company name (optional)')
    ..addOption(
      'device-id',
      abbr: 'd',
      help: 'Device ID / fingerprint (required)',
    )
    ..addOption(
      'type',
      abbr: 't',
      help: 'License type: trial, monthly, yearly, lifetime, '
          'enterprise (required)',
    )
    ..addOption(
      'expiry',
      abbr: 'e',
      help: 'Expiry date (YYYY-MM-DD). Auto-calculated if omitted.',
    )
    ..addOption(
      'features',
      abbr: 'f',
      help: 'Comma-separated features: crm,sales,inventory,reports,'
          'accounting,printing,backup,multi_branch',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path (default: license.dat)',
      defaultsTo: 'license.dat',
    )
    ..addOption(
      'private-key',
      abbr: 'k',
      help: 'Base64-encoded Ed25519 private key (required)',
    )
    ..addOption(
      'encryption-key',
      help: 'Base64-encoded AES-256 encryption key (optional)',
    )
    ..addOption(
      'id',
      help: 'Custom license ID (auto-generated if omitted)',
    )
    ..addFlag('help', abbr: 'h', help: 'Show help for create-license');

  ArgResults result;
  try {
    result = parser.parse(args);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    stderr.writeln('');
    stderr.writeln('Usage: license_generator create-license [options]');
    stderr.writeln('');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (result['help'] as bool) {
    stdout.writeln('Create a signed license file\n');
    stdout.writeln('Usage: license_generator create-license [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final customer = result['customer'] as String?;
  final deviceId = result['device-id'] as String?;
  final typeStr = result['type'] as String?;
  final privateKey = result['private-key'] as String?;

  if (customer == null || customer.isEmpty) {
    stderr.writeln('Error: --customer is required');
    exit(1);
  }
  if (deviceId == null || deviceId.isEmpty) {
    stderr.writeln('Error: --device-id is required');
    exit(1);
  }
  if (typeStr == null || typeStr.isEmpty) {
    stderr.writeln('Error: --type is required');
    exit(1);
  }
  if (privateKey == null || privateKey.isEmpty) {
    stderr.writeln('Error: --private-key is required');
    exit(1);
  }

  final LicenseType type;
  try {
    type = LicenseType.fromString(typeStr);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }

  final featuresStr = result['features'] as String? ?? '';
  final features = <LicenseFeature>[];
  if (featuresStr.isNotEmpty) {
    for (final f in featuresStr.split(',')) {
      try {
        features.add(LicenseFeature.fromString(f.trim()));
      } catch (e) {
        stderr.writeln('Error: $e');
        exit(1);
      }
    }
  }

  DateTime? expiry;
  final expiryStr = result['expiry'] as String?;
  if (expiryStr != null && expiryStr.isNotEmpty) {
    try {
      expiry = DateTime.parse(expiryStr);
    } catch (e) {
      stderr.writeln('Error: Invalid expiry date format. Use YYYY-MM-DD.');
      exit(1);
    }
  }

  final generator = LicenseGenerator(
    privateKeyBase64: privateKey,
    encryptionKey: result['encryption-key'] as String?,
  );

  final outputPath = result['output'] as String;
  final licenseId = result['id'] as String?;
  final company = result['company'] as String?;

  try {
    await generator.generateToFile(
      outputPath: outputPath,
      id: licenseId,
      customerName: customer,
      companyName: company,
      deviceId: deviceId,
      licenseType: type,
      expiryDate: expiry,
      features: features,
    );

    final publicKey = await generator.getPublicKey();

    stdout.writeln('✓ License generated successfully!');
    stdout.writeln('  File: $outputPath');
    stdout.writeln('  Customer: $customer');
    stdout.writeln('  Device: $deviceId');
    stdout.writeln('  Type: ${type.value}');
    if (expiry != null) {
      stdout.writeln(
        '  Expiry: ${expiry.toIso8601String().split('T').first}',
      );
    }
    if (features.isNotEmpty) {
      stdout.writeln(
        '  Features: ${features.map((f) => f.value).join(', ')}',
      );
    }
    stdout.writeln('  Public key: $publicKey');
  } catch (e) {
    stderr.writeln('Error generating license: $e');
    exit(1);
  }
}

Future<void> _generateKeys(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory (default: current)',
      defaultsTo: '.',
    )
    ..addFlag('help', abbr: 'h', help: 'Show help for generate-keys');

  ArgResults result;
  try {
    result = parser.parse(args);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }

  if (result['help'] as bool) {
    stdout.writeln('Generate a new Ed25519 key pair\n');
    stdout.writeln('Usage: license_generator generate-keys [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final keyPair = await LicenseCrypto.generateKeyPair();
  final outputDir = result['output'] as String;

  stdout.writeln('=== Ed25519 Key Pair Generated ===\n');
  stdout.writeln('Private Key (KEEP SECRET — use with license_generator):');
  stdout.writeln(keyPair.privateKeyBase64);
  stdout.writeln('\nPublic Key (EMBED IN FLUTTER APP):');
  stdout.writeln(keyPair.publicKeyBase64);
  stdout.writeln(
    '\n⚠  Store the private key securely. Never embed it in your app.',
  );

  final privateKeyFile = File('$outputDir/private_key.txt');
  final publicKeyFile = File('$outputDir/public_key.txt');
  privateKeyFile.writeAsStringSync(keyPair.privateKeyBase64);
  publicKeyFile.writeAsStringSync(keyPair.publicKeyBase64);

  stdout.writeln('\nKeys saved to:');
  stdout.writeln('  $outputDir/private_key.txt');
  stdout.writeln('  $outputDir/public_key.txt');
}

void _printHelp() {
  stdout.writeln('''
license_generator — CLI tool for generating signed license files

Usage:
  license_generator <command> [options]

Commands:
  create-license    Generate a digitally signed license file
  generate-keys     Generate a new Ed25519 key pair

Example:
  license_generator generate-keys
  license_generator create-license \\
    --customer "John Doe" \\
    --company "ACME Corp" \\
    --device-id "abc123def456..." \\
    --type lifetime \\
    --features sales,inventory,reports \\
    --private-key <base64_private_key> \\
    --output license.dat
''');
}

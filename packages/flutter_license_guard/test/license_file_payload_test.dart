import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_license_guard/src/models/license_file_payload.dart';

void main() {
  group('LicenseFilePayload', () {
    test('toBytes and fromBytes round-trip succeeds', () {
      final payload = LicenseFilePayload(
        encryptedPayload: Uint8List.fromList([1, 2, 3, 4, 5]),
        signature: Uint8List.fromList(List.generate(64, (i) => i)),
        checksum: Uint8List(32),
      );

      final bytes = payload.toBytes();
      final restored = LicenseFilePayload.fromBytes(bytes);

      expect(restored.encryptedPayload, payload.encryptedPayload);
      expect(restored.signature, payload.signature);
    });

    test('fromBytes throws on too-short file', () {
      final short = Uint8List.fromList([1, 2, 3]);
      expect(
        () => LicenseFilePayload.fromBytes(short),
        throwsFormatException,
      );
    });

    test('fromBytes throws on invalid magic header', () {
      final bytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00, // wrong magic
        0x01, // version
        0x00, 0x00, 0x00, 0x01, // payload length = 1
        0xFF, // payload
        0x00, 0x00, 0x00, 0x40, // sig length = 64
        ...List.generate(64, (i) => 0), // signature
        ...List.generate(32, (i) => 0), // checksum
      ]);
      expect(
        () => LicenseFilePayload.fromBytes(bytes),
        throwsFormatException,
      );
    });

    test('fromBytes throws on unsupported version', () {
      final builder = BytesBuilder();
      builder.add(Uint8List.fromList(LicenseFilePayload.magicHeader));
      builder.addByte(99); // unsupported version
      builder.add(Uint8List(4)); // payload length
      builder.add(Uint8List(4)); // sig length
      builder.add(Uint8List(32)); // checksum placeholder
      expect(
        () => LicenseFilePayload.fromBytes(builder.toBytes()),
        throwsFormatException,
      );
    });

    test('fromBytes detects tampering via checksum mismatch', () {
      final payload = LicenseFilePayload(
        encryptedPayload: Uint8List.fromList([1, 2, 3, 4, 5]),
        signature: Uint8List.fromList(List.generate(64, (i) => i)),
        checksum: Uint8List(32),
      );

      final bytes = Uint8List.fromList(payload.toBytes());
      // Tamper with a byte in the encrypted payload (after header+version+length)
      bytes[10] ^= 0xFF;

      expect(
        () => LicenseFilePayload.fromBytes(bytes),
        throwsFormatException,
      );
    });

    test('magic header is "FLGV"', () {
      expect(LicenseFilePayload.magicHeader, [0x46, 0x4C, 0x47, 0x56]);
    });

    test('format version is 1', () {
      expect(LicenseFilePayload.formatVersion, 1);
    });
  });
}

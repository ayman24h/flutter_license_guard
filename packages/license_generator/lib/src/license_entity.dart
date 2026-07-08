import 'license_type.dart';
import 'license_feature.dart';

/// License entity for the generator tool.
///
/// Mirrors the entity in the main package but kept independent
/// so the generator has no dependency on Flutter.
class LicenseEntity {
  const LicenseEntity({
    required this.id,
    required this.customerName,
    this.companyName,
    required this.deviceId,
    required this.licenseType,
    required this.issueDate,
    this.expiryDate,
    this.features = const [],
    this.metadata,
  });

  final String id;
  final String customerName;
  final String? companyName;
  final String deviceId;
  final LicenseType licenseType;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final List<String> features;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'customer': customerName,
      if (companyName != null) 'company': companyName,
      'deviceId': deviceId,
      'type': licenseType.value,
      'issueDate': issueDate.toIso8601String(),
      if (expiryDate != null) 'expiry': expiryDate!.toIso8601String(),
      'features': features,
      if (metadata != null) 'metadata': metadata,
    };
    return json;
  }

  /// Returns canonical JSON (sorted keys, no signature field).
  String toSignedDataJson() {
    final json = toJson();
    return _canonicalJsonEncode(json);
  }
}

String _canonicalJsonEncode(Map<String, dynamic> map) {
  final sortedKeys = map.keys.toList()..sort();
  final buffer = StringBuffer('{');
  for (var i = 0; i < sortedKeys.length; i++) {
    if (i > 0) buffer.write(',');
    final key = sortedKeys[i];
    buffer.write('"${_escapeJson(key)}":');
    buffer.write(_encodeValue(map[key]));
  }
  buffer.write('}');
  return buffer.toString();
}

String _encodeValue(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return '"${_escapeJson(value)}"';
  if (value is num) return value.toString();
  if (value is bool) return value.toString();
  if (value is List) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_encodeValue(value[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }
  if (value is Map<String, dynamic>) {
    return _canonicalJsonEncode(value);
  }
  return 'null';
}

String _escapeJson(String input) {
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

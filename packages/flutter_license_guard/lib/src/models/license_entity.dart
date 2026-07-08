import '../enums/license_type.dart';

/// The core license entity representing a digitally signed license.
///
/// This is the domain model that flows through all layers of the SDK.
/// It is immutable and serializable to/from JSON.
class LicenseEntity {
  /// Creates a [LicenseEntity].
  const LicenseEntity({
    required this.id,
    required this.customerName,
    this.companyName,
    required this.deviceId,
    required this.licenseType,
    required this.issueDate,
    this.expiryDate,
    this.features = const [],
    this.signature,
    this.metadata,
  });

  /// Creates a [LicenseEntity] from a JSON map.
  ///
  /// The JSON structure must match the format produced by [toJson].
  factory LicenseEntity.fromJson(Map<String, dynamic> json) {
    return LicenseEntity(
      id: json['id'] as String,
      customerName: json['customer'] as String,
      companyName: json['company'] as String?,
      deviceId: json['deviceId'] as String,
      licenseType: _parseLicenseType(json['type'] as String),
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: json['expiry'] != null
          ? DateTime.parse(json['expiry'] as String)
          : null,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      signature: json['signature'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Unique license identifier.
  final String id;

  /// Name of the customer / individual the license is issued to.
  final String customerName;

  /// Optional company name.
  final String? companyName;

  /// The device identifier this license is bound to.
  final String deviceId;

  /// The type of license (trial, monthly, yearly, lifetime, enterprise).
  final LicenseType licenseType;

  /// Date the license was issued.
  final DateTime issueDate;

  /// Optional expiry date. `null` for lifetime / enterprise licenses.
  final DateTime? expiryDate;

  /// List of enabled feature identifiers.
  final List<String> features;

  /// Base64-encoded digital signature.
  final String? signature;

  /// Optional metadata map for extensibility.
  final Map<String, dynamic>? metadata;

  /// Whether this license has an expiry date.
  bool get hasExpiry => expiryDate != null;

  /// Whether this license has expired.
  ///
  /// Returns `false` if there is no expiry date.
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Whether the license includes a given feature string.
  bool hasFeature(String feature) => features.contains(feature);

  /// Converts this entity to a JSON map.
  ///
  /// If [includeSignature] is `false`, the signature field is omitted.
  /// This is used when computing the signature over the license data.
  Map<String, dynamic> toJson({bool includeSignature = true}) {
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
    if (includeSignature && signature != null) {
      json['signature'] = signature;
    }
    return json;
  }

  /// Returns a JSON string of the license data without the signature.
  ///
  /// This is the canonical form that is signed and verified.
  String toSignedDataJson() {
    final json = toJson(includeSignature: false);
    // Sort keys for deterministic signing
    return _canonicalJsonEncode(json);
  }

  /// Creates a copy of this entity with optional field overrides.
  ///
  /// To explicitly set [expiryDate] to `null` (e.g. for lifetime
  /// licenses), pass [clearExpiry] as `true`.
  LicenseEntity copyWith({
    String? id,
    String? customerName,
    String? companyName,
    String? deviceId,
    LicenseType? licenseType,
    DateTime? issueDate,
    DateTime? expiryDate,
    bool clearExpiry = false,
    List<String>? features,
    String? signature,
    Map<String, dynamic>? metadata,
  }) {
    return LicenseEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      deviceId: deviceId ?? this.deviceId,
      licenseType: licenseType ?? this.licenseType,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      features: features ?? this.features,
      signature: signature ?? this.signature,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'LicenseEntity(id: $id, customer: $customerName, type: ${licenseType.value}, deviceId: $deviceId)';
  }

  static LicenseType _parseLicenseType(String value) {
    return LicenseType.fromString(value);
  }
}

/// Encodes a map as canonical JSON with sorted keys.
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

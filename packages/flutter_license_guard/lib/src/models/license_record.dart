import 'dart:convert';

import '../enums/license_status.dart';
import '../enums/license_type.dart';
import 'license_entity.dart';

/// Represents a customer in the licensing system.
///
/// This model is designed for a future online dashboard and is
/// not used by the offline SDK directly.
class Customer {
  /// Creates a [Customer].
  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.createdAt,
  });

  /// Creates a [Customer] from JSON.
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Unique customer identifier.
  final String id;

  /// Customer name.
  final String name;

  /// Email address.
  final String? email;

  /// Phone number.
  final String? phone;

  /// Company name.
  final String? company;

  /// Account creation date.
  final DateTime? createdAt;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (company != null) 'company': company,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

/// Represents a device associated with a license.
///
/// This model is designed for a future online dashboard.
class DeviceInfo {
  /// Creates a [DeviceInfo].
  const DeviceInfo({
    required this.deviceId,
    required this.platform,
    this.hostname,
    this.firstSeen,
    this.lastSeen,
    this.isActive = true,
  });

  /// Creates a [DeviceInfo] from JSON.
  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String,
      hostname: json['hostname'] as String?,
      firstSeen: json['firstSeen'] != null
          ? DateTime.parse(json['firstSeen'] as String)
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Device fingerprint hash.
  final String deviceId;

  /// Operating system platform.
  final String platform;

  /// Device hostname.
  final String? hostname;

  /// First activation date.
  final DateTime? firstSeen;

  /// Last validation date.
  final DateTime? lastSeen;

  /// Whether this device is currently active.
  final bool isActive;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'platform': platform,
        if (hostname != null) 'hostname': hostname,
        if (firstSeen != null) 'firstSeen': firstSeen!.toIso8601String(),
        if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
        'isActive': isActive,
      };
}

/// Represents an activation history entry.
///
/// This model is designed for a future online dashboard.
class ActivationHistoryEntry {
  /// Creates an [ActivationHistoryEntry].
  const ActivationHistoryEntry({
    required this.id,
    required this.licenseId,
    required this.deviceId,
    required this.activatedAt,
    this.deactivatedAt,
    this.status = 'active',
    this.metadata,
  });

  /// Creates an [ActivationHistoryEntry] from JSON.
  factory ActivationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ActivationHistoryEntry(
      id: json['id'] as String,
      licenseId: json['licenseId'] as String,
      deviceId: json['deviceId'] as String,
      activatedAt: DateTime.parse(json['activatedAt'] as String),
      deactivatedAt: json['deactivatedAt'] != null
          ? DateTime.parse(json['deactivatedAt'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Entry identifier.
  final String id;

  /// Associated license ID.
  final String licenseId;

  /// Device that was activated.
  final String deviceId;

  /// Activation timestamp.
  final DateTime activatedAt;

  /// Deactivation timestamp (if deactivated).
  final DateTime? deactivatedAt;

  /// Status: 'active', 'deactivated', 'revoked'.
  final String status;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'licenseId': licenseId,
        'deviceId': deviceId,
        'activatedAt': activatedAt.toIso8601String(),
        if (deactivatedAt != null)
          'deactivatedAt': deactivatedAt!.toIso8601String(),
        'status': status,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Represents a complete license record for admin/dashboard use.
///
/// This model aggregates a [LicenseEntity] with customer information,
/// associated devices, and activation history. It is designed for
/// a future online dashboard and is not used by the offline SDK directly.
class LicenseRecord {
  /// Creates a [LicenseRecord].
  const LicenseRecord({
    required this.license,
    required this.customer,
    this.devices = const [],
    this.activationHistory = const [],
    this.status = LicenseStatus.valid,
  });

  /// Creates a [LicenseRecord] from JSON.
  factory LicenseRecord.fromJson(Map<String, dynamic> json) {
    return LicenseRecord(
      license: LicenseEntity.fromJson(json['license'] as Map<String, dynamic>),
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      devices: (json['devices'] as List<dynamic>?)
              ?.map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activationHistory: (json['activationHistory'] as List<dynamic>?)
              ?.map((e) =>
                  ActivationHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      status: LicenseStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LicenseStatus.valid,
      ),
    );
  }

  /// The license entity.
  final LicenseEntity license;

  /// The customer who owns this license.
  final Customer customer;

  /// Devices associated with this license.
  final List<DeviceInfo> devices;

  /// Activation history entries.
  final List<ActivationHistoryEntry> activationHistory;

  /// Current license status.
  final LicenseStatus status;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'license': license.toJson(),
        'customer': customer.toJson(),
        'devices': devices.map((d) => d.toJson()).toList(),
        'activationHistory':
            activationHistory.map((a) => a.toJson()).toList(),
        'status': status.name,
      };
}

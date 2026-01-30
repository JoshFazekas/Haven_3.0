import 'dart:ui';

/// Light model for Haven lighting system
class Light {
  final int id;
  final String name;
  final int? controllerId;
  final int? zoneId;
  final bool isOn;
  final int brightness;
  final Color? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Light({
    required this.id,
    required this.name,
    this.controllerId,
    this.zoneId,
    this.isOn = false,
    this.brightness = 100,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory Light.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json['color'] != null) {
      final colorData = json['color'];
      if (colorData is Map) {
        color = Color.fromARGB(
          255,
          colorData['red'] ?? 255,
          colorData['green'] ?? 255,
          colorData['blue'] ?? 255,
        );
      } else if (colorData is int) {
        color = Color(colorData);
      }
    }

    return Light(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      controllerId: json['controller_id'] ?? json['controllerId'],
      zoneId: json['zone_id'] ?? json['zoneId'],
      isOn: json['is_on'] ?? json['isOn'] ?? false,
      brightness: json['brightness'] ?? 100,
      color: color,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'controller_id': controllerId,
      'zone_id': zoneId,
      'is_on': isOn,
      'brightness': brightness,
      'color': color != null
          ? {
              'red': color!.red,
              'green': color!.green,
              'blue': color!.blue,
            }
          : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Light copyWith({
    int? id,
    String? name,
    int? controllerId,
    int? zoneId,
    bool? isOn,
    int? brightness,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Light(
      id: id ?? this.id,
      name: name ?? this.name,
      controllerId: controllerId ?? this.controllerId,
      zoneId: zoneId ?? this.zoneId,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Controller model for Haven lighting system
class Controller {
  final int id;
  final String name;
  final String? macAddress;
  final String? ipAddress;
  final bool isOnline;
  final String? firmwareVersion;
  final int? locationId;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Controller({
    required this.id,
    required this.name,
    this.macAddress,
    this.ipAddress,
    this.isOnline = false,
    this.firmwareVersion,
    this.locationId,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
  });

  factory Controller.fromJson(Map<String, dynamic> json) {
    return Controller(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      macAddress: json['mac_address'] ?? json['macAddress'],
      ipAddress: json['ip_address'] ?? json['ipAddress'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? false,
      firmwareVersion: json['firmware_version'] ?? json['firmwareVersion'],
      locationId: json['location_id'] ?? json['locationId'],
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mac_address': macAddress,
      'ip_address': ipAddress,
      'is_online': isOnline,
      'firmware_version': firmwareVersion,
      'location_id': locationId,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Zone model for Haven lighting system
class Zone {
  final int id;
  final String name;
  final int? controllerId;
  final List<int>? lightIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Zone({
    required this.id,
    required this.name,
    this.controllerId,
    this.lightIds,
    this.createdAt,
    this.updatedAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      controllerId: json['controller_id'] ?? json['controllerId'],
      lightIds: json['light_ids'] != null
          ? List<int>.from(json['light_ids'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'controller_id': controllerId,
      'light_ids': lightIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

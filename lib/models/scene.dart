/// Scene model for Haven lighting system
class Scene {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final List<SceneLight>? lights;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Scene({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.lights,
    this.createdAt,
    this.updatedAt,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      iconName: json['icon_name'] ?? json['iconName'],
      lights: json['lights'] != null
          ? (json['lights'] as List)
              .map((e) => SceneLight.fromJson(e))
              .toList()
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
      'description': description,
      'icon_name': iconName,
      'lights': lights?.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Light configuration within a scene
class SceneLight {
  final int lightId;
  final int red;
  final int green;
  final int blue;
  final int brightness;

  SceneLight({
    required this.lightId,
    required this.red,
    required this.green,
    required this.blue,
    this.brightness = 100,
  });

  factory SceneLight.fromJson(Map<String, dynamic> json) {
    return SceneLight(
      lightId: json['light_id'] ?? json['lightId'] ?? 0,
      red: json['red'] ?? 255,
      green: json['green'] ?? 255,
      blue: json['blue'] ?? 255,
      brightness: json['brightness'] ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'light_id': lightId,
      'red': red,
      'green': green,
      'blue': blue,
      'brightness': brightness,
    };
  }
}

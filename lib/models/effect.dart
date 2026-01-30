/// Effect model for Haven lighting system
class Effect {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? iconName;
  final Map<String, dynamic>? parameters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Effect({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.iconName,
    this.parameters,
    this.createdAt,
    this.updatedAt,
  });

  factory Effect.fromJson(Map<String, dynamic> json) {
    return Effect(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      iconName: json['icon_name'] ?? json['iconName'],
      parameters: json['parameters'],
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
      'category': category,
      'icon_name': iconName,
      'parameters': parameters,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

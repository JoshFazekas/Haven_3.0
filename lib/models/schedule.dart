/// Schedule model for Haven lighting system
class Schedule {
  final int id;
  final String name;
  final bool isEnabled;
  final ScheduleTime startTime;
  final ScheduleTime? endTime;
  final List<int> daysOfWeek; // 0=Sunday, 6=Saturday
  final int? sceneId;
  final int? effectId;
  final List<int>? lightIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Schedule({
    required this.id,
    required this.name,
    this.isEnabled = true,
    required this.startTime,
    this.endTime,
    required this.daysOfWeek,
    this.sceneId,
    this.effectId,
    this.lightIds,
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isEnabled: json['is_enabled'] ?? json['isEnabled'] ?? true,
      startTime: ScheduleTime.fromJson(json['start_time'] ?? json['startTime'] ?? {}),
      endTime: json['end_time'] != null || json['endTime'] != null
          ? ScheduleTime.fromJson(json['end_time'] ?? json['endTime'])
          : null,
      daysOfWeek: json['days_of_week'] != null
          ? List<int>.from(json['days_of_week'])
          : json['daysOfWeek'] != null
              ? List<int>.from(json['daysOfWeek'])
              : [],
      sceneId: json['scene_id'] ?? json['sceneId'],
      effectId: json['effect_id'] ?? json['effectId'],
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
      'is_enabled': isEnabled,
      'start_time': startTime.toJson(),
      'end_time': endTime?.toJson(),
      'days_of_week': daysOfWeek,
      'scene_id': sceneId,
      'effect_id': effectId,
      'light_ids': lightIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Time representation for schedules
class ScheduleTime {
  final int hour; // 0-23
  final int minute; // 0-59
  final bool useSunrise;
  final bool useSunset;
  final int offsetMinutes; // Offset from sunrise/sunset

  ScheduleTime({
    this.hour = 0,
    this.minute = 0,
    this.useSunrise = false,
    this.useSunset = false,
    this.offsetMinutes = 0,
  });

  factory ScheduleTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTime(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      useSunrise: json['use_sunrise'] ?? json['useSunrise'] ?? false,
      useSunset: json['use_sunset'] ?? json['useSunset'] ?? false,
      offsetMinutes: json['offset_minutes'] ?? json['offsetMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'use_sunrise': useSunrise,
      'use_sunset': useSunset,
      'offset_minutes': offsetMinutes,
    };
  }

  String get formattedTime {
    if (useSunrise) {
      return offsetMinutes == 0
          ? 'Sunrise'
          : 'Sunrise ${offsetMinutes > 0 ? '+' : ''}$offsetMinutes min';
    }
    if (useSunset) {
      return offsetMinutes == 0
          ? 'Sunset'
          : 'Sunset ${offsetMinutes > 0 ? '+' : ''}$offsetMinutes min';
    }
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

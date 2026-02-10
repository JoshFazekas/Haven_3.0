import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haven/core/services/auth_service.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:haven/core/utils/color_capability.dart';
import 'package:haven/core/utils/lighting_status.dart';

// ─────────────────────────── Models ───────────────────────────

/// Represents a single zone or light from the API response
class LightZoneItem {
  /// "Zone" or "Light"
  final String itemType;
  final String name;
  final String? lightColor;
  final int? colorId; // Color ID from API (e.g. 21 = Green)
  final String? colorName; // Color name from API (e.g. "Green")
  final int? lightBrightnessId;
  final bool isHidden;
  final int zoneNumber;
  final String type; // e.g. "FULL COLOR", "K SERIES", "TRIM LIGHT", "L902"
  final int? lightingStatusId; // e.g. 1 = OFF, 3 = SOLID_COLOR, etc.
  final String? lightingStatus; // e.g. "OFF", "SOLID_COLOR"
  final String? colorCapability; // "Legacy" or "Extended"

  LightZoneItem({
    required this.itemType,
    required this.name,
    this.lightColor,
    this.colorId,
    this.colorName,
    this.lightBrightnessId,
    required this.isHidden,
    required this.zoneNumber,
    required this.type,
    this.lightingStatusId,
    this.lightingStatus,
    this.colorCapability,
  });

  bool get isZone => itemType == 'Zone';
  bool get isLight => itemType == 'Light';

  /// Display label for the channel/zone number, e.g. "Zone 1" or "Channel 2".
  String get channelLabel => isZone ? 'Zone $zoneNumber' : 'Channel $zoneNumber';

  /// Whether this light/zone is currently on, derived from API data.
  bool get isCurrentlyOn => LightingStatus.isOn(
        lightingStatus: lightingStatus,
        brightnessId: lightBrightnessId,
      );

  /// Brightness as a display percentage (0–100), e.g. 80.
  int get brightnessPercent =>
      LightingStatus.brightnessPercent(lightBrightnessId);

  /// Brightness as a 0.0–1.0 fraction (handy for sliders / opacity).
  double get brightnessFraction =>
      LightingStatus.brightnessFraction(lightBrightnessId);

  /// Human-readable brightness string, e.g. "80%".
  String get brightnessLabel =>
      LightingStatus.brightnessLabel(lightBrightnessId);

  /// The actual [Color] for this light based on its [colorId] and [colorCapability].
  /// Falls back to warm white (2700K) if the ID isn't found.
  Color get initialColor =>
      ColorCapability.colorForId(colorId ?? 0, capability: colorCapability) ??
      const Color(0xFFFFAE5E); // 2700K warm white fallback

  /// Display-friendly type name. Maps API type values to user-facing labels.
  String get displayType {
    switch (type.toUpperCase()) {
      case 'TRIM LIGHT':
        return 'X Series';
      default:
        return type;
    }
  }

  factory LightZoneItem.fromJson(Map<String, dynamic> json) {
    return LightZoneItem(
      itemType: json['t'] as String? ?? 'Light',
      name: json['name'] as String? ?? '',
      lightColor: json['lightColor'] as String?,
      colorId: json['colorId'] as int?,
      colorName: json['colorName'] as String?,
      lightBrightnessId: json['lightBrightnessId'] as int?,
      isHidden: json['isHidden'] as bool? ?? false,
      zoneNumber: json['zoneNumber'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      lightingStatusId: json['lightingStatusId'] as int?,
      lightingStatus: json['lightingStatus'] as String?,
      colorCapability: json['colorCapability'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        't': itemType,
        'name': name,
        'lightColor': lightColor,
        'colorId': colorId,
        'colorName': colorName,
        'lightBrightnessId': lightBrightnessId,
        'isHidden': isHidden,
        'zoneNumber': zoneNumber,
        'type': type,
        'lightingStatusId': lightingStatusId,
        'lightingStatus': lightingStatus,
        'colorCapability': colorCapability,
      };
}

/// Represents a controller from the API response
class ControllerItem {
  final int controllerId;
  final String name;
  final String macAddress;
  final String typeName;
  final bool proFlag;

  ControllerItem({
    required this.controllerId,
    required this.name,
    required this.macAddress,
    required this.typeName,
    required this.proFlag,
  });

  factory ControllerItem.fromJson(Map<String, dynamic> json) {
    return ControllerItem(
      controllerId: json['controllerId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      typeName: json['typeName'] as String? ?? '',
      proFlag: json['proFlag'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'controllerId': controllerId,
        'name': name,
        'macAddress': macAddress,
        'typeName': typeName,
        'proFlag': proFlag,
      };
}

/// Represents a saved effect from the API response
class EffectItem {
  final String name;
  final int id;
  final String effectType;
  final String configuration;

  EffectItem({
    required this.name,
    required this.id,
    required this.effectType,
    required this.configuration,
  });

  factory EffectItem.fromJson(Map<String, dynamic> json) {
    return EffectItem(
      name: json['name'] as String? ?? '',
      id: json['id'] as int? ?? 0,
      effectType: json['effectType'] as String? ?? '',
      configuration: json['configuration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'effectType': effectType,
        'configuration': configuration,
      };
}

// ─────────────────────────── Service ──────────────────────────

/// Singleton service that manages the currently-selected location's data.
///
/// • Stores zones, lights, controllers, effects for the active location.
/// • Persists the selected location ID so the app can restore it on cold start.
/// • When switching locations, the old data is discarded and replaced by a fresh
///   API response.
class LocationDataService extends ChangeNotifier {
  static final LocationDataService _instance = LocationDataService._internal();
  factory LocationDataService() => _instance;
  LocationDataService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _selectedLocationIdKey = 'selected_location_id';
  static const _cachedLocationDataKey = 'cached_location_data';

  // ── Current state ──
  int? _selectedLocationId;
  List<LightZoneItem> _zonesAndLights = [];
  List<ControllerItem> _controllers = [];
  List<EffectItem> _effects = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  // ── Public getters ──
  int? get selectedLocationId => _selectedLocationId;
  List<LightZoneItem> get zonesAndLights => List.unmodifiable(_zonesAndLights);
  List<ControllerItem> get controllers => List.unmodifiable(_controllers);
  List<EffectItem> get effects => List.unmodifiable(_effects);

  /// True during any fetch (first load or refresh).
  bool get isLoading => _isLoading;

  /// True only during a pull-to-refresh (old data still on screen).
  bool get isRefreshing => _isRefreshing;

  bool get hasData => _zonesAndLights.isNotEmpty || _controllers.isNotEmpty;

  /// Convenience: only the visible lights (isHidden == false)
  List<LightZoneItem> get visibleLights =>
      _zonesAndLights.where((item) => item.isLight && !item.isHidden).toList();

  /// Convenience: only the zones
  List<LightZoneItem> get zones =>
      _zonesAndLights.where((item) => item.isZone).toList();

  /// Convenience: all lights (including hidden)
  List<LightZoneItem> get allLights =>
      _zonesAndLights.where((item) => item.isLight).toList();

  // ─────────────────────── Core Methods ───────────────────────

  /// Load the previously-selected location from secure storage.
  /// Called on app startup (cold start) to restore state.
  Future<void> loadCachedLocation() async {
    try {
      final idStr = await _storage.read(key: _selectedLocationIdKey);
      if (idStr != null) {
        _selectedLocationId = int.tryParse(idStr);
      }

      // Also try to restore cached data so we have something to show
      // while the fresh API call is in flight.
      final cachedJson = await _storage.read(key: _cachedLocationDataKey);
      if (cachedJson != null) {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        _parseApiResponse(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LocationDataService: Error loading cache: $e');
    }
  }

  /// Populate the service from an API response map **without** making a
  /// network call. Use this right after login when we already have the
  /// response from `/api/locationlightszones`.
  Future<void> loadFromApiResponse(Map<String, dynamic> response) async {
    final locationId = response['locationId'] as int?;
    _selectedLocationId = locationId;
    _parseApiResponse(response);
    await _persistToStorage(response);
    notifyListeners();
  }

  /// Switch to a different location. Clears old data, fetches fresh data
  /// from the API, and stores the result.
  ///
  /// Returns `true` if the fetch succeeded.
  Future<bool> switchLocation(int newLocationId) async {
    if (newLocationId == _selectedLocationId && hasData) return true;
    return _fetchLocation(newLocationId, preserveOldData: false);
  }

  /// Re-fetch the current location's data from the API.
  /// Old data stays visible until the new response arrives.
  ///
  /// Use from pull-to-refresh, background sync, or anywhere you want a
  /// silent refresh without blanking the UI.
  ///
  /// Returns `true` if the fetch succeeded, `false` on error or if no
  /// location is selected.
  Future<bool> refreshCurrentLocation() async {
    final id = _selectedLocationId;
    if (id == null) return false;
    return _fetchLocation(id, preserveOldData: true);
  }

  // ─────────────────────── Private Fetch ──────────────────────

  /// Shared fetch helper used by [switchLocation] and [refreshCurrentLocation].
  ///
  /// When [preserveOldData] is true (refresh), the existing zones,
  /// controllers and effects stay on screen until the API response
  /// replaces them. When false (location switch), old data is cleared
  /// immediately so the user doesn't see stale data from a different location.
  ///
  /// Guards against concurrent fetches — if a fetch is already in flight
  /// the call returns `false` immediately.
  Future<bool> _fetchLocation(int locationId, {required bool preserveOldData}) async {
    // Prevent overlapping network calls
    if (_isLoading) return false;

    _isLoading = true;
    _isRefreshing = preserveOldData;
    notifyListeners();

    if (!preserveOldData) {
      // Clear old data immediately (switching to a different location)
      _zonesAndLights = [];
      _controllers = [];
      _effects = [];
    }
    _selectedLocationId = locationId;

    try {
      final authState = AuthState();
      final token = authState.token;
      if (token == null || token.isEmpty) {
        throw Exception('No auth token available');
      }

      final authService = AuthService();
      final response = await authService.getLocationLightsZones(
        bearerToken: token,
        locationId: locationId,
      );

      _parseApiResponse(response);
      await _persistToStorage(response);
      return true;
    } catch (e) {
      debugPrint('LocationDataService: Error fetching location $locationId: $e');
      return false;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Clear everything (used on logout).
  Future<void> clear() async {
    _selectedLocationId = null;
    _zonesAndLights = [];
    _controllers = [];
    _effects = [];

    try {
      await _storage.delete(key: _selectedLocationIdKey);
      await _storage.delete(key: _cachedLocationDataKey);
    } catch (e) {
      debugPrint('LocationDataService: Error clearing: $e');
    }

    notifyListeners();
  }

  // ─────────────────────── Private Helpers ────────────────────

  void _parseApiResponse(Map<String, dynamic> data) {
    // Parse zones and lights
    final zonesAndLightsJson = data['zonesAndLights'] as List<dynamic>? ?? [];
    _zonesAndLights =
        zonesAndLightsJson.map((e) => LightZoneItem.fromJson(e as Map<String, dynamic>)).toList();

    // Parse controllers
    final controllersJson = data['controllers'] as List<dynamic>? ?? [];
    _controllers =
        controllersJson.map((e) => ControllerItem.fromJson(e as Map<String, dynamic>)).toList();

    // Parse effects
    final effectsJson = data['effects'] as List<dynamic>? ?? [];
    _effects =
        effectsJson.map((e) => EffectItem.fromJson(e as Map<String, dynamic>)).toList();

    debugPrint(
      'LocationDataService: Loaded ${_zonesAndLights.length} zones/lights, '
      '${_controllers.length} controllers, ${_effects.length} effects '
      'for location $_selectedLocationId',
    );
  }

  Future<void> _persistToStorage(Map<String, dynamic> response) async {
    try {
      if (_selectedLocationId != null) {
        await _storage.write(
          key: _selectedLocationIdKey,
          value: _selectedLocationId.toString(),
        );
      }
      await _storage.write(
        key: _cachedLocationDataKey,
        value: jsonEncode(response),
      );
    } catch (e) {
      debugPrint('LocationDataService: Error persisting: $e');
    }
  }
}

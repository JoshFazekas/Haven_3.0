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
  final int? lightId; // Unique light ID from API (used in Commands)
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
    this.lightId,
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
  String get channelLabel =>
      isZone ? 'Zone $zoneNumber' : 'Channel $zoneNumber';

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

  /// Returns a copy of this item with the given fields replaced.
  LightZoneItem copyWith({
    String? itemType,
    int? lightId,
    String? name,
    String? lightColor,
    int? colorId,
    String? colorName,
    int? lightBrightnessId,
    bool? isHidden,
    int? zoneNumber,
    String? type,
    int? lightingStatusId,
    String? lightingStatus,
    String? colorCapability,
  }) {
    return LightZoneItem(
      itemType: itemType ?? this.itemType,
      lightId: lightId ?? this.lightId,
      name: name ?? this.name,
      lightColor: lightColor ?? this.lightColor,
      colorId: colorId ?? this.colorId,
      colorName: colorName ?? this.colorName,
      lightBrightnessId: lightBrightnessId ?? this.lightBrightnessId,
      isHidden: isHidden ?? this.isHidden,
      zoneNumber: zoneNumber ?? this.zoneNumber,
      type: type ?? this.type,
      lightingStatusId: lightingStatusId ?? this.lightingStatusId,
      lightingStatus: lightingStatus ?? this.lightingStatus,
      colorCapability: colorCapability ?? this.colorCapability,
    );
  }

  factory LightZoneItem.fromJson(Map<String, dynamic> json) {
    return LightZoneItem(
      itemType: json['t'] as String? ?? 'Light',
      lightId: json['lightId'] as int?,
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
    'lightId': lightId,
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

  /// Pending optimistic expectations.
  ///
  /// After an optimistic command (toggle, setColor, etc.) we record what
  /// the server *should* eventually return.  When a refresh completes, we
  /// compare the server data against these expectations.  If they don't
  /// match, we re-fetch (up to [_maxReconcileRetries] times) so the
  /// server has time to commit the change.
  ///
  /// Key   = lightId
  /// Value = expected [_OptimisticExpectation]
  final Map<int, _OptimisticExpectation> _pendingExpectations = {};

  /// How many times we'll re-fetch when the server data doesn't match
  /// an optimistic expectation before giving up.
  static const int _maxReconcileRetries = 3;

  /// Delay between reconciliation retries.
  static const Duration _reconcileDelay = Duration(milliseconds: 800);

  /// Snapshot of the raw server data from the last fetch (before optimistic
  /// patches).  Used by [refreshCurrentLocation] to detect mismatches.
  Map<int, LightZoneItem> _lastServerSnapshot = {};

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

  /// The "best" color capability across all lights and zones.
  ///
  /// If **any** item has `"Extended"` capability the whole location is
  /// treated as Extended so the full palette is shown when controlling
  /// all lights at once.  Falls back to `"Legacy"`.
  String get bestColorCapability {
    for (final item in _zonesAndLights) {
      if (item.colorCapability?.toUpperCase() == 'EXTENDED') return 'Extended';
    }
    return 'Legacy';
  }

  /// The "best" light type across all lights and zones.
  ///
  /// If **any** item is an X Series (`"TRIM LIGHT"`) the location is
  /// treated as X Series so Effects & Music tabs appear when controlling
  /// all lights at once.  Returns `null` if the list is empty.
  String? get bestLightType {
    for (final item in _zonesAndLights) {
      if (item.type.toUpperCase() == 'TRIM LIGHT') return 'TRIM LIGHT';
    }
    return _zonesAndLights.isNotEmpty ? _zonesAndLights.first.type : null;
  }

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

  // ─────────────────── Optimistic Updates ─────────────────────

  /// Optimistically update a light's color in the local data.
  ///
  /// Finds the [LightZoneItem] matching [lightId] and replaces its
  /// `colorId`, `colorName`, `lightingStatus`, and `lightingStatusId`
  /// so the UI reflects the change immediately — before the API responds.
  ///
  /// After calling this, fire the real API command and then call
  /// [refreshCurrentLocation] to reconcile with the server.
  void optimisticSetColor({
    required int lightId,
    required int colorId,
    String? colorName,
  }) {
    final idx = _zonesAndLights.indexWhere((item) => item.lightId == lightId);
    if (idx == -1) return;

    // Record what we expect the server to eventually return
    _pendingExpectations[lightId] = _OptimisticExpectation(
      expectedStatusId: 3, // SOLID_COLOR
      expectedColorId: colorId,
      createdAt: DateTime.now(),
    );

    final old = _zonesAndLights[idx];

    // Resolve the color name from the palette if not provided
    final resolvedName =
        colorName ??
        ColorCapability.nameForId(colorId, capability: old.colorCapability) ??
        old.colorName;

    _zonesAndLights[idx] = old.copyWith(
      colorId: colorId,
      colorName: resolvedName,
      lightingStatus: 'SOLID_COLOR',
      lightingStatusId: 3,
    );

    debugPrint(
      'LocationDataService: Optimistic update — '
      'light $lightId → colorId=$colorId ($resolvedName)',
    );
    notifyListeners();
  }

  /// Optimistically toggle a light or zone on/off in the local data.
  ///
  /// When [isOn] is `false` → sets `lightingStatus` to `"OFF"` / `lightingStatusId` to `1`.
  /// When [isOn] is `true`  → sets `lightingStatus` to `"SOLID_COLOR"` / `lightingStatusId` to `3`.
  ///
  /// After calling this, fire the real API command and then call
  /// [refreshCurrentLocation] to reconcile with the server.
  void optimisticToggle({required int lightId, required bool isOn}) {
    final idx = _zonesAndLights.indexWhere((item) => item.lightId == lightId);
    if (idx == -1) return;

    // Record what we expect the server to eventually return
    _pendingExpectations[lightId] = _OptimisticExpectation(
      expectedStatusId: isOn ? 3 : 1,
      createdAt: DateTime.now(),
    );

    final old = _zonesAndLights[idx];

    _zonesAndLights[idx] = old.copyWith(
      lightingStatus: isOn ? 'SOLID_COLOR' : 'OFF',
      lightingStatusId: isOn ? 3 : 1,
    );

    debugPrint(
      'LocationDataService: Optimistic toggle — '
      'light $lightId → ${isOn ? 'ON' : 'OFF'}',
    );
    notifyListeners();
  }

  /// Optimistically update the color on **all** lights and zones.
  ///
  /// Sets every item's `colorId`, `colorName`, `lightingStatus`, and
  /// `lightingStatusId` so the UI reflects the change immediately.
  void optimisticSetColorAll({required int colorId, String? colorName}) {
    final now = DateTime.now();
    for (int i = 0; i < _zonesAndLights.length; i++) {
      final item = _zonesAndLights[i];
      if (item.lightId != null) {
        _pendingExpectations[item.lightId!] = _OptimisticExpectation(
          expectedStatusId: 3,
          expectedColorId: colorId,
          createdAt: now,
        );
      }
      final resolvedName =
          colorName ??
          ColorCapability.nameForId(
            colorId,
            capability: item.colorCapability,
          ) ??
          item.colorName;
      _zonesAndLights[i] = item.copyWith(
        colorId: colorId,
        colorName: resolvedName,
        lightingStatus: 'SOLID_COLOR',
        lightingStatusId: 3,
      );
    }

    debugPrint(
      'LocationDataService: Optimistic set color ALL — '
      '${_zonesAndLights.length} items → colorId=$colorId',
    );
    notifyListeners();
  }

  /// Optimistically toggle **all** lights and zones in the current location.
  ///
  /// Updates every item's `lightingStatus` / `lightingStatusId` so
  /// the entire list immediately reflects the new state.
  void optimisticToggleAll({required bool isOn}) {
    final now = DateTime.now();
    final expectedStatusId = isOn ? 3 : 1;

    for (int i = 0; i < _zonesAndLights.length; i++) {
      final item = _zonesAndLights[i];
      // Record expectation for every item that has a lightId
      if (item.lightId != null) {
        _pendingExpectations[item.lightId!] = _OptimisticExpectation(
          expectedStatusId: expectedStatusId,
          createdAt: now,
        );
      }
      _zonesAndLights[i] = item.copyWith(
        lightingStatus: isOn ? 'SOLID_COLOR' : 'OFF',
        lightingStatusId: isOn ? 3 : 1,
      );
    }

    debugPrint(
      'LocationDataService: Optimistic toggle ALL — '
      '${_zonesAndLights.length} items → ${isOn ? 'ON' : 'OFF'}',
    );
    notifyListeners();
  }

  /// Optimistically update a single light's brightness in the local data.
  ///
  /// [brightnessId] is the API value 1–10 (maps to 10%–100%).
  void optimisticSetBrightness({
    required int lightId,
    required int brightnessId,
  }) {
    final idx = _zonesAndLights.indexWhere((item) => item.lightId == lightId);
    if (idx == -1) return;

    _pendingExpectations[lightId] = _OptimisticExpectation(
      expectedBrightnessId: brightnessId,
      createdAt: DateTime.now(),
    );

    final old = _zonesAndLights[idx];
    _zonesAndLights[idx] = old.copyWith(lightBrightnessId: brightnessId);

    debugPrint(
      'LocationDataService: Optimistic brightness — '
      'light $lightId → brightnessId=$brightnessId',
    );
    notifyListeners();
  }

  /// Optimistically update brightness on **all** lights and zones.
  void optimisticSetBrightnessAll({required int brightnessId}) {
    final now = DateTime.now();
    for (int i = 0; i < _zonesAndLights.length; i++) {
      final item = _zonesAndLights[i];
      if (item.lightId != null) {
        _pendingExpectations[item.lightId!] = _OptimisticExpectation(
          expectedBrightnessId: brightnessId,
          createdAt: now,
        );
      }
      _zonesAndLights[i] = item.copyWith(lightBrightnessId: brightnessId);
    }

    debugPrint(
      'LocationDataService: Optimistic brightness ALL — '
      '${_zonesAndLights.length} items → brightnessId=$brightnessId',
    );
    notifyListeners();
  }

  /// Switch to a different location. Clears old data, fetches fresh data
  /// from the API, and stores the result.
  ///
  /// Returns `true` if the fetch succeeded.
  Future<bool> switchLocation(int newLocationId) async {
    if (newLocationId == _selectedLocationId && hasData) return true;
    _pendingExpectations.clear();
    _lastServerSnapshot.clear();
    return _fetchLocation(newLocationId, preserveOldData: false);
  }

  /// Re-fetch the current location's data from the API.
  /// Old data stays visible until the new response arrives.
  ///
  /// After the fetch, if any pending optimistic expectations don't match
  /// the server data, the service will **re-fetch** (up to
  /// [_maxReconcileRetries] times with a short delay) so the server has
  /// time to commit the change.  If all retries are exhausted the server
  /// state is accepted as-is.
  ///
  /// Returns `true` if the fetch succeeded, `false` on error or if no
  /// location is selected.
  Future<bool> refreshCurrentLocation() async {
    final id = _selectedLocationId;
    if (id == null) return false;

    // Prune expired expectations before checking
    _pendingExpectations.removeWhere((_, exp) => exp.isExpired);

    final success = await _fetchLocation(id, preserveOldData: true);
    if (!success) return false;

    // If there are no pending expectations, we're done
    if (_pendingExpectations.isEmpty) return true;

    // Check whether the server data matches our expectations.
    // The initial fetch snapshot is already in _lastServerSnapshot.
    // If it doesn't match, retry up to _maxReconcileRetries times.
    for (int attempt = 0; attempt <= _maxReconcileRetries; attempt++) {
      final mismatches = <int>[];

      for (final entry in _pendingExpectations.entries) {
        final lightId = entry.key;
        final expectation = entry.value;
        if (expectation.isExpired) continue;

        // Compare against the raw server snapshot (before optimistic patches)
        final serverItem = _lastServerSnapshot[lightId];
        if (serverItem != null && !expectation.matches(serverItem)) {
          mismatches.add(lightId);
        }
      }

      if (mismatches.isEmpty) {
        // Server matches — clear expectations and we're done
        debugPrint(
          'LocationDataService: Server data matches expectations '
          '(check #$attempt)',
        );
        _pendingExpectations.clear();
        return true;
      }

      // If this was the last allowed attempt, don't retry
      if (attempt == _maxReconcileRetries) break;

      debugPrint(
        'LocationDataService: Server mismatch for ${mismatches.length} '
        'light(s) — re-fetching (retry ${attempt + 1}/$_maxReconcileRetries)',
      );

      // Re-apply optimistic state so the UI doesn't flicker
      _reapplyExpectations();

      // Wait before retrying
      await Future.delayed(_reconcileDelay);
      final retrySuccess = await _fetchLocation(id, preserveOldData: true);
      if (!retrySuccess) return false;
    }

    // Exhausted all retries — accept server state, clear expectations
    debugPrint(
      'LocationDataService: Exhausted $_maxReconcileRetries retries — '
      'accepting server state',
    );
    _pendingExpectations.clear();
    return true;
  }

  /// Re-apply pending optimistic expectations to `_zonesAndLights` so the
  /// UI doesn't flicker back to stale server state between retries.
  void _reapplyExpectations() {
    _reapplyExpectationsQuietly();
    notifyListeners();
  }

  /// Same as [_reapplyExpectations] but without calling [notifyListeners].
  /// Used inside [_fetchLocation] where the `finally` block already notifies.
  void _reapplyExpectationsQuietly() {
    for (final entry in _pendingExpectations.entries) {
      final lightId = entry.key;
      final expectation = entry.value;
      if (expectation.isExpired) continue;

      final idx = _zonesAndLights.indexWhere((z) => z.lightId == lightId);
      if (idx == -1) continue;

      final old = _zonesAndLights[idx];
      _zonesAndLights[idx] = old.copyWith(
        lightingStatusId: expectation.expectedStatusId ?? old.lightingStatusId,
        lightingStatus: expectation.expectedStatusId != null
            ? (expectation.expectedStatusId == 1 ? 'OFF' : 'SOLID_COLOR')
            : old.lightingStatus,
        colorId: expectation.expectedColorId ?? old.colorId,
        lightBrightnessId:
            expectation.expectedBrightnessId ?? old.lightBrightnessId,
      );
    }
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
  Future<bool> _fetchLocation(
    int locationId, {
    required bool preserveOldData,
  }) async {
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

      // Snapshot the raw server state for mismatch detection before
      // re-applying optimistic expectations.
      _lastServerSnapshot = {
        for (final item in _zonesAndLights)
          if (item.lightId != null) item.lightId!: item,
      };

      // If there are pending optimistic expectations, re-apply them
      // before notifyListeners fires so the UI never flickers to stale data.
      if (_pendingExpectations.isNotEmpty) {
        _reapplyExpectationsQuietly();
      }

      return true;
    } catch (e) {
      debugPrint(
        'LocationDataService: Error fetching location $locationId: $e',
      );
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
    _pendingExpectations.clear();
    _lastServerSnapshot.clear();

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
    _zonesAndLights = zonesAndLightsJson
        .map((e) => LightZoneItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse controllers
    final controllersJson = data['controllers'] as List<dynamic>? ?? [];
    _controllers = controllersJson
        .map((e) => ControllerItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse effects
    final effectsJson = data['effects'] as List<dynamic>? ?? [];
    _effects = effectsJson
        .map((e) => EffectItem.fromJson(e as Map<String, dynamic>))
        .toList();

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

/// Tracks what we expect the server to eventually return for a given light
/// after an optimistic command.
class _OptimisticExpectation {
  /// The `lightingStatusId` we expect (1 = OFF, 3 = SOLID_COLOR, etc.).
  final int? expectedStatusId;

  /// The `colorId` we expect (null if the command didn't change the color).
  final int? expectedColorId;

  /// The `lightBrightnessId` we expect (1–10, null if unchanged).
  final int? expectedBrightnessId;

  /// When this expectation was created.
  final DateTime createdAt;

  _OptimisticExpectation({
    this.expectedStatusId,
    this.expectedColorId,
    this.expectedBrightnessId,
    required this.createdAt,
  });

  /// Returns `true` if [item] from the server matches this expectation.
  bool matches(LightZoneItem item) {
    if (expectedStatusId != null && item.lightingStatusId != expectedStatusId) {
      return false;
    }
    if (expectedColorId != null && item.colorId != expectedColorId) {
      return false;
    }
    if (expectedBrightnessId != null &&
        item.lightBrightnessId != expectedBrightnessId) {
      return false;
    }
    return true;
  }

  /// Expectations older than this are considered stale and auto-cleared.
  static const _maxAge = Duration(seconds: 15);

  bool get isExpired => DateTime.now().difference(createdAt) > _maxAge;
}

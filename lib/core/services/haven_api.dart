import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/services/api_logger.dart';
import 'package:haven/core/services/auth_state.dart';

// ╔═══════════════════════════════════════════════════════════════════╗
// ║                     HAVEN API SERVICE                            ║
// ║                                                                   ║
// ║  Central file for every HTTP call in the app.                     ║
// ║  Import this file anywhere you need to hit the Haven backend.     ║
// ║                                                                   ║
// ║  Base URLs (from EnvironmentConfig):                              ║
// ║    LOCAL  → http://localhost:5001                                  ║
// ║    DEV    → https://dev-api.havenlighting.com                     ║
// ║    PROD   → https://stg-api.havenlighting.com                     ║
// ╚═══════════════════════════════════════════════════════════════════╝

class HavenApi {
  // ──────────────────────── Singleton ────────────────────────
  static final HavenApi _instance = HavenApi._internal();
  factory HavenApi() => _instance;
  HavenApi._internal();

  final ApiLogger _logger = ApiLogger();

  // ──────────────────────── Base URLs ────────────────────────
  static String get baseUrl => EnvironmentConfig.baseUrl;
  static String get apiUrl => '$baseUrl/api';

  // ──────────────────────── Default Headers ──────────────────
  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const Map<String, String> _portalHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Referer': 'https://portal.havenlighting.com/',
    'Origin': 'https://portal.havenlighting.com',
  };

  /// Returns auth headers with the current bearer token.
  /// Throws [HavenApiException] if no token is available.
  static Map<String, String> _authHeaders({String? token}) {
    final t = token ?? AuthState().token;
    if (t == null || t.isEmpty) {
      throw HavenApiException('No auth token available. Please sign in again.');
    }
    return {..._jsonHeaders, 'Authorization': 'Bearer $t'};
  }

  // ═══════════════════════════════════════════════════════════
  //  1.  AUTH  —  /api/Auth
  // ═══════════════════════════════════════════════════════════

  /// **POST** `/api/Auth/authenticate`
  ///
  /// Signs in with email + password.
  /// Returns `{ token, refreshToken, id }`.
  Future<Map<String, dynamic>> authenticate({
    required String email,
    required String password,
  }) async {
    const path = '/api/Auth/authenticate';
    final url = '$baseUrl$path';
    final body = {'userName': email, 'password': password};

    return _post(
      url,
      headers: _portalHeaders,
      body: body,
      label: 'authenticate',
    );
  }

  /// **POST** `/api/Auth/refresh`
  ///
  /// Exchanges the stored refresh token for a **new** bearer token.
  /// On success the new token + refreshToken are persisted via
  /// [AuthState.updateToken] so every subsequent request picks them up.
  ///
  /// Returns `true` if the refresh succeeded, `false` otherwise.
  Future<bool> refreshTokens() async {
    final authState = AuthState();
    final refreshToken = authState.refreshToken;
    final userId = authState.userId;

    if (refreshToken == null || refreshToken.isEmpty || userId == null) {
      debugPrint('HavenApi: Cannot refresh — no refreshToken or userId');
      return false;
    }

    const path = '/api/Auth/refresh';
    final url = '$baseUrl$path';
    final body = jsonEncode({'userId': userId, 'refreshToken': refreshToken});

    _logger.logRequest(
      method: 'POST',
      endpoint: url,
      headers: _jsonHeaders,
      body: {'userId': userId, 'refreshToken': '***'},
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _jsonHeaders,
        body: body,
      );

      _logger.logResponse(
        method: 'POST',
        endpoint: url,
        statusCode: response.statusCode,
        body: response.body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final newUserId = data['id'] as int? ?? userId;

        if (newToken != null && newToken.isNotEmpty) {
          await authState.updateToken(
            token: newToken,
            refreshToken: newRefreshToken ?? refreshToken,
            userId: newUserId,
          );
          debugPrint('HavenApi: Token refreshed successfully');
          return true;
        }
      }

      debugPrint('HavenApi: Token refresh failed (${response.statusCode})');
      return false;
    } catch (e) {
      debugPrint('HavenApi: Token refresh error: $e');
      return false;
    }
  }

  /// Whether a refresh is already in-flight (prevents concurrent refreshes).
  bool _isRefreshing = false;

  // ═══════════════════════════════════════════════════════════
  //  2.  USER  —  /api/User
  // ═══════════════════════════════════════════════════════════

  /// **GET** `/api/User/GetCurrent`
  ///
  /// Validates the token by hitting a lightweight endpoint.
  /// Returns `true` if the token is still valid.
  Future<bool> validateToken({required String token}) async {
    const path = '/api/User/GetCurrent';
    final url = '$baseUrl$path';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders(token: token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// **POST** `/api/User/Info`
  ///
  /// Fetches full user profile info for the given email.
  /// Returns decoded JSON with `{ success, ... }`.
  Future<Map<String, dynamic>> getUserInfo({
    required String token,
    required String email,
  }) async {
    const path = '/api/User/Info';
    final url = '$baseUrl$path';
    final headers = {
      'Content-Type': 'application/json-patch+json',
      'Authorization': 'Bearer $token',
    };
    final body = {'email': email};

    return _post(url, headers: headers, body: body, label: 'getUserInfo');
  }

  // ═══════════════════════════════════════════════════════════
  //  3.  LOCATION  —  /api/locationlightszones
  // ═══════════════════════════════════════════════════════════

  /// **POST** `/api/locationlightszones`
  ///
  /// Fetches all zones, lights, controllers & effects for a location.
  /// This is the main data-loading call for the Lights screen.
  Future<Map<String, dynamic>> getLocationLightsZones({
    required String token,
    required int locationId,
  }) async {
    const path = '/api/locationlightszones';
    final url = '$baseUrl$path';
    final body = {'locationId': locationId};

    return _post(
      url,
      headers: _authHeaders(token: token),
      body: body,
      label: 'getLocationLightsZones',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4.  COMMANDS  —  /api/Commands
  // ═══════════════════════════════════════════════════════════

  /// **POST** `/api/Commands/SetColor`
  ///
  /// Sets the color of a light or zone.
  ///
  /// - [id]      – `lightId` or zone ID from location data.
  /// - [type]    – `"Light"` or `"Zone"`.
  /// - [colorId] – Color ID from [ColorCapability] palettes (1-8 whites, 11-57 colors).
  Future<http.Response> setColor({
    required int id,
    required String type,
    required int colorId,
  }) async {
    const path = '/api/Commands/SetColor';
    final url = '$baseUrl$path';
    final body = {'id': id, 'type': type, 'colorId': colorId};

    return _postRaw(
      url,
      headers: _authHeaders(),
      body: body,
      label: 'SetColor',
    );
  }

  /// **POST** `/api/Commands/Off`
  ///
  /// Turns a light or zone **off**.
  ///
  /// - [id]   – `lightId` or zone ID from location data.
  /// - [type] – `"Light"` or `"Zone"`.
  Future<http.Response> turnOff({required int id, required String type}) async {
    const path = '/api/Commands/Off';
    final url = '$baseUrl$path';
    final body = {'id': id, 'type': type};

    return _postRaw(url, headers: _authHeaders(), body: body, label: 'Off');
  }

  /// **POST** `/api/Commands/On`
  ///
  /// Turns a light or zone **on** (restores its last color/brightness).
  ///
  /// - [id]   – `lightId` or zone ID from location data.
  /// - [type] – `"Light"` or `"Zone"`.
  Future<http.Response> turnOn({required int id, required String type}) async {
    const path = '/api/Commands/On';
    final url = '$baseUrl$path';
    final body = {'id': id, 'type': type};

    return _postRaw(url, headers: _authHeaders(), body: body, label: 'On');
  }

  /// **POST** `/api/Commands/Brightness`
  ///
  /// Sets the brightness of a light, zone, or entire location.
  ///
  /// - [id]         – `lightId`, zone ID, or location ID.
  /// - [type]       – `"Light"`, `"Zone"`, or `"Location"`.
  /// - [brightness] – Brightness level 1–10 (maps to 10%–100%).
  Future<http.Response> setBrightness({
    required int id,
    required String type,
    required int brightness,
  }) async {
    const path = '/api/Commands/Brightness';
    final url = '$baseUrl$path';
    final body = {'id': id, 'type': type, 'brightness': brightness};

    return _postRaw(
      url,
      headers: _authHeaders(),
      body: body,
      label: 'Brightness',
    );
  }

  // ─────────────────── Light / Zone Rename ───────────────────

  /// **PUT** `/api/Light/UpdateName`
  ///
  /// Renames a light or zone.
  ///
  /// - [lightId] – The target's `lightId` (or zone id).
  /// - [name]    – The new display name.
  /// - `pinName` is auto-generated as the first 3 characters of [name].
  Future<http.Response> updateLightName({
    required int lightId,
    required String name,
  }) async {
    const path = '/api/Light/UpdateName';
    final url = '$baseUrl$path';

    // Abbreviated 3-char pin derived from the user-entered name
    final pinName = name.length >= 3 ? name.substring(0, 3) : name;

    final body = {'lightId': lightId, 'name': name, 'pinName': pinName};

    return _putRaw(
      url,
      headers: {
        ..._authHeaders(),
        'Content-Type': 'application/json-patch+json',
      },
      body: body,
      label: 'UpdateName',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5.  DEVICE  —  /api/Device
  // ═══════════════════════════════════════════════════════════

  /// **GET** `/api/Device/GetCredentials/{mac}?controllerTypeId={typeId}`
  ///
  /// Fetches the API key for a controller by its MAC address.
  /// Returns the raw API key string.
  Future<String> getDeviceCredentials({
    required String macAddress,
    required String token,
    int controllerTypeId = 1,
  }) async {
    final normalizedMac = macAddress
        .replaceAll(':', '')
        .replaceAll('-', '')
        .toUpperCase();
    final path =
        '/api/Device/GetCredentials/$normalizedMac?controllerTypeId=$controllerTypeId';
    final url = '$baseUrl$path';

    _logger.logRequest(
      method: 'GET',
      endpoint: url,
      headers: _authHeaders(token: token),
    );

    final response = await http.get(
      Uri.parse(url),
      headers: {..._portalHeaders, 'Authorization': 'Bearer $token'},
    );

    _logger.logResponse(
      method: 'GET',
      endpoint: url,
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) {
        throw HavenApiException('Device not registered. MAC: $normalizedMac');
      }
      final apiKeyString = data[0] as String;
      return apiKeyString.split(' : ')[1];
    } else if (response.statusCode == 401) {
      throw HavenApiException('Authentication failed. Please sign in again.');
    } else if (response.statusCode == 404) {
      throw HavenApiException('Device not found. MAC: $normalizedMac');
    } else {
      throw HavenApiException(
        'Failed to get credentials (${response.statusCode}).',
      );
    }
  }

  /// **POST** `/api/Device/DeviceAnnounce`
  ///
  /// The URL given to a controller so it can phone home after provisioning.
  /// (Used during BLE provisioning — the URL is sent to the device, not called
  /// directly by the app.)
  static String get deviceAnnounceUrl => '$baseUrl/api/Device/DeviceAnnounce';

  // ═══════════════════════════════════════════════════════════
  //  6.  DEVICES  —  /api/Devices
  // ═══════════════════════════════════════════════════════════

  /// **POST** `/api/Devices/AddDeviceToLocation`
  ///
  /// Associates a provisioned controller with a location.
  Future<void> addDeviceToLocation({
    required String deviceId,
    required int locationId,
    required String token,
  }) async {
    const path = '/api/Devices/AddDeviceToLocation';
    final url = '$baseUrl$path';
    final body = {'deviceId': deviceId, 'locationId': locationId};

    _logger.logRequest(
      method: 'POST',
      endpoint: url,
      headers: _authHeaders(token: token),
      body: body,
    );

    final response = await http.post(
      Uri.parse(url),
      headers: _authHeaders(token: token),
      body: jsonEncode(body),
    );

    _logger.logResponse(
      method: 'POST',
      endpoint: url,
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 409) {
      debugPrint(
        'HavenApi: addDeviceToLocation succeeded (${response.statusCode})',
      );
    } else if (response.statusCode == 401) {
      throw HavenApiException('Authentication failed. Please sign in again.');
    } else {
      throw HavenApiException(
        'Failed to add device to location (${response.statusCode}).',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS  —  shared request logic
  // ═══════════════════════════════════════════════════════════

  /// Attempts to refresh the token (once) if a 401 is not already being
  /// handled.  Returns `true` when a fresh token was stored.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false; // another call is already refreshing
    _isRefreshing = true;
    try {
      return await refreshTokens();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Rebuilds the header map with the **current** bearer token so that
  /// a retried request picks up the freshly-refreshed token.
  Map<String, String> _refreshAuthHeader(Map<String, String> original) {
    final token = AuthState().token;
    if (token == null || token.isEmpty) return original;
    return {...original, 'Authorization': 'Bearer $token'};
  }

  /// Sends a POST and returns the **decoded JSON** response.
  ///
  /// If the server responds with **401** and a refresh token is available
  /// the method will attempt a single token refresh and retry the request.
  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    _logger.logRequest(
      method: 'POST',
      endpoint: url,
      headers: headers,
      body: body,
    );

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _logger.logResponse(
        method: 'POST',
        endpoint: url,
        statusCode: response.statusCode,
        body: response.body,
      );

      // ── 401 → try token refresh then retry once ──
      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          debugPrint('HavenApi: Retrying $label after token refresh');
          final retryHeaders = _refreshAuthHeader(headers);
          response = await http.post(
            Uri.parse(url),
            headers: retryHeaders,
            body: jsonEncode(body),
          );

          _logger.logResponse(
            method: 'POST (retry)',
            endpoint: url,
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw HavenApiException('Authentication failed. Please sign in again.');
      } else {
        throw HavenApiException(
          '$label failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e is HavenApiException) rethrow;
      _logger.logError(method: 'POST', endpoint: url, error: e);
      throw HavenApiException(
        '$label failed. Please check your connection and try again.',
      );
    }
  }

  /// Sends a POST and returns the **raw [http.Response]** so the caller
  /// can inspect status codes directly (useful for commands that return 204).
  ///
  /// If the server responds with **401** and a refresh token is available
  /// the method will attempt a single token refresh and retry the request.
  Future<http.Response> _postRaw(
    String url, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    _logger.logRequest(
      method: 'POST',
      endpoint: url,
      headers: headers,
      body: body,
    );

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _logger.logResponse(
        method: 'POST',
        endpoint: url,
        statusCode: response.statusCode,
        body: response.body,
      );

      // ── 401 → try token refresh then retry once ──
      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          debugPrint('HavenApi: Retrying $label after token refresh');
          final retryHeaders = _refreshAuthHeader(headers);
          response = await http.post(
            Uri.parse(url),
            headers: retryHeaders,
            body: jsonEncode(body),
          );

          _logger.logResponse(
            method: 'POST (retry)',
            endpoint: url,
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      }

      return response;
    } catch (e) {
      _logger.logError(method: 'POST', endpoint: url, error: e);
      throw HavenApiException(
        '$label failed. Please check your connection and try again.',
      );
    }
  }

  /// Sends a PUT and returns the **raw [http.Response]** so the caller
  /// can inspect status codes directly.
  ///
  /// If the server responds with **401** and a refresh token is available
  /// the method will attempt a single token refresh and retry the request.
  Future<http.Response> _putRaw(
    String url, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required String label,
  }) async {
    _logger.logRequest(
      method: 'PUT',
      endpoint: url,
      headers: headers,
      body: body,
    );

    try {
      var response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _logger.logResponse(
        method: 'PUT',
        endpoint: url,
        statusCode: response.statusCode,
        body: response.body,
      );

      // ── 401 → try token refresh then retry once ──
      if (response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          debugPrint('HavenApi: Retrying $label after token refresh');
          final retryHeaders = _refreshAuthHeader(headers);
          response = await http.put(
            Uri.parse(url),
            headers: retryHeaders,
            body: jsonEncode(body),
          );

          _logger.logResponse(
            method: 'PUT (retry)',
            endpoint: url,
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      }

      return response;
    } catch (e) {
      _logger.logError(method: 'PUT', endpoint: url, error: e);
      throw HavenApiException(
        '$label failed. Please check your connection and try again.',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Exception
// ═══════════════════════════════════════════════════════════════════

class HavenApiException implements Exception {
  final String message;
  HavenApiException(this.message);

  @override
  String toString() => message;
}

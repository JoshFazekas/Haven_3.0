import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/services/api_logger.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:haven/core/services/location_data_service.dart';
import 'package:haven/core/services/haven_api.dart';

/// Service for sending commands to the Haven lighting API.
///
/// All command endpoints live under `/api/Commands/…`.
class CommandService {
  static final CommandService _instance = CommandService._internal();
  factory CommandService() => _instance;
  CommandService._internal();

  static String get _baseUrl => '${EnvironmentConfig.baseUrl}/api/Commands';

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final ApiLogger _logger = ApiLogger();

  // ─────────────────────── Set Color ───────────────────────

  /// Sends the **SetColor** command for a single light or zone.
  ///
  /// Parameters:
  /// - [id]      – The `lightId` (or zone id) from the location data.
  /// - [type]    – `"Light"` or `"Zone"`.
  /// - [colorId] – The color ID to set (from [ColorCapability] palettes).
  ///
  /// Throws a [CommandException] on failure.
  ///
  /// ```dart
  /// await CommandService().setColor(
  ///   id: 1022,
  ///   type: 'Light',
  ///   colorId: 12,
  /// );
  /// ```
  Future<void> setColor({
    required int id,
    required String type,
    required int colorId,
  }) async {
    final token = AuthState().token;
    if (token == null || token.isEmpty) {
      throw CommandException('No auth token available. Please sign in again.');
    }

    // ── 1. Optimistic update ──
    // Update local state immediately so the UI reflects the change.
    if (type == 'Light') {
      LocationDataService().optimisticSetColor(
        lightId: id,
        colorId: colorId,
      );
    }

    // ── 2. Fire the API call ──
    final endpoint = '$_baseUrl/SetColor';

    final headers = {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };

    final body = {
      'id': id,
      'type': type,
      'colorId': colorId,
    };

    // Log the request
    _logger.logRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
    );

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      // Log the response
      _logger.logResponse(
        method: 'POST',
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint(
          'CommandService: SetColor succeeded — id=$id, type=$type, colorId=$colorId',
        );

        // ── 3. Background refresh ──
        // Reconcile local state with the server so all lights/zones
        // reflect the true current status.
        LocationDataService().refreshCurrentLocation().then((success) {
          debugPrint(
            'CommandService: Background refresh ${success ? 'succeeded' : 'failed'}',
          );
        });
      } else if (response.statusCode == 401) {
        throw CommandException('Authentication failed. Please sign in again.');
      } else {
        throw CommandException(
          'SetColor failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e is CommandException) rethrow;

      _logger.logError(method: 'POST', endpoint: endpoint, error: e);

      throw CommandException(
        'Failed to set color. Please check your connection and try again.',
      );
    }
  }

  // ─────────────────────── Turn Off ───────────────────────

  /// Sends the **Off** command for a single light or zone.
  ///
  /// Flow: optimistic update → fire-and-forget API call (no refresh).
  ///
  /// ```dart
  /// await CommandService().turnOff(id: 1022, type: 'Light');
  /// ```
  Future<void> turnOff({
    required int id,
    required String type,
  }) async {
    // ── 1. Optimistic update ──
    if (type == 'Light') {
      LocationDataService().optimisticToggle(lightId: id, isOn: false);
    }

    // ── 2. Fire the API call ──
    try {
      final response = await HavenApi().turnOff(id: id, type: type);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('CommandService: Off succeeded — id=$id, type=$type');
      } else if (response.statusCode == 401) {
        throw CommandException('Authentication failed. Please sign in again.');
      } else {
        throw CommandException(
          'Off failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e is CommandException) rethrow;
      throw CommandException(
        'Failed to turn off. Please check your connection and try again.',
      );
    }
  }

  // ─────────────────────── Turn On ───────────────────────

  /// Sends the **On** command for a single light or zone.
  ///
  /// Flow: optimistic update → fire-and-forget API call (no refresh).
  ///
  /// ```dart
  /// await CommandService().turnOn(id: 1022, type: 'Light');
  /// ```
  Future<void> turnOn({
    required int id,
    required String type,
  }) async {
    // ── 1. Optimistic update ──
    if (type == 'Light') {
      LocationDataService().optimisticToggle(lightId: id, isOn: true);
    }

    // ── 2. Fire the API call ──
    try {
      final response = await HavenApi().turnOn(id: id, type: type);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('CommandService: On succeeded — id=$id, type=$type');
      } else if (response.statusCode == 401) {
        throw CommandException('Authentication failed. Please sign in again.');
      } else {
        throw CommandException(
          'On failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e is CommandException) rethrow;
      throw CommandException(
        'Failed to turn on. Please check your connection and try again.',
      );
    }
  }
}

class CommandException implements Exception {
  final String message;
  CommandException(this.message);

  @override
  String toString() => message;
}

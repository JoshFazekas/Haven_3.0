import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_logger.dart';
import 'auth_state.dart';

class DeviceService {
  static const String _baseUrl = 'https://stg-api.havenlighting.com/api';
  static const String _devicesByLocationEndpoint = 'App/Device/Location/';

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Referer': 'https://portal.havenlighting.com/',
    'Origin': 'https://portal.havenlighting.com',
  };

  final ApiLogger _logger = ApiLogger();
  final AuthState _authState = AuthState();

  /// Gets devices by location ID
  /// Returns the raw response body as a map
  Future<Map<String, dynamic>> getDevicesByLocation(int locationId) async {
    final endpoint = '$_baseUrl/$_devicesByLocationEndpoint$locationId';
    final token = _authState.token;

    if (token == null) {
      throw DeviceServiceException('Not authenticated. Please sign in.');
    }

    final headers = {..._defaultHeaders, 'Authorization': 'Bearer $token'};

    // Log the request
    _logger.logRequest(method: 'GET', endpoint: endpoint, headers: headers);

    try {
      final response = await http.get(Uri.parse(endpoint), headers: headers);

      // Log the response
      _logger.logResponse(
        method: 'GET',
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
      );

      // Return the full response info for debugging
      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? jsonDecode(response.body) : null,
        'rawBody': response.body,
        'endpoint': endpoint,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Log the error
      _logger.logError(method: 'GET', endpoint: endpoint, error: e);

      if (e is DeviceServiceException) rethrow;

      throw DeviceServiceException(
        'Failed to fetch devices. Please try again.',
      );
    }
  }
}

class DeviceServiceException implements Exception {
  final String message;
  DeviceServiceException(this.message);

  @override
  String toString() => message;
}

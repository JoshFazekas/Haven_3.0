import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LightService {
  /// Sets the color of a light/zone
  static Future<bool> setColor({
    required int locationId,
    required Color color,
    int brightness = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/App/Light/SetColor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.bearerToken}',
        },
        body: jsonEncode({
          'locationId': locationId,
          'red': color.red,
          'green': color.green,
          'blue': color.blue,
          'brightness': brightness,
        }),
      );

      debugPrint('SetColor Response: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting color: $e');
      return false;
    }
  }

  /// Sets color by light ID
  static Future<bool> setColorByLightId({
    required int lightId,
    required Color color,
    int brightness = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/App/Light/$lightId/SetColor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.bearerToken}',
        },
        body: jsonEncode({
          'red': color.red,
          'green': color.green,
          'blue': color.blue,
          'brightness': brightness,
        }),
      );

      debugPrint('SetColorByLightId Response: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting color by light ID: $e');
      return false;
    }
  }

  /// Sets color by zone ID
  static Future<bool> setColorByZoneId({
    required int zoneId,
    required Color color,
    int brightness = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/App/Zone/$zoneId/SetColor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.bearerToken}',
        },
        body: jsonEncode({
          'red': color.red,
          'green': color.green,
          'blue': color.blue,
          'brightness': brightness,
        }),
      );

      debugPrint('SetColorByZoneId Response: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting color by zone ID: $e');
      return false;
    }
  }

  /// Sets color by controller ID
  static Future<bool> setColorByControllerId({
    required int controllerId,
    required Color color,
    int brightness = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/App/Controller/$controllerId/SetColor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.bearerToken}',
        },
        body: jsonEncode({
          'red': color.red,
          'green': color.green,
          'blue': color.blue,
          'brightness': brightness,
        }),
      );

      debugPrint('SetColorByControllerId Response: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting color by controller ID: $e');
      return false;
    }
  }

  /// Generic light command
  static Future<bool> sendLightCommand({
    required int lightId,
    required Color color,
    int brightness = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/App/Light/Command'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.bearerToken}',
        },
        body: jsonEncode({
          'lightId': lightId,
          'command': 'setColor',
          'red': color.red,
          'green': color.green,
          'blue': color.blue,
          'brightness': brightness,
        }),
      );

      debugPrint('SendLightCommand Response: ${response.statusCode} - ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending light command: $e');
      return false;
    }
  }

  /// Helper method to convert Color to RGB values for debugging
  static Map<String, int> colorToRgb(Color color) {
    return {
      'red': color.red,
      'green': color.green,
      'blue': color.blue,
    };
  }
}

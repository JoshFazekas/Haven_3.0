import 'package:haven/core/config/environment.dart';

/// API configuration for the Haven lighting system
class ApiConfig {
  // Base URL is determined by the current environment
  // DEV: https://dev-api.havenlighting.com
  // PROD: https://stg-api.havenlighting.com
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  static const String bearerToken = 'YOUR_TOKEN_HERE';
  
  // Example endpoints that might be used:
  // - https://api.haven.com/App/Light/SetColor
  // - https://api.haven.com/App/Light/123/SetColor
  // - https://api.haven.com/App/Zone/456/SetColor
  // - https://api.haven.com/App/Controller/789/SetColor
  
  // Common location IDs you might use
  static const int defaultLocationId = 27040;
  
  // Default brightness level (0-100)
  static const int defaultBrightness = 100;
}

/// Example usage:
/// 
/// ```dart
/// await LightService.setColorByLightId(
///   lightId: 123,
///   color: Colors.red,
///   brightness: ApiConfig.defaultBrightness,
/// );
/// ```

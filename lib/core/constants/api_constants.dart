/// API Constants for Haven Lighting
/// 
/// This file defines the base URLs for dev and prod environments.
/// The environment is set at app startup via main_dev.dart or main_prod.dart

enum Environment {
  dev,
  prod,
}

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // Base URLs for each environment
  static const String devBaseUrl = 'https://dev-api.havenlighting.com/api';
  static const String prodBaseUrl = 'https://prod-api.havenlighting.com/api';

  // Current environment - set at app initialization
  static Environment _currentEnvironment = Environment.dev;
  
  /// Initialize the environment. Call this in main_dev.dart or main_prod.dart
  static void init(Environment env) {
    _currentEnvironment = env;
  }

  /// Get the current environment
  static Environment get currentEnvironment => _currentEnvironment;

  /// Get the base URL for the current environment
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.dev:
        return devBaseUrl;
      case Environment.prod:
        return prodBaseUrl;
    }
  }

  /// Check if currently in dev environment
  static bool get isDev => _currentEnvironment == Environment.dev;

  /// Check if currently in prod environment
  static bool get isProd => _currentEnvironment == Environment.prod;

  // API Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ===========================================
  // API Endpoints - Add your endpoints below
  // ===========================================
  
}

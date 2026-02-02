/// Available environments for the Haven App
enum Environment {
  /// Development environment - uses https://dev-api.havenlighting.com
  dev,
  /// Production environment - uses https://stg-api.havenlighting.com
  prod,
}

class EnvironmentConfig {
  static Environment _environment = Environment.dev;
  
  /// Initialize the environment - call this before runApp()
  static void init(Environment env) {
    _environment = env;
  }
  
  /// Get the current environment
  static Environment get current => _environment;
  
  /// Check if running in development mode
  static bool get isDev => _environment == Environment.dev;
  
  /// Check if running in production mode
  static bool get isProd => _environment == Environment.prod;
  
  /// Get the base API URL for the current environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.dev:
        return 'https://dev-api.havenlighting.com';
      case Environment.prod:
        return 'https://stg-api.havenlighting.com';
    }
  }
  
  /// Get the environment name for display/logging purposes
  static String get name {
    switch (_environment) {
      case Environment.dev:
        return 'Development';
      case Environment.prod:
        return 'Production';
    }
  }
}

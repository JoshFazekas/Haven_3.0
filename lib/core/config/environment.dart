/// Available environments for the Haven App
enum Environment {
  /// Local environment - uses http://localhost:5001
  local,
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
  
  /// Check if running in local mode
  static bool get isLocal => _environment == Environment.local;
  
  /// Check if running in development mode
  static bool get isDev => _environment == Environment.dev;
  
  /// Check if running in production mode
  static bool get isProd => _environment == Environment.prod;

  /// Returns true for non-production environments (local + dev)
  static bool get showBadge => _environment != Environment.prod;
  
  /// Get the base API URL for the current environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.local:
        return 'http://localhost:5001';
      case Environment.dev:
        return 'https://dev-api.havenlighting.com';
      case Environment.prod:
        return 'https://stg-api.havenlighting.com';
    }
  }

  /// Short badge label for the environment indicator
  static String get badgeLabel {
    switch (_environment) {
      case Environment.local:
        return 'LOCAL';
      case Environment.dev:
        return 'DEV';
      case Environment.prod:
        return '';
    }
  }
  
  /// Get the environment name for display/logging purposes
  static String get name {
    switch (_environment) {
      case Environment.local:
        return 'Local';
      case Environment.dev:
        return 'Development';
      case Environment.prod:
        return 'Production';
    }
  }
}

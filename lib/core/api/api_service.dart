import 'package:dio/dio.dart';
import 'package:haven/core/constants/api_constants.dart';

/// Dio-based API Service for Haven Lighting
/// 
/// This service handles all HTTP requests to the Haven API.
/// The base URL is determined by the environment set in ApiConstants.
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  // Private constructor
  ApiService._() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  /// Get the singleton instance of ApiService
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Re-initialize the service (useful if environment changes)
  static void reinitialize() {
    _instance = ApiService._();
  }

  /// Base options for Dio
  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    sendTimeout: ApiConstants.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  /// Setup interceptors for logging, auth, error handling
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log requests in dev mode
          if (ApiConstants.isDev) {
            print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
            print('📤 DATA: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log responses in dev mode
          if (ApiConstants.isDev) {
            print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Log errors in dev mode
          if (ApiConstants.isDev) {
            print('❌ ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
            print('📛 MESSAGE: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Set the authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear the authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ============================================
  // Generic HTTP Methods
  // ============================================

  /// Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Generic DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ============================================
  // API Endpoints - Add your methods below
  // ============================================

}


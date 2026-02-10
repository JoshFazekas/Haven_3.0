import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haven/core/services/location_data_service.dart';

class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _userTypeKey = 'user_type';
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _lastEmailKey = 'last_user_email'; // Persists after logout
  static const _fullNameKey = 'user_full_name';
  static const _phoneNumberKey = 'user_phone_number';
  static const _defaultLocationIdKey = 'user_default_location_id';

  String? _token;
  String? _refreshToken;
  int? _userId;
  String? _username;
  int? _userType;
  String? _email;
  String? _password;
  String? _fullName;
  String? _phoneNumber;
  int? _defaultLocationId;

  /// Cached location lights/zones response from last login
  Map<String, dynamic>? _locationLightsZones;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  int? get userId => _userId;
  String? get username => _username;
  int? get userType => _userType;
  String? get email => _email;
  String? get password => _password;
  String? get fullName => _fullName;
  String? get phoneNumber => _phoneNumber;
  int? get defaultLocationId => _defaultLocationId;
  Map<String, dynamic>? get locationLightsZones => _locationLightsZones;
  bool get isLoggedIn => _token != null;

  /// Load stored credentials from secure storage
  Future<bool> loadStoredCredentials() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
      final userIdStr = await _storage.read(key: _userIdKey);
      _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
      _username = await _storage.read(key: _usernameKey);
      final userTypeStr = await _storage.read(key: _userTypeKey);
      _userType = userTypeStr != null ? int.tryParse(userTypeStr) : null;
      _email = await _storage.read(key: _emailKey);
      _password = await _storage.read(key: _passwordKey);
      _fullName = await _storage.read(key: _fullNameKey);
      _phoneNumber = await _storage.read(key: _phoneNumberKey);
      final defaultLocStr = await _storage.read(key: _defaultLocationIdKey);
      _defaultLocationId = defaultLocStr != null ? int.tryParse(defaultLocStr) : null;

      notifyListeners();
      return _token != null && _email != null && _password != null;
    } catch (e) {
      debugPrint('Error loading stored credentials: $e');
      return false;
    }
  }

  /// Check if we have stored credentials (without loading them into memory)
  Future<bool> hasStoredCredentials() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      return token != null && email != null && password != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> login({
    required String token,
    required String refreshToken,
    required int userId,
    String? username,
    int? userType,
    String? email,
    String? password,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _userId = userId;
    if (username != null) _username = username;
    if (userType != null) _userType = userType;
    if (email != null) _email = email;
    if (password != null) _password = password;

    // Persist to secure storage
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _userIdKey, value: userId.toString());
      if (username != null) {
        await _storage.write(key: _usernameKey, value: username);
      }
      if (userType != null) {
        await _storage.write(key: _userTypeKey, value: userType.toString());
      }
      if (email != null) {
        await _storage.write(key: _emailKey, value: email);
      }
      if (password != null) {
        await _storage.write(key: _passwordKey, value: password);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }

    notifyListeners();
  }

  /// Save user info fetched from /api/User/Info
  Future<void> saveUserInfo({
    required String fullName,
    required String phoneNumber,
    required int defaultLocationId,
    required String email,
    required int userId,
  }) async {
    _fullName = fullName;
    _phoneNumber = phoneNumber;
    _defaultLocationId = defaultLocationId;
    _email = email;
    _userId = userId;

    try {
      await _storage.write(key: _fullNameKey, value: fullName);
      await _storage.write(key: _phoneNumberKey, value: phoneNumber);
      await _storage.write(key: _defaultLocationIdKey, value: defaultLocationId.toString());
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      debugPrint('Error saving user info: $e');
    }

    notifyListeners();
  }

  /// Store location lights/zones data in memory (not persisted)
  void saveLocationLightsZones(Map<String, dynamic> data) {
    _locationLightsZones = data;
    notifyListeners();
  }

  /// Update just the token (used for re-authentication)
  Future<void> updateToken({
    required String token,
    required String refreshToken,
    required int userId,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _userId = userId;

    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      debugPrint('Error updating token: $e');
    }

    notifyListeners();
  }

  Future<void> logout() async {
    // Save the last email before clearing (for auto-fill on next login)
    final lastEmail = _email;

    _token = null;
    _refreshToken = null;
    _userId = null;
    _username = null;
    _userType = null;
    _email = null;
    _password = null;
    _fullName = null;
    _phoneNumber = null;
    _defaultLocationId = null;
    _locationLightsZones = null;

    // Clear location data service
    await LocationDataService().clear();

    // Clear from secure storage but preserve last email
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: _userTypeKey);
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
      await _storage.delete(key: _fullNameKey);
      await _storage.delete(key: _phoneNumberKey);
      await _storage.delete(key: _defaultLocationIdKey);

      // Save the last email for auto-fill
      if (lastEmail != null) {
        await _storage.write(key: _lastEmailKey, value: lastEmail);
      }
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }

    notifyListeners();
  }

  /// Get the last email used (persists after logout for auto-fill)
  Future<String?> getLastEmail() async {
    try {
      return await _storage.read(key: _lastEmailKey);
    } catch (e) {
      debugPrint('Error reading last email: $e');
      return null;
    }
  }
}

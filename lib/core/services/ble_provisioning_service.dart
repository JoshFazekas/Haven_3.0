import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:haven/core/services/bluetooth_scan_service.dart';
import 'package:haven/core/services/ble_debug_service.dart';
import 'package:haven/core/config/environment.dart';

/// Haven Controller BLE Service and Characteristic UUIDs (from NIKKO app)
class HavenBleUuids {
  static const String serviceUuid = '00000006-8C26-476F-89A7-A108033A69C7';
  static const String characteristicUuid = '0000000B-8C26-476F-89A7-A108033A69C7';
}

/// Haven API endpoints - uses EnvironmentConfig.baseUrl so they respect the active scheme
class HavenApi {
  static String get deviceAnnounceUrl => '${EnvironmentConfig.baseUrl}/api/Device/DeviceAnnounce';
  static String get addDeviceToLocationUrl => '${EnvironmentConfig.baseUrl}/api/Devices/AddDeviceToLocation';
  static String get getCredentialsUrl => '${EnvironmentConfig.baseUrl}/api/Device/GetCredentials';
}

/// Default WiFi credentials (for development/testing)
const String defaultWifiSsid = 'Hav3n Production_IoT';
const String defaultWifiPassword = '12345678';

/// Provisioning state enum
enum ProvisioningState {
  idle,
  connecting,
  discoveringServices,
  gettingDeviceInfo,
  fetchingApiKey,
  settingApiKey,
  settingWifiSsid,
  settingWifiPassword,
  settingAnnounceUrl,
  connectingToServer,
  addingToLocation,
  stoppingBleAdvertising,
  completed,
  failed,
}

/// Device info from WHO_AM_I command
class DeviceInfo {
  final String deviceType;
  final String macAddress;
  final String firmwareVersion;
  final String last4Mac;

  DeviceInfo({
    required this.deviceType,
    required this.macAddress,
    required this.firmwareVersion,
  }) : last4Mac = macAddress.length >= 4
          ? macAddress.substring(macAddress.length - 4).toUpperCase()
          : macAddress.toUpperCase();
}

/// Result of provisioning operation
class ProvisioningResult {
  final bool success;
  final String? errorMessage;
  final String? deviceMac;
  final DeviceInfo? deviceInfo;

  ProvisioningResult({
    required this.success,
    this.errorMessage,
    this.deviceMac,
    this.deviceInfo,
  });
}

/// Service for BLE provisioning of Haven devices (matching NIKKO app flow)
class BleProvisioningService {
  static final BleProvisioningService _instance = BleProvisioningService._internal();
  factory BleProvisioningService() => _instance;
  BleProvisioningService._internal();

  final BleDebugService _debugService = BleDebugService();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _havenCharacteristic;

  final _stateController = StreamController<ProvisioningState>.broadcast();
  final _deviceInfoController = StreamController<DeviceInfo>.broadcast();
  
  Stream<ProvisioningState> get stateStream => _stateController.stream;
  Stream<DeviceInfo> get deviceInfoStream => _deviceInfoController.stream;

  ProvisioningState _currentState = ProvisioningState.idle;
  ProvisioningState get currentState => _currentState;

  void _updateState(ProvisioningState state) {
    _currentState = state;
    _stateController.add(state);
    _debugService.logEvent('STATE', details: state.name);
  }

  /// Get the current WiFi network name the phone is connected to
  Future<String?> getCurrentWifiSsid() async {
    try {
      // Check location permission (required for WiFi info on both platforms)
      final locationStatus = await Permission.locationWhenInUse.status;
      if (!locationStatus.isGranted) {
        final result = await Permission.locationWhenInUse.request();
        if (!result.isGranted) {
          debugPrint('Location permission denied - cannot get WiFi SSID');
          return null;
        }
      }
      
      final info = NetworkInfo();
      String? wifiName = await info.getWifiName();
      
      // Clean up the SSID (remove quotes on some platforms)
      if (wifiName != null) {
        wifiName = wifiName.replaceAll('"', '');
        if (wifiName.isEmpty || wifiName == '<unknown ssid>') {
          return null;
        }
      }
      
      return wifiName;
    } catch (e) {
      debugPrint('Error getting WiFi SSID: $e');
      return null;
    }
  }

  /// Send a command to the device and read the response
  Future<String> _sendCommand(String command) async {
    if (_havenCharacteristic == null) {
      throw Exception('Characteristic not available');
    }

    _debugService.logTx('Command', command);

    await _havenCharacteristic!.write(
      utf8.encode(command),
      withoutResponse: false,
    );

    // Small delay to allow device to process
    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = await _havenCharacteristic!.read();
    final response = utf8.decode(bytes, allowMalformed: true);

    _debugService.logRx('Response', response);

    return response;
  }

  /// Get controllerTypeId based on device name
  int _getControllerTypeId(String deviceName) {
    final upperName = deviceName.toUpperCase();

    if (upperName.contains('X-POE') || upperName.contains('XPOE') || upperName.contains('X POE')) {
      return 9;
    }
    if (upperName.contains('X-MINI') || upperName.contains('XMINI') || upperName.contains('X MINI')) {
      return 10;
    }
    if (upperName.contains('X-SERIES') || upperName.contains('XSERIES') || upperName.contains('X SERIES')) {
      return 8;
    }
    return 1; // Default fallback
  }

  /// Get API key from Haven server
  Future<String> _getDeviceApiKey({
    required String macAddress,
    required String bearerToken,
    required String deviceName,
  }) async {
    final normalizedMac = macAddress.replaceAll(':', '').replaceAll('-', '').toUpperCase();
    final controllerTypeId = _getControllerTypeId(deviceName);

    final url = '${HavenApi.getCredentialsUrl}/$normalizedMac?controllerTypeId=$controllerTypeId';

    _debugService.logEvent('API', details: 'GET $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
        'Referer': 'https://portal.havenlighting.com/',
        'Origin': 'https://portal.havenlighting.com',
      },
    );

    _debugService.logRx('API Response', 'Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) {
        throw Exception('Device not registered in Haven system. MAC: $normalizedMac');
      }

      final apiKeyString = data[0] as String;
      final parts = apiKeyString.split(' : ');

      if (parts.length < 2) {
        throw Exception('Invalid API key format: $apiKeyString');
      }

      return parts[1];
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please sign in again.');
    } else if (response.statusCode == 404) {
      throw Exception('Device not found. MAC: $normalizedMac');
    } else {
      throw Exception('Failed to get credentials: ${response.statusCode}');
    }
  }

  /// Add device to location via Haven API
  Future<void> _addDeviceToLocation({
    required String deviceId,
    required int locationId,
    required String bearerToken,
  }) async {
    final body = jsonEncode({
      'deviceId': deviceId,
      'locationId': locationId,
    });

    _debugService.logEvent('API', details: 'POST ${HavenApi.addDeviceToLocationUrl}');
    _debugService.logTx('API Body', body);

    final response = await http.post(
      Uri.parse(HavenApi.addDeviceToLocationUrl),
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    _debugService.logRx('API Response', 'Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      _debugService.logEvent('API', details: 'Device added to location successfully');
    } else if (response.statusCode == 409) {
      _debugService.logEvent('API', details: 'Device already added to location (conflict - OK)');
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please sign in again.');
    } else {
      throw Exception('Failed to add device to location: ${response.statusCode}');
    }
  }

  /// Parse WHO_AM_I response to extract device info
  DeviceInfo _parseWhoAmIResponse(String response, String deviceName) {
    String macAddress;
    String firmwareVersion = '---';
    String deviceType = 'Unknown';

    // Try to extract JSON from response
    final startIndex = response.indexOf('{');
    final endIndex = response.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final jsonStr = response.substring(startIndex, endIndex + 1);
      _debugService.logEvent('PARSE', details: 'Found JSON: $jsonStr');

      // Clean up JSON issues
      String cleanedJson = jsonStr
          .replaceAll(RegExp(r'"\s*,\s*"'), '","')
          .replaceAll("'", '"');

      final data = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // Extract MAC address
      final deviceId = data['DeviceID'] ??
          data['deviceId'] ??
          data['MAC'] ??
          data['mac'] ??
          data['device_id'] ??
          data['macAddress'];
      if (deviceId == null) {
        throw Exception('DeviceID not found in response');
      }
      macAddress = deviceId.toString();

      // Extract firmware version
      firmwareVersion = (data['Firmware_ Version'] ??
          data['Firmware_Version'] ??
          data['FirmwareVersion'] ??
          data['firmwareVersion'] ??
          data['Firmware'] ??
          data['firmware'] ??
          data['FW'] ??
          data['fw'] ??
          '---').toString();

      // Extract device type
      deviceType = (data['Model_Name'] ??
          data['ModelName'] ??
          data['DeviceType'] ??
          data['deviceType'] ??
          data['Type'] ??
          data['type'] ??
          'Unknown').toString();
    } else {
      // Fallback: try regex MAC pattern
      final macMatch = RegExp(r'([0-9A-Fa-f]{2}[:-]?){5}[0-9A-Fa-f]{2}').firstMatch(response);
      if (macMatch != null) {
        macAddress = macMatch.group(0)!.replaceAll(':', '').replaceAll('-', '').toUpperCase();
      } else {
        throw Exception('Could not parse MAC from response');
      }
    }

    macAddress = macAddress.replaceAll(':', '').replaceAll('-', '').toUpperCase();

    // Determine friendly device type from deviceName if not found in response
    if (deviceType == 'Unknown' || deviceType.isEmpty) {
      if (deviceName.toUpperCase().contains('MINI')) {
        deviceType = 'X-Mini';
      } else if (deviceName.toUpperCase().contains('POE')) {
        deviceType = 'X-POE';
      } else {
        deviceType = 'X-Series';
      }
    }

    return DeviceInfo(
      deviceType: deviceType,
      macAddress: macAddress,
      firmwareVersion: firmwareVersion,
    );
  }

  /// Main provisioning method - matches NIKKO app flow
  Future<ProvisioningResult> provisionDevice({
    required NearbyHavenDevice device,
    required String bearerToken,
    required int locationId,
    String? wifiSsid,
    String? wifiPassword,
  }) async {
    // Clear previous debug logs
    _debugService.clear();

    final effectiveSsid = (wifiSsid != null && wifiSsid.isNotEmpty) ? wifiSsid : defaultWifiSsid;
    final effectivePassword = (wifiPassword != null && wifiPassword.isNotEmpty) ? wifiPassword : defaultWifiPassword;

    try {
      if (device.scanResult == null) {
        _debugService.logError('INIT', 'Invalid device - no scan result');
        return ProvisioningResult(success: false, errorMessage: 'Invalid device');
      }

      final bluetoothDevice = device.scanResult!.device;
      final deviceName = device.deviceName;

      _debugService.logEvent('INIT', details: 'Starting provisioning for $deviceName');
      _debugService.logEvent('INIT', details: 'Location ID: $locationId');
      _debugService.logEvent('INIT', details: 'WiFi SSID: $effectiveSsid');

      // Stop any ongoing scan
      await FlutterBluePlus.stopScan();

      // Step 1: Connect to device
      _updateState(ProvisioningState.connecting);
      _debugService.logEvent('CONNECT', details: 'Connecting to device...');

      try {
        await bluetoothDevice.connect(timeout: const Duration(seconds: 10));
        _connectedDevice = bluetoothDevice;
        _debugService.logEvent('CONNECT', details: 'Connected successfully');
      } catch (e) {
        _debugService.logError('CONNECT', 'Failed: $e');
        _updateState(ProvisioningState.failed);
        return ProvisioningResult(success: false, errorMessage: 'Failed to connect: $e');
      }

      // Step 2: Discover services
      _updateState(ProvisioningState.discoveringServices);
      _debugService.logEvent('DISCOVER', details: 'Discovering services...');

      final services = await bluetoothDevice.discoverServices();
      _debugService.logEvent('DISCOVER', details: 'Found ${services.length} services');

      // Find Haven service and characteristic
      for (var service in services) {
        _debugService.logEvent('SERVICE', details: 'Found: ${service.uuid}');
        if (service.uuid.toString().toUpperCase() == HavenBleUuids.serviceUuid.toUpperCase()) {
          _debugService.logEvent('SERVICE', details: 'Haven service found!');
          for (var char in service.characteristics) {
            if (char.uuid.toString().toUpperCase() == HavenBleUuids.characteristicUuid.toUpperCase()) {
              _havenCharacteristic = char;
              _debugService.logEvent('CHAR', details: 'Haven characteristic found!');
              break;
            }
          }
        }
      }

      if (_havenCharacteristic == null) {
        _debugService.logError('DISCOVER', 'Haven characteristic not found');
        await _disconnect();
        _updateState(ProvisioningState.failed);
        return ProvisioningResult(success: false, errorMessage: 'Haven service not found');
      }

      // Step 3: Get device info via WHO_AM_I
      _updateState(ProvisioningState.gettingDeviceInfo);
      _debugService.logEvent('WHO_AM_I', details: 'Getting device info...');

      final whoAmIResponse = await _sendCommand('<CONSOLE.WHO_AM_I()>');
      await Future.delayed(const Duration(milliseconds: 500));

      DeviceInfo deviceInfo;
      try {
        deviceInfo = _parseWhoAmIResponse(whoAmIResponse, deviceName);
        _debugService.logEvent('WHO_AM_I', details: 'MAC: ${deviceInfo.macAddress}');
        _debugService.logEvent('WHO_AM_I', details: 'Type: ${deviceInfo.deviceType}');
        _debugService.logEvent('WHO_AM_I', details: 'Firmware: ${deviceInfo.firmwareVersion}');
        _deviceInfoController.add(deviceInfo);
      } catch (e) {
        _debugService.logError('WHO_AM_I', 'Failed to parse: $e');
        await _disconnect();
        _updateState(ProvisioningState.failed);
        return ProvisioningResult(success: false, errorMessage: 'Failed to get device info: $e');
      }

      // Step 4: Get API key from server
      _updateState(ProvisioningState.fetchingApiKey);
      _debugService.logEvent('API_KEY', details: 'Fetching from server...');

      String apiKey;
      try {
        apiKey = await _getDeviceApiKey(
          macAddress: deviceInfo.macAddress,
          bearerToken: bearerToken,
          deviceName: deviceName,
        );
        _debugService.logEvent('API_KEY', details: 'Got API key: ${apiKey.substring(0, 8)}...');
      } catch (e) {
        _debugService.logError('API_KEY', 'Failed: $e');
        await _disconnect();
        _updateState(ProvisioningState.failed);
        return ProvisioningResult(success: false, errorMessage: 'Failed to get API key: $e');
      }

      // Step 5: Set API Key
      _updateState(ProvisioningState.settingApiKey);
      await _sendCommand('<SYSTEM.SET({"API_KEY":"$apiKey"})>');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 6: Set WiFi SSID
      _updateState(ProvisioningState.settingWifiSsid);
      await _sendCommand('<WIFI.SET({"SSID1":"$effectiveSsid"})>');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 7: Set WiFi Password
      _updateState(ProvisioningState.settingWifiPassword);
      await _sendCommand('<WIFI.SET({"PASS1":"$effectivePassword"})>');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 8: Set Device Announce URL
      _updateState(ProvisioningState.settingAnnounceUrl);
      await _sendCommand('<SYSTEM.SET({"DEVICE_ANNOUNCE_URL":"${HavenApi.deviceAnnounceUrl}"})>');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 9: Connect to server
      _updateState(ProvisioningState.connectingToServer);
      await _sendCommand('<SYSTEM.SERVER_CONNECT()>');
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 10: Add device to location via API
      _updateState(ProvisioningState.addingToLocation);
      try {
        await _addDeviceToLocation(
          deviceId: deviceInfo.macAddress,
          locationId: locationId,
          bearerToken: bearerToken,
        );
      } catch (e) {
        _debugService.logError('LOCATION', 'Warning: $e (continuing)');
        // Don't fail - continue with BLE stop
      }

      // Step 11: Stop BLE advertising
      _updateState(ProvisioningState.stoppingBleAdvertising);
      try {
        await _sendCommand('<BLE.ADVERT_STOP()>');
      } catch (e) {
        _debugService.logError('BLE_STOP', 'Failed (device may have disconnected): $e');
        // Continue anyway
      }

      // Step 12: Disconnect
      await _disconnect();

      _debugService.logEvent('COMPLETE', details: 'Provisioning completed successfully!');
      _updateState(ProvisioningState.completed);

      return ProvisioningResult(
        success: true,
        deviceMac: deviceInfo.macAddress,
        deviceInfo: deviceInfo,
      );

    } catch (e) {
      debugPrint('Provisioning error: $e');
      _debugService.logError('FATAL', 'Provisioning failed: $e');
      await _disconnect();
      _updateState(ProvisioningState.failed);
      return ProvisioningResult(success: false, errorMessage: 'Provisioning failed: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
    _havenCharacteristic = null;
  }

  void reset() {
    _updateState(ProvisioningState.idle);
  }

  void dispose() {
    _disconnect();
    _stateController.close();
    _deviceInfoController.close();
  }
}

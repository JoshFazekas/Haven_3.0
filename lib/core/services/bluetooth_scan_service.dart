import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// RSSI threshold for "nearby" detection (in dBm).
/// -50 dBm means the device is close (within ~2-3 meters)
const int kNearbyRssiThreshold = -50;

/// Information about a nearby Haven device
class NearbyHavenDevice {
  final String deviceId;
  final String deviceName;
  final int rssi;
  final ScanResult? scanResult;

  NearbyHavenDevice({
    required this.deviceId,
    required this.deviceName,
    required this.rssi,
    required this.scanResult,
  });

  /// Mock constructor for testing/design purposes
  NearbyHavenDevice.mock({
    required this.deviceId,
    required this.deviceName,
    required this.rssi,
  }) : scanResult = null;
}

/// Service for scanning Bluetooth devices and detecting nearby Haven controllers
class BluetoothScanService {
  static final BluetoothScanService _instance = BluetoothScanService._internal();
  factory BluetoothScanService() => _instance;
  BluetoothScanService._internal();

  // Stream controller for nearby device detection
  final _nearbyDeviceController = StreamController<NearbyHavenDevice>.broadcast();
  Stream<NearbyHavenDevice> get nearbyDeviceStream => _nearbyDeviceController.stream;

  // Discovered devices map
  final Map<String, ScanResult> _discoveredDevices = {};
  
  // Set of device IDs that the user has dismissed (won't show popup again)
  final Set<String> _dismissedDeviceIds = {};

  // Subscription and state
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanRefreshTimer;
  bool _isScanning = false;
  bool _hasShownPopupForCurrentScan = false;
  String? _lastNotifiedDeviceId;

  bool get isScanning => _isScanning;
  
  /// Mark a device as dismissed so it won't trigger popup again
  void dismissDevice(String deviceId) {
    _dismissedDeviceIds.add(deviceId);
    debugPrint('Device dismissed, will not show popup again: $deviceId');
  }
  
  /// Check if a device has been dismissed
  bool isDeviceDismissed(String deviceId) {
    return _dismissedDeviceIds.contains(deviceId);
  }
  
  /// Clear all dismissed devices (e.g., on app restart or user request)
  void clearDismissedDevices() {
    _dismissedDeviceIds.clear();
  }

  /// Check if a device name belongs to a Haven device
  bool isHavenDevice(String? name) {
    if (name == null || name.isEmpty) return false;
    final upperName = name.toUpperCase();
    return upperName.startsWith('HVN') || upperName.startsWith('HAVEN');
  }

  /// Check and request Bluetooth permissions
  Future<bool> checkPermissions() async {
    debugPrint('Checking Bluetooth permissions...');
    
    if (Platform.isIOS) {
      try {
        // Check current adapter state first
        BluetoothAdapterState adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
        debugPrint('Initial adapter state: $adapterState');
        
        // If Bluetooth is off, we can't scan
        if (adapterState == BluetoothAdapterState.off) {
          debugPrint('Bluetooth is OFF - please enable it in Settings');
          return false;
        }
        
        // If unauthorized, permission was denied
        if (adapterState == BluetoothAdapterState.unauthorized) {
          debugPrint('Bluetooth is UNAUTHORIZED - permission denied');
          return false;
        }
        
        // If unknown, try to trigger the permission prompt by starting a scan
        if (adapterState == BluetoothAdapterState.unknown) {
          debugPrint('Adapter state unknown, attempting scan to trigger permission...');
          try {
            await FlutterBluePlus.startScan(timeout: const Duration(milliseconds: 500));
            await FlutterBluePlus.stopScan();
          } catch (e) {
            debugPrint('Permission trigger scan error: $e');
          }
          
          // Wait and check again
          await Future.delayed(const Duration(milliseconds: 500));
          adapterState = await FlutterBluePlus.adapterState.first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => BluetoothAdapterState.unknown,
          );
          debugPrint('Adapter state after permission trigger: $adapterState');
        }
        
        final isReady = adapterState == BluetoothAdapterState.on;
        debugPrint('Bluetooth ready: $isReady');
        return isReady;
        
      } catch (e) {
        debugPrint('iOS permission check error: $e');
        return false;
      }
    } else {
      // Android
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

      bool allGranted =
          (bluetoothScanStatus.isGranted || bluetoothScanStatus.isLimited) &&
          (bluetoothConnectStatus.isGranted || bluetoothConnectStatus.isLimited);

      if (allGranted) return true;

      List<Permission> permissionsToRequest = [];
      if (!bluetoothScanStatus.isGranted && !bluetoothScanStatus.isLimited) {
        permissionsToRequest.add(Permission.bluetoothScan);
      }
      if (!bluetoothConnectStatus.isGranted && !bluetoothConnectStatus.isLimited) {
        permissionsToRequest.add(Permission.bluetoothConnect);
      }

      if (permissionsToRequest.isNotEmpty) {
        await permissionsToRequest.request();

        final newBluetoothScanStatus = await Permission.bluetoothScan.status;
        final newBluetoothConnectStatus = await Permission.bluetoothConnect.status;

        allGranted = (newBluetoothScanStatus.isGranted || newBluetoothScanStatus.isLimited) &&
            (newBluetoothConnectStatus.isGranted || newBluetoothConnectStatus.isLimited);
      }

      return allGranted;
    }
  }

  /// Start scanning for Haven devices
  Future<void> startScanning() async {
    debugPrint('startScanning() called, isScanning: $_isScanning');
    if (_isScanning) {
      debugPrint('Already scanning, returning');
      return;
    }

    final hasPermissions = await checkPermissions();
    debugPrint('Permissions granted: $hasPermissions');
    if (!hasPermissions) {
      debugPrint('Bluetooth permissions not granted - cannot scan');
      return;
    }

    // Cancel any existing subscriptions
    _scanRefreshTimer?.cancel();
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();

    _isScanning = true;
    _hasShownPopupForCurrentScan = false;
    _discoveredDevices.clear();

    debugPrint('Setting up scan listener...');
    
    // Listen for scan results
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        debugPrint('Scan results received: ${results.length} devices');
        for (final result in results) {
          final deviceId = result.device.remoteId.toString();
          _discoveredDevices[deviceId] = result;
        }
        _checkForNearbyDevice();
      },
      onError: (e) {
        debugPrint('Scan error: $e');
      },
    );

    // Start the scan
    debugPrint('Starting BLE scan...');
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.startScan(
          androidUsesFineLocation: true,
          continuousUpdates: true,
        );
        debugPrint('Android scan started successfully');
      } catch (e) {
        debugPrint('Android scan start error: $e');
      }
    } else {
      try {
        await FlutterBluePlus.startScan(continuousUpdates: true);
        debugPrint('iOS scan started successfully');
      } catch (e) {
        debugPrint('iOS scan start error: $e');
      }
    }

    // Periodically check for nearby devices
    _scanRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isScanning) {
        _checkForNearbyDevice();
      }
    });

    debugPrint('Started Bluetooth scanning for Haven devices');
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    _scanRefreshTimer?.cancel();
    _scanRefreshTimer = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Stop scan error: $e');
    }

    _isScanning = false;
    _discoveredDevices.clear();
    debugPrint('Stopped Bluetooth scanning');
  }

  /// Check if any Haven device is nearby (RSSI >= threshold)
  void _checkForNearbyDevice() {
    // If we've already shown a popup for this scan session, don't show another
    if (_hasShownPopupForCurrentScan) return;

    // Debug: Log total discovered devices count
    debugPrint('=== BLE SCAN: ${_discoveredDevices.length} total devices ===');

    for (final entry in _discoveredDevices.entries) {
      final result = entry.value;
      final deviceId = entry.key;
      final deviceName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.advertisementData.advName;

      // Debug: Log ALL discovered devices (including unnamed)
      final displayName = deviceName.isEmpty ? '(no name)' : deviceName;
      final advData = result.advertisementData;
      debugPrint('BLE: $displayName | RSSI: ${result.rssi} dBm | ID: $deviceId | Services: ${advData.serviceUuids.length} | Haven: ${isHavenDevice(deviceName)}');

      // Skip devices with positive dBm (invalid readings)
      if (result.rssi >= 0) continue;
      
      // Skip devices that the user has dismissed
      if (_dismissedDeviceIds.contains(deviceId)) continue;

      // Check if it's a Haven device with strong signal (> -50 dBm)
      if (isHavenDevice(deviceName) && result.rssi > kNearbyRssiThreshold) {
        // Skip if we already notified about this exact device
        if (_lastNotifiedDeviceId == deviceId) continue;

        // Found a nearby Haven device - notify listeners
        _hasShownPopupForCurrentScan = true;
        _lastNotifiedDeviceId = deviceId;

        final nearbyDevice = NearbyHavenDevice(
          deviceId: deviceId,
          deviceName: deviceName,
          rssi: result.rssi,
          scanResult: result,
        );

        _nearbyDeviceController.add(nearbyDevice);
        debugPrint('Nearby Haven device detected: $deviceName (RSSI: ${result.rssi} dBm)');
        break; // Only notify for the first device found
      }
    }
  }

  /// Reset the popup flag to allow showing popup for new devices
  void resetPopupFlag() {
    _hasShownPopupForCurrentScan = false;
    _lastNotifiedDeviceId = null;
  }

  /// Get list of all discovered Haven devices
  List<NearbyHavenDevice> getDiscoveredHavenDevices() {
    return _discoveredDevices.entries
        .where((entry) {
          final result = entry.value;
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.advertisementData.advName;
          return isHavenDevice(deviceName) && result.rssi < 0;
        })
        .map((entry) => NearbyHavenDevice(
              deviceId: entry.key,
              deviceName: entry.value.device.platformName.isNotEmpty
                  ? entry.value.device.platformName
                  : entry.value.advertisementData.advName,
              rssi: entry.value.rssi,
              scanResult: entry.value,
            ))
        .toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // Sort by signal strength
  }
  
  /// Get list of ALL discovered devices (for debugging)
  List<Map<String, dynamic>> getAllDiscoveredDevices() {
    return _discoveredDevices.entries
        .where((entry) => entry.value.rssi < 0) // Filter out invalid readings
        .map((entry) {
          final result = entry.value;
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.advertisementData.advName;
          return {
            'deviceId': entry.key,
            'deviceName': deviceName.isEmpty ? '(No Name)' : deviceName,
            'rssi': result.rssi,
            'isHaven': isHavenDevice(deviceName),
            'serviceUuids': result.advertisementData.serviceUuids.map((e) => e.toString()).toList(),
            'hasName': deviceName.isNotEmpty,
          };
        })
        .toList()
      ..sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));
  }

  void dispose() {
    stopScanning();
    _nearbyDeviceController.close();
  }
}

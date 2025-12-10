import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

class AddControllerNetworkScreen extends StatefulWidget {
  final String selectedLocation;

  const AddControllerNetworkScreen({
    super.key,
    required this.selectedLocation,
  });

  @override
  State<AddControllerNetworkScreen> createState() =>
      _AddControllerNetworkScreenState();
}

class _AddControllerNetworkScreenState
    extends State<AddControllerNetworkScreen> {
  String? _currentNetwork;
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _signalStrength = 4; // 0-4 bars, default to full
  int? _rssiValue; // Actual RSSI in dBm

  @override
  void initState() {
    super.initState();
    _getCurrentNetwork();
    // Refresh network every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshNetwork();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  IconData _getWifiIcon() {
    switch (_signalStrength) {
      case 0:
        return Icons.wifi_off;
      case 1:
        return Icons.wifi_1_bar;
      case 2:
        return Icons.wifi_2_bar;
      case 3:
        return Icons.wifi;
      case 4:
      default:
        return Icons.wifi;
    }
  }

  Future<void> _refreshNetwork() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      if (locationStatus.isGranted) {
        final info = NetworkInfo();
        final wifiName = await info.getWifiName();
        
        // Get actual signal strength using wifi_iot (Android)
        // or estimate for iOS
        int rssi = -50; // Default good signal
        int strength = 4;
        
        if (Platform.isAndroid) {
          try {
            final signalLevel = await WiFiForIoTPlugin.getCurrentSignalStrength();
            if (signalLevel != null) {
              rssi = signalLevel;
              strength = _rssiToStrength(rssi);
            }
          } catch (e) {
            debugPrint('Error getting signal strength: $e');
          }
        } else if (Platform.isIOS) {
          // iOS doesn't expose RSSI directly, estimate based on connection
          if (wifiName == null || wifiName.isEmpty) {
            strength = 0;
            rssi = -100;
          } else {
            // Connected, assume good signal (iOS limitation)
            strength = 4;
            rssi = -50;
          }
        }
        
        if (wifiName == null || wifiName.isEmpty) {
          strength = 0;
          rssi = -100;
        }
        
        if (mounted) {
          setState(() {
            _currentNetwork = wifiName?.replaceAll('"', '') ?? 'Unknown Network';
            _signalStrength = strength;
            _rssiValue = rssi;
          });
        }
      }
    } catch (e) {
      // Silently fail on refresh
      debugPrint('Error refreshing network: $e');
    }
  }

  /// Convert RSSI (dBm) to signal strength bars (0-4)
  int _rssiToStrength(int rssi) {
    if (rssi >= -50) return 4; // Excellent
    if (rssi >= -60) return 3; // Good
    if (rssi >= -70) return 2; // Fair
    if (rssi >= -80) return 1; // Weak
    return 0; // Poor/No signal
  }

  /// Get color based on signal quality
  /// Green = Excellent/Good, Orange = Fair, Red = Weak/Poor/Disconnected
  Color _getSignalColor() {
    if (_rssiValue == null) return Colors.red;
    if (!_isConnected()) return Colors.red;
    if (_rssiValue! >= -60) return Colors.green;   // Excellent & Good
    if (_rssiValue! >= -70) return Colors.orange;  // Fair
    return Colors.red;                              // Weak & Poor
  }

  /// Check if we're connected to a valid network
  bool _isConnected() {
    return _currentNetwork != null &&
        _currentNetwork!.isNotEmpty &&
        _currentNetwork != 'Unknown Network' &&
        _currentNetwork != 'Not connected to WiFi' &&
        _currentNetwork != 'Enable Location Services' &&
        _currentNetwork != 'Location permission denied' &&
        _currentNetwork != 'Location permission required' &&
        _currentNetwork != 'Unable to detect network';
  }

  Future<void> _getCurrentNetwork() async {
    try {
      // First check if location service is enabled
      final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentNetwork = 'Enable Location Services';
            _isLoading = false;
          });
        }
        return;
      }

      // Request location permission (required on iOS to access WiFi info)
      var locationStatus = await Permission.locationWhenInUse.status;
      
      if (locationStatus.isDenied) {
        locationStatus = await Permission.locationWhenInUse.request();
      }
      
      if (locationStatus.isGranted || locationStatus.isLimited) {
        final info = NetworkInfo();
        final wifiName = await info.getWifiName();
        debugPrint('WiFi Name returned: $wifiName');
        
        // Get signal strength
        int rssi = -50;
        int strength = 4;
        
        if (Platform.isAndroid) {
          try {
            final signalLevel = await WiFiForIoTPlugin.getCurrentSignalStrength();
            if (signalLevel != null) {
              rssi = signalLevel;
              strength = _rssiToStrength(rssi);
            }
          } catch (e) {
            debugPrint('Error getting initial signal strength: $e');
          }
        }
        
        if (wifiName == null || wifiName.isEmpty) {
          strength = 0;
          rssi = -100;
        }
        
        if (mounted) {
          setState(() {
            if (wifiName != null && wifiName.isNotEmpty) {
              // Remove quotes if present (iOS adds quotes around SSID)
              _currentNetwork = wifiName.replaceAll('"', '');
            } else {
              _currentNetwork = 'Not connected to WiFi';
            }
            _signalStrength = strength;
            _rssiValue = rssi;
            _isLoading = false;
          });
        }
      } else if (locationStatus.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _currentNetwork = 'Location permission denied';
            _isLoading = false;
          });
          // Optionally open settings
          openAppSettings();
        }
      } else {
        if (mounted) {
          setState(() {
            _currentNetwork = 'Location permission required';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting network: $e');
      if (mounted) {
        setState(() {
          _currentNetwork = 'Unable to detect network';
          _isLoading = false;
        });
      }
    }
  }

  void _onNext() {
    // TODO: Navigate to next step in device setup
    debugPrint('Next pressed with network: $_currentNetwork');
  }

  void _showManualNetworkDialog() {
    final networkNameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 5),
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter WiFi Network',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: networkNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Network Name',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.wifi,
                          color: Color(0xFFF57F20),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFF57F20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: Color(0xFFF57F20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFF57F20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            if (networkNameController.text.isNotEmpty) {
                              setState(() {
                                _currentNetwork = networkNameController.text;
                                _signalStrength = 4;
                                _rssiValue = -50;
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF57F20),
                          ),
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Controller',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your controller will be added to this network',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Network Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getSignalColor().withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getSignalColor().withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getSignalColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getWifiIcon(),
                        color: _getSignalColor(),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFF57F20),
                                  ),
                                )
                              : Text(
                                  _isConnected()
                                      ? _currentNetwork!
                                      : 'Connect to network',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isConnected() ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isConnected() ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _isConnected() ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Choose different network option
              TextButton(
                onPressed: _showManualNetworkDialog,
                child: const Text(
                  'Choose different WiFi network',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF57F20),
                  ),
                ),
              ),

              const Spacer(),

              // Next Button
              FilledButton(
                onPressed: _isLoading ? null : _onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF57F20).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(
                      color: Color(0xFFF57F20),
                      width: 2,
                    ),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

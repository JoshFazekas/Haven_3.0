import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haven/widgets/location_header.dart';
import 'package:haven/widgets/nearby_device_popup.dart';
import 'package:haven/widgets/device_control_card.dart';
import 'package:haven/widgets/light_zone_card.dart';
import 'package:haven/core/services/bluetooth_scan_service.dart';
import 'package:haven/core/services/device_service.dart';
import 'package:lottie/lottie.dart';

// Import threshold constant
const int kNearbyRssiThreshold = -50;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  AnimationController? _lottieController;
  AnimationController? _pullController;
  AnimationController? _fadeController;
  double _pullDistance = 0;
  bool _isRefreshing = false;
  double _opacity = 0;
  static const double _maxPullDistance = 100;
  static const double _triggerDistance = 70;

  // Tab navigation state
  int _selectedTabIndex = 0;
  AnimationController? _lightsTabAnimController;
  AnimationController? _scheduleTabAnimController;
  AnimationController? _scenesTabAnimController;
  AnimationController? _lightsLoadInController;
  AnimationController? _scheduleLoadInController;
  AnimationController? _scenesLoadInController;
  bool _hasLoadedDevices = false; // Track if devices were just loaded

  // Bluetooth scanning state
  final BluetoothScanService _bluetoothService = BluetoothScanService();
  StreamSubscription<NearbyHavenDevice>? _nearbyDeviceSubscription;
  bool _showNearbyDevicePopup = false;
  NearbyHavenDevice? _nearbyDevice;

  // Debug state
  final DeviceService _deviceService = DeviceService();
  Map<String, dynamic>? _debugResponse;
  bool _isLoadingDebug = false;
  String? _debugError;

  // Devices list parsed from API response
  List<DeviceController> _devices = [];

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _lightsTabAnimController = AnimationController(vsync: this);
    _scheduleTabAnimController = AnimationController(vsync: this);
    _scenesTabAnimController = AnimationController(vsync: this);
    _lightsLoadInController = AnimationController(vsync: this);
    _scheduleLoadInController = AnimationController(vsync: this);
    _scenesLoadInController = AnimationController(vsync: this);
    
    // Reset _hasLoadedDevices after load-in animations complete
    _lightsLoadInController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _hasLoadedDevices = false;
        });
      }
    });

    // Start Bluetooth scanning and listen for nearby devices
    _startBluetoothScanning();
  }

  Future<void> _startBluetoothScanning() async {
    // Listen for nearby device notifications
    _nearbyDeviceSubscription = _bluetoothService.nearbyDeviceStream.listen((
      device,
    ) {
      if (mounted && !_showNearbyDevicePopup) {
        // Trigger haptic feedback when device is detected
        HapticFeedback.heavyImpact();

        setState(() {
          _nearbyDevice = device;
          _showNearbyDevicePopup = true;
        });
      }
    });

    // Start scanning
    await _bluetoothService.startScanning();
  }

  void _dismissNearbyDevicePopup() {
    setState(() {
      _showNearbyDevicePopup = false;
      _nearbyDevice = null;
    });
    // Reset the flag after a delay so we can detect new devices
    Future.delayed(const Duration(seconds: 10), () {
      _bluetoothService.resetPopupFlag();
    });
  }

  void _onConnectToDevice() {
    // TODO: Navigate to add device flow with the detected device
    debugPrint('Connect to device: ${_nearbyDevice?.deviceName}');
    _dismissNearbyDevicePopup();
  }

  Future<void> _fetchDevicesByLocation() async {
    setState(() {
      _isLoadingDebug = true;
      _debugError = null;
    });

    try {
      // Using locationId 28791 for testing
      final response = await _deviceService.getDevicesByLocation(28791);

      // Parse devices from the response body
      List<DeviceController> parsedDevices = [];
      if (response['body'] != null && response['body'] is List) {
        parsedDevices = (response['body'] as List)
            .map(
              (json) => DeviceController.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      setState(() {
        _debugResponse = response;
        _devices = parsedDevices;
        _isLoadingDebug = false;
        // Trigger load-in animations if devices were just loaded
        if (parsedDevices.isNotEmpty) {
          _hasLoadedDevices = true;
        }
      });
      debugPrint('Devices response: $response');
      debugPrint('Parsed ${parsedDevices.length} devices');
    } catch (e) {
      setState(() {
        _debugError = e.toString();
        _devices = [];
        _isLoadingDebug = false;
      });
      debugPrint('Error fetching devices: $e');
    }
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Debug Response',
          style: TextStyle(color: Colors.white, fontFamily: 'SpaceMono'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingDebug)
                const Center(child: CircularProgressIndicator())
              else if (_debugError != null)
                Text(
                  'Error: $_debugError',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                  ),
                )
              else if (_debugResponse != null)
                Text(
                  const JsonEncoder.withIndent('  ').convert(_debugResponse),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                  ),
                )
              else
                const Text(
                  'No data yet. Pull to refresh to fetch devices.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              if (_debugResponse != null) {
                Clipboard.setData(
                  ClipboardData(
                    text: const JsonEncoder.withIndent(
                      '  ',
                    ).convert(_debugResponse),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            child: const Text(
              'Copy',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lottieController?.dispose();
    _pullController?.dispose();
    _fadeController?.dispose();
    _lightsTabAnimController?.dispose();
    _scheduleTabAnimController?.dispose();
    _scenesTabAnimController?.dispose();
    _lightsLoadInController?.dispose();
    _scheduleLoadInController?.dispose();
    _scenesLoadInController?.dispose();
    _nearbyDeviceSubscription?.cancel();
    _bluetoothService.stopScanning();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;

    setState(() {
      _pullDistance += details.delta.dy;
      _pullDistance = _pullDistance.clamp(0, _maxPullDistance);
      // Update opacity based on pull distance (animation stays at frame 0)
      _opacity = (_pullDistance / _triggerDistance).clamp(0.0, 1.0);
    });
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_isRefreshing) return;

    if (_pullDistance >= _triggerDistance) {
      // Trigger refresh
      setState(() {
        _isRefreshing = true;
        _opacity = 1.0;
      });

      // Play the animation once from the beginning
      _lottieController?.reset();
      await _lottieController?.forward();

      // Fetch devices on refresh
      await _fetchDevicesByLocation();
      debugPrint('Refreshed!');

      if (mounted) {
        // Fade out the animation
        _fadeController?.reset();
        _fadeController?.forward();
        _fadeController?.addListener(_fadeOutListener);
      }
    } else {
      // Not enough pull, snap back
      _snapBack();
    }
  }

  void _fadeOutListener() {
    if (!mounted) {
      _fadeController?.removeListener(_fadeOutListener);
      return;
    }

    setState(() {
      _opacity = 1.0 - _fadeController!.value;
      _pullDistance = _maxPullDistance * (1.0 - _fadeController!.value);
    });

    if (_fadeController!.isCompleted) {
      _fadeController!.removeListener(_fadeOutListener);
      setState(() {
        _isRefreshing = false;
        _pullDistance = 0;
        _opacity = 0;
        _lottieController?.reset();
      });
    }
  }

  void _snapBack() {
    if (_pullController == null) return;

    final startDistance = _pullDistance;
    final startOpacity = _opacity;

    _pullController!.reset();

    void listener() {
      if (!mounted) {
        _pullController?.removeListener(listener);
        return;
      }

      setState(() {
        _pullDistance = startDistance * (1 - _pullController!.value);
        _opacity = startOpacity * (1 - _pullController!.value);
      });

      if (_pullController!.isCompleted) {
        _pullController!.removeListener(listener);
        _pullDistance = 0;
        _opacity = 0;
      }
    }

    _pullController!.addListener(listener);
    _pullController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _devices.isNotEmpty
          ? const Color(0xFF2A2A2A)
          : null,
      body: Stack(
        children: [
          // Background image for empty state (only show when no devices)
          if (_devices.isEmpty)
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/spacey.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          // Gesture detector for custom pull-to-refresh (behind main content)
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Shooting star animation that pulls down from behind header
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, _pullDistance - 80),
                  child: Opacity(
                    opacity: _opacity,
                    child: Transform.rotate(
                      angle: 3.926991, // 225 degrees in radians (45 + 180)
                      child: Lottie.asset(
                        'assets/animations/shootingstar.json',
                        controller: _lottieController,
                        width: 80,
                        height: 80,
                        onLoaded: (composition) {
                          _lottieController?.duration = composition.duration;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Main content - on top so button is clickable
          Column(
            children: [
              // Header ribbon - extends to top of screen
              Container(
                color: _devices.isNotEmpty
                    ? const Color(0xFF1C1C1C)
                    : null,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26.0,
                      vertical: 16.0,
                    ),
                    child: LocationHeader(
                      locationName: 'Home',
                      onLocationTap: () {
                        // TODO: Show location picker
                        debugPrint('Location tapped');
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  behavior: HitTestBehavior.translucent,
                  child: _devices.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26.0),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "It's a little empty here..",
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Add your first controller to get started",
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF828282),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _buildLightZoneCards().length,
                                itemBuilder: (context, index) {
                                  return _buildLightZoneCards()[index];
                                },
                              ),
                            ),
                            DeviceControlCard(
                              devices: _devices,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
              ),
              ],
            ),

          // Nearby device popup overlay
          if (_showNearbyDevicePopup && _nearbyDevice != null)
            NearbyDevicePopup(
              device: _nearbyDevice!,
              onDismiss: _dismissNearbyDevicePopup,
              onConnect: _onConnectToDevice,
            ),

          // Debug button - shows API response
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'debug_button',
              backgroundColor: _debugResponse != null
                  ? Colors.greenAccent.withOpacity(0.8)
                  : _debugError != null
                  ? Colors.redAccent.withOpacity(0.8)
                  : Colors.grey.withOpacity(0.5),
              onPressed: _showDebugDialog,
              child: _isLoadingDebug
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bug_report, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _devices.isEmpty
          ? null
          : Container(
              color: const Color(0xFF2A2A2A),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 46.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedTabItem(
                        index: 0,
                        animationPath: 'assets/animations/lighttabtap.json',
                        loadInAnimationPath: 'assets/animations/loadinlighttab.json',
                        staticAssetPath: 'assets/images/lighttab.png',
                        controller: _lightsTabAnimController,
                        loadInController: _lightsLoadInController,
                        label: 'Lights',
                      ),
                      _buildAnimatedTabItem(
                        index: 1,
                        animationPath: 'assets/animations/scenetap.json',
                        loadInAnimationPath: 'assets/animations/scenereveal.json',
                        staticAssetPath: 'assets/images/scenestab.png',
                        controller: _scenesTabAnimController,
                        loadInController: _scenesLoadInController,
                        label: 'Scenes',
                        iconScale: 1.14,
                      ),
                      _buildAnimatedTabItem(
                        index: 2,
                        animationPath: 'assets/animations/scheduletab.json',
                        loadInAnimationPath: 'assets/animations/loadinschedule.json',
                        staticAssetPath: 'assets/images/scheduletap.png',
                        controller: _scheduleTabAnimController,
                        loadInController: _scheduleLoadInController,
                        label: 'Schedule',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Builds individual light/zone cards from all devices
  List<Widget> _buildLightZoneCards() {
    final List<Widget> cards = [];
    
    debugPrint('=== Building light zone cards ===');
    debugPrint('Total devices: ${_devices.length}');
    
    for (int deviceIndex = 0; deviceIndex < _devices.length; deviceIndex++) {
      final device = _devices[deviceIndex];
      debugPrint('Device $deviceIndex: ${device.controllerTypeName}');
      debugPrint('Light names: "${device.lightNames}"');
      
      if (device.lightNames.isNotEmpty) {
        final lights = device.lightNames.split(',');
        debugPrint('Split into ${lights.length} lights: $lights');
        
        for (int i = 0; i < lights.length; i++) {
          final lightName = lights[i].trim();
          if (lightName.isNotEmpty) {
            debugPrint('Creating card for light: "$lightName"');
            cards.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LightZoneCard(
                  channelName: 'Channel ${i + 1}',
                  lightName: lightName,
                  controllerTypeName: device.controllerTypeName,
                  // TODO: Pass actual IDs from API response
                  lightId: 100 + i, // Example light ID
                  locationId: 27040, // Example location ID
                  // zoneId: null, // Add zone ID if available
                ),
              ),
            );
          }
        }
      } else {
        debugPrint('Device has no light names');
      }
    }
    
    debugPrint('Total cards created: ${cards.length}');
    debugPrint('=== End building light zone cards ===');
    return cards;
  }

  Widget _buildAnimatedTabItem({
    required int index,
    required String animationPath,
    required String staticAssetPath,
    required AnimationController? controller,
    required String label,
    String? loadInAnimationPath,
    AnimationController? loadInController,
    double iconSize = 50,
    double iconScale = 1.0,
  }) {
    final isSelected = _selectedTabIndex == index;
    final shouldPlayLoadIn = _hasLoadedDevices && loadInAnimationPath != null && loadInController != null;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTabIndex = index;
        });
        debugPrint('Tab $index tapped: $label');
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Transform.scale(
              scale: iconScale,
              child: shouldPlayLoadIn
                ? Lottie.asset(
                    loadInAnimationPath,
                    controller: loadInController,
                    repeat: false,
                    onLoaded: (composition) {
                      loadInController.duration = composition.duration;
                      loadInController.reset();
                      loadInController.forward();
                    },
                  )
                : isSelected
                    ? Lottie.asset(
                        animationPath,
                        controller: controller,
                        repeat: false,
                        onLoaded: (composition) {
                          controller?.duration = composition.duration;
                          // Play the animation once when loaded
                          controller?.reset();
                          controller?.forward();
                        },
                      )
                    : Image.asset(
                        staticAssetPath,
                        color: const Color(0xFF6E6E6E),
                      ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF6E6E6E),
            ),
          ),
        ],
      ),
    );
  }
}

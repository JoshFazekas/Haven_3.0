import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haven/widgets/location_header.dart';
import 'package:haven/widgets/nearby_device_popup.dart';
import 'package:haven/core/services/bluetooth_scan_service.dart';
import 'package:lottie/lottie.dart';

// Import threshold constant
const int kNearbyRssiThreshold = -50;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  AnimationController? _lottieController;
  AnimationController? _pullController;
  AnimationController? _fadeController;
  double _pullDistance = 0;
  bool _isRefreshing = false;
  double _opacity = 0;
  static const double _maxPullDistance = 100;
  static const double _triggerDistance = 70;

  // Bluetooth scanning state
  final BluetoothScanService _bluetoothService = BluetoothScanService();
  StreamSubscription<NearbyHavenDevice>? _nearbyDeviceSubscription;
  bool _showNearbyDevicePopup = false;
  NearbyHavenDevice? _nearbyDevice;

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

    // Start Bluetooth scanning and listen for nearby devices
    _startBluetoothScanning();
  }

  Future<void> _startBluetoothScanning() async {
    // Listen for nearby device notifications
    _nearbyDeviceSubscription = _bluetoothService.nearbyDeviceStream.listen((device) {
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

  @override
  void dispose() {
    _lottieController?.dispose();
    _pullController?.dispose();
    _fadeController?.dispose();
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
      
      // TODO: Add your refresh logic here
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
      body: Stack(
        children: [
          // Background image for empty state
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationHeader(
                    locationName: 'Home',
                    onLocationTap: () {
                      // TODO: Show location picker
                      debugPrint('Location tapped');
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      behavior: HitTestBehavior.translucent,
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
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nearby device popup overlay
          if (_showNearbyDevicePopup && _nearbyDevice != null)
            NearbyDevicePopup(
              device: _nearbyDevice!,
              onDismiss: _dismissNearbyDevicePopup,
              onConnect: _onConnectToDevice,
            ),
          

        ],
      ),
    );
  }
}

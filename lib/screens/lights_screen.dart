import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haven/widgets/location_header.dart';
import 'package:haven/widgets/nearby_device_popup.dart';
import 'package:haven/widgets/device_control_card.dart';
import 'package:haven/widgets/light_zone_card.dart';
import 'package:haven/widgets/image_view_content.dart';
import 'package:haven/core/services/bluetooth_scan_service.dart';
import 'package:haven/core/services/location_data_service.dart';
import 'package:haven/screens/holiday_presets_screen.dart';
import 'package:lottie/lottie.dart';

// Import threshold constant
const int kNearbyRssiThreshold = -50;

class LightsScreen extends StatefulWidget {
  const LightsScreen({super.key});

  @override
  State<LightsScreen> createState() => _LightsScreenState();
}

class _LightsScreenState extends State<LightsScreen>
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

  // Location data service
  final LocationDataService _locationDataService = LocationDataService();

  // Devices list parsed from API response
  List<DeviceController> _devices = [];

  // Selected location state
  String _selectedLocation = 'Home';

  // Global lights on/off state (null = no forced state, true = all on, false = all off)
  bool? _forceAllLightsState;

  // Image view toggle state
  bool _isImageViewActive = false;

  // Channel placement mode state
  bool _isChannelPlacementMode = false;
  int _selectedChannelIndex = 0;

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

    // Listen for location data changes and rebuild device list
    _locationDataService.addListener(_onLocationDataChanged);

    // Populate devices from location data service (already loaded at login)
    _populateDevicesFromLocationData();

    // Start Bluetooth scanning and listen for nearby devices
    _startBluetoothScanning();
  }

  /// Called whenever LocationDataService notifies listeners (new data loaded).
  void _onLocationDataChanged() {
    if (mounted) {
      _populateDevicesFromLocationData();
    }
  }

  /// Build the [_devices] list from the data in [LocationDataService].
  /// Each controller becomes a [DeviceController] and we attach the
  /// matching light names (from zonesAndLights) as a comma-separated string.
  void _populateDevicesFromLocationData() {
    final service = _locationDataService;
    if (!service.hasData) return;

    final List<DeviceController> devices = [];

    for (final controller in service.controllers) {
      // Collect the visible light names that belong to this controller.
      // The API response ties lights to controllers by matching the
      // controller MAC's last 4 characters in the light name prefix.
      // We do a simple prefix check: "XXXX CHANNEL-N" where XXXX is the
      // last 4 chars of the MAC address.
      final last4 = controller.macAddress.length >= 4
          ? controller.macAddress.substring(controller.macAddress.length - 4).toUpperCase()
          : controller.macAddress.toUpperCase();

      final matchingLights = service.allLights.where((light) {
        return light.name.toUpperCase().startsWith(last4);
      }).toList();

      // If no lights matched by prefix, include ALL visible lights for this controller
      // (fallback for controller types like K SERIES / Stratus where naming differs)
      final lightsForController = matchingLights.isNotEmpty
          ? matchingLights
          : <LightZoneItem>[];

      final lightNames = lightsForController
          .where((l) => !l.isHidden)
          .map((l) => l.name)
          .join(',');

      devices.add(DeviceController(
        controllerId: controller.controllerId,
        name: controller.name,
        deviceId: controller.macAddress,
        controllerTypeName: controller.typeName,
        firmwareVersion: '',
        isConnected: true, // assume connected from API
        lightNames: lightNames,
      ));
    }

    // If there are lights that didn't match any controller (e.g. K SERIES, Stratus),
    // group them into virtual DeviceController entries by their light type.
    final assignedLightNames = devices.expand((d) => d.lightNames.split(',')).toSet();
    final unassignedLights = service.visibleLights.where(
      (l) => !assignedLightNames.contains(l.name),
    ).toList();

    if (unassignedLights.isNotEmpty) {
      // Group by type
      final Map<String, List<LightZoneItem>> grouped = {};
      for (final light in unassignedLights) {
        grouped.putIfAbsent(light.type, () => []).add(light);
      }

      for (final entry in grouped.entries) {
        devices.add(DeviceController(
          controllerId: 0,
          name: entry.key,
          deviceId: '',
          controllerTypeName: entry.key,
          firmwareVersion: '',
          isConnected: true,
          lightNames: entry.value.map((l) => l.name).join(','),
        ));
      }
    }

    setState(() {
      _devices = devices;
      _hasLoadedDevices = true;
    });

    debugPrint('LightsScreen: Populated ${devices.length} device controllers from LocationDataService');
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
    if (!mounted) return;

    setState(() {
      _showNearbyDevicePopup = false;
      _nearbyDevice = null;
    });
    // Reset the flag after a delay so we can detect new devices
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _bluetoothService.resetPopupFlag();
      }
    });
  }

  void _onConnectToDevice() {
    // TODO: Navigate to add device flow with the detected device
    debugPrint('Connect to device: ${_nearbyDevice?.deviceName}');
    _dismissNearbyDevicePopup();
  }

  @override
  void dispose() {
    _locationDataService.removeListener(_onLocationDataChanged);
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
    if (_isRefreshing || !mounted) return;

    setState(() {
      _pullDistance += details.delta.dy;
      _pullDistance = _pullDistance.clamp(0, _maxPullDistance);
      // Update opacity based on pull distance (animation stays at frame 0)
      _opacity = (_pullDistance / _triggerDistance).clamp(0.0, 1.0);
    });
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_isRefreshing || !mounted) return;

    if (_pullDistance >= _triggerDistance) {
      // Trigger refresh
      if (!mounted) return;
      setState(() {
        _isRefreshing = true;
        _opacity = 1.0;
      });

      // Play the animation and fetch data in parallel (not waiting for animation). 
      _lottieController?.reset();
      _lottieController?.forward();

      // TODO: Fetch devices when device service is re-implemented
      Future.delayed(const Duration(milliseconds: 500)).then((_) {
        debugPrint('Refreshed!');
        if (mounted) {
          // Fade out the animation after data is loaded
          _fadeController?.reset();
          _fadeController?.forward();
          _fadeController?.addListener(_fadeOutListener);
        }
      });
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
        if (mounted) {
          setState(() {
            _pullDistance = 0;
            _opacity = 0;
          });
        }
      }
    }

    _pullController!.addListener(listener);
    _pullController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _devices.isNotEmpty ? const Color(0xFF2A2A2A) : null,
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
          // Main content - on top so button is clickable
          Column(
            children: [
              // Header ribbon - extends to top of screen
              Container(
                color: _devices.isNotEmpty ? const Color(0xFF1C1C1C) : null,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26.0,
                      vertical: 16.0,
                    ),
                    child: LocationHeader(
                      locationName: _selectedLocation,
                      onLocationTap: () {
                        // Location dropdown handled by LocationHeader
                        debugPrint('Location tapped');
                      },
                      onLocationSelected: (String location) {
                        setState(() {
                          _selectedLocation = location;
                        });
                        debugPrint('Location selected: $location');
                        // TODO: Map location name to locationId and call
                        // _locationDataService.switchLocation(newLocationId);
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
                      : _buildTabContent(),
                ),
              ),
            ],
          ),

          // Shooting star animation that pulls down - on top of content
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: IgnorePointer(
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

          // Nearby device popup overlay
          if (_showNearbyDevicePopup && _nearbyDevice != null)
            NearbyDevicePopup(
              device: _nearbyDevice!,
              onDismiss: _dismissNearbyDevicePopup,
              onConnect: _onConnectToDevice,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 46.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedTabItem(
                        index: 0,
                        animationPath: 'assets/animations/lighttabtap.json',
                        loadInAnimationPath:
                            'assets/animations/loadinlighttab.json',
                        staticAssetPath: 'assets/images/lighttab.png',
                        controller: _lightsTabAnimController,
                        loadInController: _lightsLoadInController,
                        label: 'Lights',
                      ),
                      _buildAnimatedTabItem(
                        index: 1,
                        animationPath: 'assets/animations/scenetap.json',
                        loadInAnimationPath:
                            'assets/animations/scenereveal.json',
                        staticAssetPath: 'assets/images/scenestab.png',
                        controller: _scenesTabAnimController,
                        loadInController: _scenesLoadInController,
                        label: 'Scenes',
                        iconScale: 1.14,
                      ),
                      _buildAnimatedTabItem(
                        index: 2,
                        animationPath: 'assets/animations/scheduletab.json',
                        loadInAnimationPath:
                            'assets/animations/loadinschedule.json',
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

  /// Builds the channel carousel for placement mode
  Widget _buildChannelCarousel(List<String> channelNames) {
    return Center(
      child: Container(
        width: 385,
        height: 101,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: channelNames.isEmpty
            ? Center(
                child: Text(
                  'No channels available',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              )
            : PageView.builder(
                controller: PageController(
                  viewportFraction: 0.25,
                  initialPage: _selectedChannelIndex,
                ),
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedChannelIndex = index;
                  });
                },
                itemCount: channelNames.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedChannelIndex;
                  final channelName = channelNames[index];

                  return AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.0 : 0.7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4842A).withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4842A)
                                  : Colors.grey,
                              width: isSelected ? 3 : 2,
                            ),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: isSelected
                                ? const Color(0xFFD4842A)
                                : Colors.white.withOpacity(0.6),
                            size: 28,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            channelName,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Builds the content for the currently selected tab
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Lights tab
        // Build list of channel names from all devices
        final List<String> channelNames = [];
        for (final device in _devices) {
          if (device.lightNames.isNotEmpty) {
            final lights = device.lightNames.split(',');
            for (int i = 0; i < lights.length; i++) {
              final lightName = lights[i].trim();
              if (lightName.isNotEmpty) {
                channelNames.add(lightName);
              }
            }
          }
        }

        return Column(
          children: [
            Expanded(
              child: _isImageViewActive
                  ? ImageViewContent(
                      channels: channelNames,
                      isChannelPlacementMode: _isChannelPlacementMode,
                      selectedChannelIndex: _selectedChannelIndex,
                      onChannelSelected: (index) {
                        setState(() {
                          _selectedChannelIndex = index;
                        });
                      },
                      onEnterPlacementMode: () {
                        setState(() {
                          _isChannelPlacementMode = true;
                        });
                      },
                      onExitPlacementMode: () {
                        setState(() {
                          _isChannelPlacementMode = false;
                        });
                      },
                    )
                  : Builder(
                      builder: (context) {
                        final cards = _buildLightZoneCards();
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            return cards[index];
                          },
                        );
                      },
                    ),
            ),
            // Show channel carousel in placement mode, otherwise DeviceControlCard
            if (_isChannelPlacementMode)
              _buildChannelCarousel(channelNames)
            else
              DeviceControlCard(
              devices: _devices,
              isImageViewActive: _isImageViewActive,
              onImageViewTap: () {
                setState(() {
                  _isImageViewActive = !_isImageViewActive;
                });
              },
              onAllLightsOn: () {
                setState(() {
                  _forceAllLightsState = true;
                });
                // Reset after a short delay so future toggles work
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _forceAllLightsState = null;
                    });
                  }
                });
              },
              onAllLightsOff: () {
                setState(() {
                  _forceAllLightsState = false;
                });
                // Reset after a short delay so future toggles work
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _forceAllLightsState = null;
                    });
                  }
                });
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      case 1: // Scenes tab
        return Stack(
          children: [
            // Add Scene button in top left
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  debugPrint('Add Scene tapped');
                  // TODO: Navigate to add scene
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC56A21),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Add Scene',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Centered content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No Scenes',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HolidayPresetsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Presets',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 2: // Schedule tab
        return const Center(
          child: Text(
            'Schedule',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds individual light/zone cards from LocationDataService data.
  /// First renders zone cards, then individual visible light cards.
  List<Widget> _buildLightZoneCards() {
    final List<Widget> cards = [];
    final service = _locationDataService;
    final locationId = service.selectedLocationId;

    debugPrint('=== Building light zone cards ===');

    // 1. Add zone cards
    for (final zone in service.zones) {
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LightZoneCard(
            channelName: 'Zone ${zone.zoneNumber}',
            lightName: zone.name,
            controllerTypeName: zone.displayType,
            locationId: locationId,
            forceIsOn: _forceAllLightsState,
            initialIsOn: zone.isCurrentlyOn,
            initialBrightness: zone.brightnessPercent.toDouble(),
          ),
        ),
      );
    }

    // 2. Add visible light cards
    for (final light in service.visibleLights) {
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LightZoneCard(
            channelName: 'Channel ${light.zoneNumber}',
            lightName: light.name,
            controllerTypeName: light.displayType,
            locationId: locationId,
            forceIsOn: _forceAllLightsState,
            initialIsOn: light.isCurrentlyOn,
            initialBrightness: light.brightnessPercent.toDouble(),
          ),
        ),
      );
    }

    // Fallback: if LocationDataService has no data, use the old _devices list
    if (cards.isEmpty) {
      for (int deviceIndex = 0; deviceIndex < _devices.length; deviceIndex++) {
        final device = _devices[deviceIndex];
        if (device.lightNames.isNotEmpty) {
          final lights = device.lightNames.split(',');
          for (int i = 0; i < lights.length; i++) {
            final lightName = lights[i].trim();
            if (lightName.isNotEmpty) {
              cards.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LightZoneCard(
                    channelName: 'Channel ${i + 1}',
                    lightName: lightName,
                    controllerTypeName: device.controllerTypeName,
                    locationId: locationId,
                    forceIsOn: _forceAllLightsState,
                  ),
                ),
              );
            }
          }
        }
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
    final shouldPlayLoadIn =
        _hasLoadedDevices &&
        isSelected &&
        loadInAnimationPath != null &&
        loadInController != null;

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

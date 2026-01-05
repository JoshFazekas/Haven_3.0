import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Represents a device/controller returned from the API
class DeviceController {
  final int controllerId;
  final String name;
  final String deviceId;
  final String controllerTypeName;
  final String firmwareVersion;
  final bool isConnected;
  final String lightNames;

  DeviceController({
    required this.controllerId,
    required this.name,
    required this.deviceId,
    required this.controllerTypeName,
    required this.firmwareVersion,
    required this.isConnected,
    required this.lightNames,
  });

  factory DeviceController.fromJson(Map<String, dynamic> json) {
    return DeviceController(
      controllerId: json['controllerId'] ?? 0,
      name: json['name'] ?? '',
      deviceId: json['deviceId'] ?? '',
      controllerTypeName: json['controllerTypeName'] ?? '',
      firmwareVersion: json['firmwareVersion'] ?? '',
      isConnected: json['isConnected'] ?? false,
      lightNames: json['lightNames'] ?? '',
    );
  }

  /// Get the number of zones/channels from lightNames
  int get zoneCount {
    if (lightNames.isEmpty) return 0;
    return lightNames.split(',').length;
  }
}

/// A control card for managing all lights in a zone
class DeviceControlCard extends StatefulWidget {
  final List<DeviceController> devices;
  final VoidCallback? onAllLightsOn;
  final VoidCallback? onAllLightsOff;

  const DeviceControlCard({
    super.key,
    required this.devices,
    this.onAllLightsOn,
    this.onAllLightsOff,
  });

  @override
  State<DeviceControlCard> createState() => _DeviceControlCardState();
}

class _DeviceControlCardState extends State<DeviceControlCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: double.infinity,
        height: 101,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1D1D1D),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            // Left side content - title and buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ALL LIGHTS / ZONES',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildButton('OFF', isOn: false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildButton('ON', isOn: true),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ],
            ),
            // Right side - icon buttons centered vertically
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImageIconButton(
                    imagePath: 'assets/images/colors.png',
                    backgroundColor: const Color(0xFF2A2A2A),
                    borderColor: const Color(0xFF9E9E9E),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      debugPrint('Color palette tapped');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.wb_sunny_outlined,
                    backgroundColor: const Color(0xFF3D2508),
                    borderColor: const Color(0xFFD4842A),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      debugPrint('Brightness tapped');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildImageIconButton(
                    imagePath: 'assets/images/imageview.png',
                    backgroundColor: const Color(0xFF0D1F33),
                    borderColor: const Color(0xFF3A7BD5),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      debugPrint('Image view tapped');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, {required bool isOn}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (isOn) {
          widget.onAllLightsOn?.call();
        } else {
          widget.onAllLightsOff?.call();
        }
        debugPrint('$label tapped - turning all lights ${isOn ? "ON" : "OFF"}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF484848),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3D3D), width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color backgroundColor = const Color(0xFF484848),
    Color borderColor = const Color(0xFF3D3D3D),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildImageIconButton({
    required String imagePath,
    required VoidCallback onTap,
    Color backgroundColor = const Color(0xFF484848),
    Color borderColor = const Color(0xFF3D3D3D),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(imagePath, width: 24, height: 24),
      ),
    );
  }
}

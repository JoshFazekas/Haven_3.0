import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gradient_border_painter.dart';

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
  final VoidCallback? onImageViewTap;
  final VoidCallback? onColorPaletteTap;
  final bool isImageViewActive;

  /// Current state colors from each light/zone card.
  /// Used to paint a gradient border that reflects each light's color.
  final List<Color> lightColors;

  const DeviceControlCard({
    super.key,
    required this.devices,
    this.onAllLightsOn,
    this.onAllLightsOff,
    this.onImageViewTap,
    this.onColorPaletteTap,
    this.isImageViewActive = false,
    this.lightColors = const [],
  });

  @override
  State<DeviceControlCard> createState() => _DeviceControlCardState();
}

class _DeviceControlCardState extends State<DeviceControlCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderAnimController;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      vsync: this,
      duration: AllLightsZonesStyle.gradientSpinDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasColors = widget.lightColors.isNotEmpty;

    return Padding(
      padding: AllLightsZonesStyle.cardMargin,
      child: hasColors
          ? AnimatedBuilder(
              animation: _borderAnimController,
              builder: (context, child) {
                return CustomPaint(
                  foregroundPainter: GradientBorderPainter(
                    colors: widget.lightColors,
                    animationValue: _borderAnimController.value,
                  ),
                  child: child,
                );
              },
              child: _buildCardContent(),
            )
          : _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    return Container(
      width: double.infinity,
      height: AllLightsZonesStyle.cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AllLightsZonesStyle.cardBorderRadius,
        ),
        color: AllLightsZonesStyle.cardBackgroundColor,
      ),
      padding: AllLightsZonesStyle.cardPadding,
      child: Stack(
        children: [
          // Left side content - title and buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ALL LIGHTS / ZONES',
                style: AllLightsZonesStyle.titleStyle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 1, child: _buildButton('OFF', isOn: false)),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _buildButton('ON', isOn: true)),
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
                  backgroundColor: AllLightsZonesStyle.colorPaletteBackground,
                  borderColor: AllLightsZonesStyle.colorPaletteBorder,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onColorPaletteTap?.call();
                    debugPrint('Color palette tapped');
                  },
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.wb_sunny_outlined,
                  backgroundColor: AllLightsZonesStyle.brightnessBackground,
                  borderColor: AllLightsZonesStyle.brightnessBorder,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    debugPrint('Brightness tapped');
                  },
                ),
                const SizedBox(width: 8),
                _buildImageIconButton(
                  imagePath: 'assets/images/imageview.png',
                  backgroundColor: widget.isImageViewActive
                      ? AllLightsZonesStyle.imageViewActiveBackground
                      : AllLightsZonesStyle.imageViewInactiveBackground,
                  borderColor: AllLightsZonesStyle.imageViewBorder,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onImageViewTap?.call();
                    debugPrint('Image view tapped');
                  },
                ),
              ],
            ),
          ),
        ],
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
        padding: AllLightsZonesStyle.buttonPadding,
        decoration: BoxDecoration(
          color: AllLightsZonesStyle.buttonBackgroundColor,
          borderRadius: BorderRadius.circular(
            AllLightsZonesStyle.buttonBorderRadius,
          ),
          border: Border.all(
            color: AllLightsZonesStyle.buttonBorderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AllLightsZonesStyle.buttonTextStyle,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color backgroundColor = AllLightsZonesStyle.buttonBackgroundColor,
    Color borderColor = AllLightsZonesStyle.buttonBorderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AllLightsZonesStyle.iconButtonPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            AllLightsZonesStyle.iconButtonRadius,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: AllLightsZonesStyle.iconSize,
        ),
      ),
    );
  }

  Widget _buildImageIconButton({
    required String imagePath,
    required VoidCallback onTap,
    Color backgroundColor = AllLightsZonesStyle.buttonBackgroundColor,
    Color borderColor = AllLightsZonesStyle.buttonBorderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AllLightsZonesStyle.iconButtonPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            AllLightsZonesStyle.iconButtonRadius,
          ),
        ),
        child: Image.asset(
          imagePath,
          width: AllLightsZonesStyle.iconSize,
          height: AllLightsZonesStyle.iconSize,
        ),
      ),
    );
  }
}

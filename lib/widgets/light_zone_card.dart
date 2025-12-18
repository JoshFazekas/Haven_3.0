import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/colors_tab_view.dart';

/// A card displaying a single light/zone with channel name and light name
class LightZoneCard extends StatefulWidget {
  final String channelName;
  final String lightName;
  final String? controllerTypeName;
  final int? lightId;
  final int? zoneId;
  final int? locationId;

  const LightZoneCard({
    super.key,
    required this.channelName,
    required this.lightName,
    this.controllerTypeName,
    this.lightId,
    this.zoneId,
    this.locationId,
  });

  @override
  State<LightZoneCard> createState() => _LightZoneCardState();
}

class _LightZoneCardState extends State<LightZoneCard> {
  bool _isOn = false;
  Color _selectedColor = Colors.white; // Store the selected color

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onToggleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOn = !_isOn;
    });
    debugPrint('Toggle tapped for ${widget.lightName}: $_isOn');
  }

  void _openColorPalette() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorsTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          locationId: widget.locationId,
          onColorSelected: (Color color, bool isOn) {
            // Optimistically update the UI with the new color and state
            setState(() {
              _selectedColor = color;
              _isOn = isOn;
            });
            debugPrint('Light ${widget.lightName} updated: Color=$color, IsOn=$isOn');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: GestureDetector(
        onTap: _openColorPalette,
        child: Container(
          width: double.infinity,
          height: 88,
          decoration: BoxDecoration(
            color: _isOn 
                ? HSLColor.fromColor(_selectedColor).withLightness(
                    HSLColor.fromColor(_selectedColor).lightness * 0.5
                  ).toColor()
                : const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Light name on left, Controller type on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Light name top left
                    Flexible(
                      child: Text(
                        widget.lightName,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Controller type top right
                    if (widget.controllerTypeName != null && widget.controllerTypeName!.isNotEmpty)
                      Text(
                        widget.controllerTypeName!,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                  ],
                ),
                // Bottom row: Toggle on left, Menu on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Toggle switch bottom left
                    Transform.scale(
                      scale: 1.15,
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: _isOn,
                        onChanged: (_) => _onToggleTap(),
                        activeColor: Colors.white,
                        activeTrackColor: _isOn 
                            ? HSLColor.fromColor(_selectedColor).withLightness(
                                HSLColor.fromColor(_selectedColor).lightness * 0.3
                              ).toColor()
                            : null,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: const Color(0xFF3A3A3A),
                      ),
                    ),
                    // 3-dot menu bottom right
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        debugPrint('Menu tapped for ${widget.lightName}');
                      },
                      child: Icon(
                        Icons.more_vert,
                        color: const Color(0xFF9E9E9E),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
      ),
    );
  }
}

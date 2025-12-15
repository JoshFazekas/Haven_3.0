import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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

class _LightZoneCardState extends State<LightZoneCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _toggleController;
  bool _isOn = false;
  Color _selectedColor = Colors.white; // Store the selected color

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Default duration
    );
  }

  @override
  void dispose() {
    _toggleController?.dispose();
    super.dispose();
  }

  void _onToggleTap() {
    HapticFeedback.mediumImpact();
    
    if (_isOn) {
      // Turning OFF - reverse the animation
      _toggleController?.reverse().then((_) {
        setState(() {
          _isOn = false;
        });
      });
    } else {
      // Turning ON - play forward
      setState(() {
        _isOn = true;
      });
    }
    
    debugPrint('Toggle tapped for ${widget.lightName}: ${!_isOn ? "ON" : "OFF"}');
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
              if (isOn && _toggleController != null) {
                _toggleController!.forward();
              }
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: _openColorPalette,
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [Color(0xFF3D3D3D), Color(0xFF070707)],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5), // Border width
            decoration: BoxDecoration(
              color: _isOn ? _selectedColor.withOpacity(0.3) : const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(18.5),
              border: _isOn ? Border.all(
                color: _selectedColor.withOpacity(0.6),
                width: 1,
              ) : null,
            ),
            clipBehavior: Clip.none,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 16,
                  top: 14,
                  child: Text(
                    widget.lightName,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.controllerTypeName != null && widget.controllerTypeName!.isNotEmpty)
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Text(
                      widget.controllerTypeName!,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  top: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      debugPrint('Menu tapped for ${widget.lightName}');
                    },
                    child: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF9E9E9E),
                      size: 38,
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  top: 25,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onToggleTap,
                    child: SizedBox(
                      width: 112,
                      height: 90,
                      child: _isOn
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              _selectedColor,
                              BlendMode.modulate,
                            ),
                            child: Lottie.asset(
                              'assets/animations/toggletap.json',
                              controller: _toggleController,
                              repeat: false,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _toggleController?.duration = composition.duration;
                                _toggleController?.forward();
                              },
                            ),
                          )
                        : Image.asset(
                            'assets/images/toggle.png',
                            fit: BoxFit.contain,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

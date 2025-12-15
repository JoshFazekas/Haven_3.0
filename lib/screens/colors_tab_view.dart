import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../core/services/light_service.dart';

class ColorsTabView extends StatefulWidget {
  final String lightName;
  final String? controllerTypeName;
  final Function(Color color, bool isOn)? onColorSelected;
  final int? locationId; // For API calls
  final int? lightId; // For API calls
  final int? zoneId; // For API calls

  const ColorsTabView({
    super.key,
    required this.lightName,
    this.controllerTypeName,
    this.onColorSelected,
    this.locationId,
    this.lightId,
    this.zoneId,
  });

  @override
  State<ColorsTabView> createState() => _ColorsTabViewState();
}

class _ColorsTabViewState extends State<ColorsTabView>
    with SingleTickerProviderStateMixin {
  Color _selectedColor = Colors.white;
  AnimationController? _toggleController;
  bool _isOn = false;
  bool _isSettingColor = false; // Track API call state

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
      _toggleController?.reverse().then((_) {
        setState(() {
          _isOn = false;
        });
      });
    } else {
      setState(() {
        _isOn = true;
      });
    }
    
    debugPrint('Toggle tapped for ${widget.lightName}: ${!_isOn ? "ON" : "OFF"}');
  }

  /// Sets the color via API call
  Future<void> _setColorViaApi(Color color) async {
    if (_isSettingColor) return; // Prevent multiple simultaneous calls

    setState(() {
      _isSettingColor = true;
    });

    try {
      bool success = false;

      // Try different API endpoints based on available IDs
      if (widget.lightId != null) {
        success = await LightService.setColorByLightId(
          lightId: widget.lightId!,
          color: color,
          brightness: 100,
        );
      } else if (widget.zoneId != null) {
        success = await LightService.setColorByZoneId(
          zoneId: widget.zoneId!,
          color: color,
          brightness: 100,
        );
      } else if (widget.locationId != null) {
        success = await LightService.setColor(
          locationId: widget.locationId!,
          color: color,
          brightness: 100,
        );
      }

      if (success) {
        debugPrint('Color set successfully for ${widget.lightName}: ${LightService.colorToRgb(color)}');
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Color set for ${widget.lightName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        debugPrint('Failed to set color for ${widget.lightName}');
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set color for ${widget.lightName}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting color: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting color: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettingColor = false;
        });
      }
    }
  }

  final List<Color> _colors = [
    const Color(0xFFFF0000), // Red
    const Color(0xFFFF6B1A), // Pumpkin
    const Color(0xFFFF8C00), // Orange
    const Color.fromARGB(255, 184, 137, 42), // Marigold
    const Color(0xFFFFB347), // Sunset
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFFFFF44F), // Lemon
    const Color(0xFF32CD32), // Lime
    const Color(0xFFD1E231), // Pear
    const Color(0xFF50C878), // Emerald
    const Color(0xFF90EE90), // Light Green
    const Color(0xFF00FF00), // Green
    const Color(0xFF2E8B57), // Sea Foam
    const Color(0xFF008080), // Teal
    const Color(0xFF40E0D0), // Turquoise
    const Color(0xFFE0FFFF), // Arctic
    const Color(0xFF006994), // Ocean
    const Color(0xFF87CEEB), // Sky
    const Color(0xFF00BFFF), // Water
    const Color(0xFF0F52BA), // Sapphire
    const Color(0xFFADD8E6), // Light Blue
    const Color(0xFF00008B), // Deep Blue
    const Color(0xFF4B0082), // Indigo
    const Color(0xFFDA70D6), // Orchid
    const Color(0xFF800080), // Purple
    const Color(0xFFE6E6FA), // Lavender
    const Color(0xFFC8A2C8), // Lilac
    const Color(0xFFFFC0CB), // Pink
    const Color(0xFFFF69B4), // Bubblegum
    const Color(0xFFFC8EAC), // Flamingo
    const Color(0xFFFF1493), // Hot Pink
    const Color(0xFFFF1493), // Deep Pink
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _isSettingColor ? null : () {
                HapticFeedback.mediumImpact();
                // Call the callback with the selected color and state before popping
                if (widget.onColorSelected != null) {
                  widget.onColorSelected!(_selectedColor, _isOn);
                }
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isSettingColor 
                      ? const Color(0xFF2A2A2A).withOpacity(0.6)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isSettingColor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Color palette grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _colors.length + 1, // +1 for the add color button
                  itemBuilder: (context, index) {
                    // Check if this is the last item (add color button)
                    if (index == _colors.length) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          debugPrint('Add color button tapped');
                          // TODO: Implement add color functionality
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6E6E6E), // Grey color
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    }
                    
                    // Regular color item
                    final color = _colors[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedColor = color;
                          // If toggle is off, turn it on when a color is selected
                          if (!_isOn) {
                            _isOn = true;
                            _toggleController?.forward();
                          }
                        });
                        debugPrint('Color selected: $color');
                        
                        // Send API call to set the color
                        _setColorViaApi(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Light card at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
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
                  margin: const EdgeInsets.all(1.5),
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
          ],
        ),
      ),
    );
  }
}

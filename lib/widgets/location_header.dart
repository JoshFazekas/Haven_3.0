import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:haven/screens/menu_screen.dart';

class LocationHeader extends StatefulWidget {
  final String locationName;
  final VoidCallback? onLocationTap;
  final Function(String)? onLocationSelected;

  const LocationHeader({
    super.key,
    this.locationName = 'Home',
    this.onLocationTap,
    this.onLocationSelected,
  });

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader> {
  final GlobalKey _locationKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  bool _isDisposed = false;

  // Demo locations list
  final List<String> _recentLocations = ['Office', 'Living Room', 'Kitchen'];

  void _navigateToMenu(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MenuScreen()));
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!mounted || _isDisposed) return;

    final RenderBox? renderBox =
        _locationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted || _isDisposed) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        onTap: () {
          _removeOverlay();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 8,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _recentLocations.length; i++) ...[
                        InkWell(
                          onTap: () {
                            if (!_isDisposed) {
                              widget.onLocationSelected?.call(
                                _recentLocations[i],
                              );
                              _removeOverlay();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Text(
                              _recentLocations[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (i < _recentLocations.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Insert overlay immediately since we're in a valid state
    try {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isDropdownOpen = true;
      });
    } catch (e) {
      debugPrint('Failed to insert overlay: $e');
      _overlayEntry = null;
    }
  }

  /// Just removes the overlay without setState - safe to call anytime
  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();

    if (mounted && !_isDisposed) {
      setState(() {
        _isDropdownOpen = false;
      });
    } else {
      _isDropdownOpen = false;
    }
  }

  void _closeDropdown() {
    _removeOverlay();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Just remove the overlay entry without any setState
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to make font size dynamic
    final screenWidth = MediaQuery.of(context).size.width;
    // Base font size that scales with screen width
    final fontSize = screenWidth * 0.07; // 7% of screen width

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Location name with dropdown
        GestureDetector(
          key: _locationKey,
          onTap: () {
            widget.onLocationTap?.call();
            _toggleDropdown();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.locationName,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: fontSize.clamp(24.0, 36.0), // Min 24, max 36
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isDropdownOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: fontSize.clamp(24.0, 32.0),
                ),
              ),
            ],
          ),
        ),

        // Menu button
        GestureDetector(
          onTap: () => _navigateToMenu(context),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Image.asset(
              'assets/images/menuicon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

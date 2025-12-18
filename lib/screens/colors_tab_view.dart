import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'whites_tab_view.dart';
import 'effects_tab_view.dart';
import 'store_tab_view.dart';

class ColorsTabView extends StatefulWidget {
  final String lightName;
  final String? controllerTypeName;
  final Function(Color color, bool isOn)? onColorSelected;
  final int? locationId; // For API calls
  final int? lightId; // For API calls
  final int? zoneId; // For API calls
  final Color? initialColor;
  final bool? initialIsOn;
  final double? initialBrightness;

  const ColorsTabView({
    super.key,
    required this.lightName,
    this.controllerTypeName,
    this.onColorSelected,
    this.locationId,
    this.lightId,
    this.zoneId,
    this.initialColor,
    this.initialIsOn,
    this.initialBrightness,
  });

  @override
  State<ColorsTabView> createState() => _ColorsTabViewState();
}

class _ColorsTabViewState extends State<ColorsTabView>
    with SingleTickerProviderStateMixin {
  late Color _selectedColor;
  late bool _isOn;
  late double _brightness;
  bool _showBrightnessIndicator = false; // Show brightness number indicator
  Timer? _fadeTimer;
  AnimationController? _sliderFadeController;
  Animation<Color?>? _sliderColorAnimation;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? const Color(0xFFEC202C);
    _isOn = widget.initialIsOn ?? false;
    _brightness = widget.initialBrightness ?? 100.0;
    _sliderFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sliderColorAnimation =
        ColorTween(begin: Colors.white, end: const Color(0xFFB0B0B0)).animate(
          CurvedAnimation(
            parent: _sliderFadeController!,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _sliderFadeController?.dispose();
    super.dispose();
  }

  void _onToggleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOn = !_isOn;
      // If turning on and brightness is 0, set it to 100
      if (_isOn && _brightness == 0) {
        _brightness = 100.0;
      }
    });
    debugPrint('Toggle tapped for ${widget.lightName}: $_isOn');
  }

  final Map<String, Color> _colorMap = {
    'Red': const Color(0xFFEC202C),
    'Pumpkin': const Color(0xFFED2F24),
    'Orange': const Color(0xFFEF5023),
    'Marigold': const Color(0xFFF37A20),
    'Sunset': const Color(0xFFFAA819),
    'Yellow': const Color(0xFFFDD901),
    'Lemon': const Color(0xFFEFE814),
    'Lime': const Color(0xFFC7D92C),
    'Pear': const Color(0xFFA7CE38),
    'Emerald': const Color(0xFF88C440),
    'Lt Green': const Color(0xFF75BF43),
    'Green': const Color(0xFF6ABC45),
    'Sea Foam': const Color(0xFF6CBD45),
    'Teal': const Color(0xFF71BE48),
    'Turquoise': const Color(0xFF71C178),
    'Arctic': const Color(0xFF70C5A2),
    'Ocean': const Color(0xFF70C9CC),
    'Sky': const Color(0xFF61CAE5),
    'Water': const Color(0xFF43B4E7),
    'Sapphire': const Color(0xFF4782C3),
    'Lt Blue': const Color(0xFF4165AF),
    'Deep Blue': const Color(0xFF3E57A6),
    'Indigo': const Color(0xFF3C54A3),
    'Orchid': const Color(0xFF4B53A3),
    'Purple': const Color(0xFF6053A2),
    'Lavender': const Color(0xFF7952A0),
    'Lilac': const Color(0xFF94519F),
    'Pink': const Color(0xFFB2519E),
    'Bubblegum': const Color(0xFFC94D9B),
    'Flamingo': const Color(0xFFE63A94),
    'Hot Pink': const Color(0xFFEC2180),
    'Deep Pink': const Color(0xFFED1F52),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // Call the callback with the selected color and state before popping
                if (widget.onColorSelected != null) {
                  widget.onColorSelected!(_selectedColor, _isOn);
                }
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
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
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
                child: GridView.builder(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount:
                      _colorMap.length + 1, // +1 for the add color button
                  itemBuilder: (context, index) {
                    // Check if this is the last item (add color button)
                    if (index == _colorMap.length) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          debugPrint('Add color button tapped');
                          // TODO: Implement add color functionality
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6E6E6E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Add Color',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Regular color item
                    final colorName = _colorMap.keys.elementAt(index);
                    final color = _colorMap[colorName]!;
                    final isSelected = color == _selectedColor;

                    // Darken color if not selected
                    final displayColor = isSelected
                        ? color
                        : HSLColor.fromColor(color)
                              .withLightness(
                                HSLColor.fromColor(color).lightness * 0.55,
                              )
                              .toColor();

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedColor = color;
                          // If toggle is off, turn it on when a color is selected
                          if (!_isOn) {
                            _isOn = true;
                          }
                        });
                        debugPrint('Color selected: $colorName - $color');

                        // Send API call to set the color (disabled for now)
                        // _setColorViaApi(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 4)
                              : Border.all(color: Colors.transparent, width: 4),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        transform: isSelected
                            ? Matrix4.identity().scaled(1.05)
                            : Matrix4.identity(),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: isSelected ? 13 : 12,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                              color: Colors.black,
                            ),
                            child: Text(colorName, textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Container above the light card - Tab selector
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTabSelector(),
              ),
            ),
            // Light card at the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 9),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: HSLColor.fromColor(_selectedColor)
                        .withLightness(
                          HSLColor.fromColor(_selectedColor).lightness * 0.3,
                        )
                        .toColor()
                        .withOpacity(0.6),
                    width: 4,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 115,
                  decoration: BoxDecoration(
                    color: _isOn
                        ? (_brightness == 0
                              ? const Color(0xFF212121)
                              : HSLColor.fromColor(_selectedColor)
                                    .withLightness(
                                      (HSLColor.fromColor(
                                                _selectedColor,
                                              ).lightness *
                                              0.15) +
                                          (HSLColor.fromColor(
                                                _selectedColor,
                                              ).lightness *
                                              0.35 *
                                              (_brightness / 100)),
                                    )
                                    .toColor())
                        : const Color(0xFF1D1D1D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
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
                          if (widget.controllerTypeName != null &&
                              widget.controllerTypeName!.isNotEmpty)
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
                      // Middle row: Toggle on left, Menu on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Toggle switch left
                          Transform.scale(
                            scale: 1.15,
                            alignment: Alignment.centerLeft,
                            child: Switch(
                              value: _isOn,
                              onChanged: (_) => _onToggleTap(),
                              activeColor: Colors.white,
                              activeTrackColor: _isOn
                                  ? HSLColor.fromColor(_selectedColor)
                                        .withLightness(
                                          HSLColor.fromColor(
                                                _selectedColor,
                                              ).lightness *
                                              0.3,
                                        )
                                        .toColor()
                                  : null,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: const Color(0xFF3A3A3A),
                            ),
                          ),
                          // 3-dot menu right
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
                      // Bottom row: Brightness slider with indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedBuilder(
                                  animation:
                                      _sliderFadeController ??
                                      AnimationController(vsync: this),
                                  builder: (context, child) {
                                    final sliderColor = _showBrightnessIndicator
                                        ? Colors.white
                                        : (_sliderColorAnimation?.value ??
                                              const Color(0xFFB0B0B0));

                                    return SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                        activeTrackColor: sliderColor,
                                        inactiveTrackColor: Colors.white
                                            .withOpacity(0.3),
                                        thumbColor: sliderColor,
                                        overlayColor: Colors.white.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _brightness,
                                        min: 0,
                                        max: 100,
                                        onChanged: (value) {
                                          // Cancel any pending fade timer
                                          _fadeTimer?.cancel();
                                          _sliderFadeController?.reset();

                                          setState(() {
                                            _brightness = value;
                                            _showBrightnessIndicator = true;
                                            // Automatically turn off toggle when brightness reaches 0
                                            if (value == 0 && _isOn) {
                                              _isOn = false;
                                            }
                                            // Automatically turn on toggle when brightness is adjusted while off
                                            else if (value > 0 && !_isOn) {
                                              _isOn = true;
                                            }
                                          });
                                        },
                                        onChangeStart: (value) {
                                          // Cancel any pending fade timer
                                          _fadeTimer?.cancel();
                                          _sliderFadeController?.reset();

                                          setState(() {
                                            _showBrightnessIndicator = true;
                                          });
                                        },
                                        onChangeEnd: (value) {
                                          HapticFeedback.mediumImpact();
                                          setState(() {
                                            _showBrightnessIndicator = false;
                                          });
                                          debugPrint(
                                            'Brightness set to: ${value.round()}%',
                                          );

                                          // Start fade animation after a delay
                                          _fadeTimer?.cancel();
                                          _fadeTimer = Timer(
                                            const Duration(milliseconds: 500),
                                            () {
                                              _sliderFadeController?.forward();
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Brightness indicator
                          if (_showBrightnessIndicator)
                            Positioned(
                              top: -35,
                              left:
                                  (_brightness / 100) *
                                      (MediaQuery.of(context).size.width -
                                          110) +
                                  14 -
                                  5,
                              child: AnimatedOpacity(
                                opacity: _showBrightnessIndicator ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_brightness.round()}',
                                    style: const TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildTabSelector() {
    const int selectedIndex = 0; // Colors tab
    const List<Map<String, String>> tabs = [
      {'label': 'Colors', 'icon': 'assets/images/colorsicon.png'},
      {'label': 'Whites', 'icon': 'assets/images/whitesicon.png'},
      {'label': 'Effects', 'icon': 'assets/images/effectsicon.png'},
      {'label': 'Store', 'icon': 'assets/images/storeicon.png'},
    ];

    return Container(
      width: 310,
      height: 77,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 4;

          return Stack(
            children: [
              // Indicator for selected tab
              Positioned(
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: tabWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Tab buttons
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _onTabSelected(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.85,
                            child: Image.asset(
                              tabs[index]['icon']!,
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            tabs[index]['label']!,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTabSelected(int index) {
    Widget targetView;
    switch (index) {
      case 0:
        return; // Already on Colors tab
      case 1:
        targetView = WhitesTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      case 2:
        targetView = EffectsTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      case 3:
        targetView = StoreTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetView,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

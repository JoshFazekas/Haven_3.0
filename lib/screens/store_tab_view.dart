import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors_tab_view.dart';
import 'whites_tab_view.dart';
import 'effects_tab_view.dart';

class StoreTabView extends StatefulWidget {
  final String lightName;
  final String? controllerTypeName;
  final Function(Color color, bool isOn)? onColorSelected;
  final int? locationId;
  final int? lightId;
  final int? zoneId;
  final Color? initialColor;
  final bool? initialIsOn;
  final double? initialBrightness;

  const StoreTabView({
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
  State<StoreTabView> createState() => _StoreTabViewState();
}

class _StoreTabViewState extends State<StoreTabView> {
  late Color _selectedColor;
  late bool _isOn;
  late double _brightness;
  int _selectedTabIndex = 3; // Store tab is index 3

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.blue;
    _isOn = widget.initialIsOn ?? false;
    _brightness = widget.initialBrightness ?? 100.0;
  }

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
            // Demo content area
            Expanded(
              child: Center(
                child: Text(
                  'SCREEN DEMO',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            // Tab selector
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTabSelector(),
              ),
            ),
            // Light card at the bottom
            _buildLightCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLightCard() {
    return Padding(
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
                              (HSLColor.fromColor(_selectedColor).lightness *
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.scale(
                    scale: 1.15,
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      value: _isOn,
                      onChanged: (value) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isOn = value;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: _isOn
                          ? HSLColor.fromColor(_selectedColor)
                                .withLightness(
                                  HSLColor.fromColor(_selectedColor).lightness *
                                      0.3,
                                )
                                .toColor()
                          : null,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: const Color(0xFF3A3A3A),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      debugPrint('Menu tapped for ${widget.lightName}');
                    },
                    child: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF9E9E9E),
                      size: 32,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: 100,
                        min: 0,
                        max: 100,
                        onChanged: (value) {},
                      ),
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

  Widget _buildTabSelector() {
    const List<Map<String, String>> tabs = [
      {'label': 'Colors', 'icon': 'assets/images/colorsicon.png'},
      {'label': 'Whites', 'icon': 'assets/images/whitesicon.png'},
      {'label': 'Effects', 'icon': ''},
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
              // Animated sliding indicator for selected tab
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _selectedTabIndex * tabWidth,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: -1,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab buttons
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  final isEffects = tabs[index]['label'] == 'Effects';
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
                            child: isEffects
                                ? Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: const RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.8,
                                        colors: [
                                          Color(0xFF8B1A1A),
                                          Color(0xFF1A3A6E),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1A3A6E).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.asset(
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
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFB0B0B0),
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
    if (index == 3) return; // Already on Store tab

    // Animate the indicator and navigate immediately (async)
    setState(() {
      _selectedTabIndex = index;
    });

    // Navigate immediately - don't wait for animation
    Widget targetView;
    switch (index) {
      case 0:
        targetView = ColorsTabView(
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

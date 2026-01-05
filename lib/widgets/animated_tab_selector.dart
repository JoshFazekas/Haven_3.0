import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedTabSelector extends StatefulWidget {
  final int selectedIndex;
  final Function(int index) onTabSelected;
  final String lightName;
  final String? controllerTypeName;
  final Function(Color color, bool isOn)? onColorSelected;
  final int? locationId;
  final int? lightId;
  final int? zoneId;

  const AnimatedTabSelector({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.lightName,
    this.controllerTypeName,
    this.onColorSelected,
    this.locationId,
    this.lightId,
    this.zoneId,
  });

  static const List<Map<String, String>> tabs = [
    {'label': 'Colors', 'icon': 'assets/images/colorsicon.png'},
    {'label': 'Whites', 'icon': 'assets/images/whitesicon.png'},
    {'label': 'Effects', 'icon': 'assets/images/effectsicon.png'},
    {'label': 'Store', 'icon': 'assets/images/storeicon.png'},
  ];

  @override
  State<AnimatedTabSelector> createState() => _AnimatedTabSelectorState();
}

class _AnimatedTabSelectorState extends State<AnimatedTabSelector> {
  @override
  Widget build(BuildContext context) {
    const double containerWidth = 310;
    const double containerPadding = 4;
    const double tabCount = 4;

    return Container(
      width: containerWidth,
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
      padding: const EdgeInsets.all(containerPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final tabWidth = availableWidth / tabCount;

          return Stack(
            children: [
              // Animated sliding indicator for selected tab
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: widget.selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(AnimatedTabSelector.tabs.length, (
                  index,
                ) {
                  return Expanded(child: _buildTabButton(index));
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index) {
    final isSelected = widget.selectedIndex == index;
    final label = AnimatedTabSelector.tabs[index]['label']!;
    final iconPath = AnimatedTabSelector.tabs[index]['icon']!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.85,
              child: Image.asset(
                iconPath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

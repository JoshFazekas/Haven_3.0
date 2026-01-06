import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';

/// Horizontal scrolling background color selector with "no background" option
class BackgroundColorPicker extends StatefulWidget {
  /// Title label for the section
  final String title;
  
  /// Currently selected background color (null means no background)
  final Color? selectedColor;
  
  /// List of available colors to choose from (defaults to ColorPalette.availableColors)
  final List<Color>? availableColors;
  
  /// Callback when a color is selected (null for no background)
  final void Function(Color? color) onColorSelected;
  
  /// Whether to show the swipe hint text
  final bool showSwipeHint;
  
  /// Whether to include "no background" option at start
  final bool includeNoBackground;

  const BackgroundColorPicker({
    super.key,
    this.title = 'Background',
    required this.selectedColor,
    this.availableColors,
    required this.onColorSelected,
    this.showSwipeHint = true,
    this.includeNoBackground = true,
  });

  @override
  State<BackgroundColorPicker> createState() => _BackgroundColorPickerState();
}

class _BackgroundColorPickerState extends State<BackgroundColorPicker> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  List<Color?> get _backgroundOptions {
    final colors = widget.availableColors ?? ColorPalette.availableColors;
    if (widget.includeNoBackground) {
      return <Color?>[null, ...colors];
    }
    return colors.cast<Color?>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Carousel background color picker
        SizedBox(
          height: 70,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _scrollOffset = _scrollController.offset;
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 0, right: 16),
              itemCount: _backgroundOptions.length,
              itemBuilder: (context, index) {
                final color = _backgroundOptions[index];
                final isSelected = widget.selectedColor == color;
                final isNoBackground = color == null;

                // Calculate scale based on position from left edge
                final itemWidth = 56.0;
                final itemPosition = (index * itemWidth) - _scrollOffset;
                
                final fullSizeZone = itemWidth * 5;
                final taperZone = itemWidth * 2.0;
                
                double scale;
                double baseOpacity;
                
                if (itemPosition < 0) {
                  scale = 0.7;
                  baseOpacity = 0.6;
                } else if (itemPosition <= fullSizeZone) {
                  scale = 1.0;
                  baseOpacity = 1.0;
                } else if (itemPosition <= fullSizeZone + taperZone) {
                  final taperProgress = (itemPosition - fullSizeZone) / taperZone;
                  scale = 1.0 - (taperProgress * 0.3);
                  baseOpacity = 1.0 - (taperProgress * 0.4);
                } else {
                  scale = 0.7;
                  baseOpacity = 0.6;
                }

                // Grey out non-selected colors
                final opacity = isSelected ? baseOpacity : baseOpacity * 0.35;

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        widget.onColorSelected(color);
                        HapticFeedback.lightImpact();
                      },
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 50),
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isNoBackground ? const Color(0xFF555555) : color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : (isNoBackground || color == Colors.black
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.3)),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected && !isNoBackground && color != Colors.black
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.6 * scale),
                                        blurRadius: 12 * scale,
                                        spreadRadius: 2 * scale,
                                      ),
                                    ]
                                  : (!isNoBackground && color != Colors.black
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.2 * scale),
                                            blurRadius: 4 * scale,
                                            spreadRadius: 0,
                                          ),
                                        ]
                                      : null),
                            ),
                            child: isNoBackground
                                ? CustomPaint(
                                    painter: _NoBackgroundPainter(),
                                    size: const Size(48, 48),
                                  )
                                : (isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showSwipeHint) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '← Swipe →',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Painter for the "No Background" option - grey with diagonal cross
class _NoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw diagonal line from top-left to bottom-right
    final padding = size.width * 0.25;
    canvas.drawLine(
      Offset(padding, padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

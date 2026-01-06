import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';

/// Horizontal scrolling color carousel for adding colors
class AddColorCarousel extends StatefulWidget {
  /// Title label for the section
  final String title;
  
  /// List of available colors to choose from (defaults to ColorPalette.availableColors)
  final List<Color>? availableColors;
  
  /// Number of currently selected colors (used to check if max reached)
  final int currentColorCount;
  
  /// Maximum number of colors that can be added
  final int maxColors;
  
  /// Callback when a color is added
  final void Function(Color color) onColorAdded;
  
  /// Whether to show the swipe hint text
  final bool showSwipeHint;

  const AddColorCarousel({
    super.key,
    this.title = 'Add Color',
    this.availableColors,
    required this.currentColorCount,
    this.maxColors = 8,
    required this.onColorAdded,
    this.showSwipeHint = true,
  });

  @override
  State<AddColorCarousel> createState() => _AddColorCarouselState();
}

class _AddColorCarouselState extends State<AddColorCarousel> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  List<Color> get _colors => widget.availableColors ?? ColorPalette.availableColors;
  bool get _canAddMore => widget.currentColorCount < widget.maxColors;

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
        // Title
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
        // Carousel color picker
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
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];

                // Calculate scale based on position from left edge
                final itemWidth = 56.0; // 48 + 8 padding
                final itemPosition = (index * itemWidth) - _scrollOffset;
                
                // First 5 items (within ~280px from left) stay full size
                // Then taper the next 2 items on the right
                final fullSizeZone = itemWidth * 5;
                final taperZone = itemWidth * 2.0;
                
                double scale;
                double opacity;
                
                if (itemPosition < 0) {
                  // Off screen to the left
                  scale = 0.7;
                  opacity = 0.6;
                } else if (itemPosition <= fullSizeZone) {
                  // First 5 - full size
                  scale = 1.0;
                  opacity = 1.0;
                } else if (itemPosition <= fullSizeZone + taperZone) {
                  // Next 2 on the right - taper from 1.0 to 0.7
                  final taperProgress = (itemPosition - fullSizeZone) / taperZone;
                  scale = 1.0 - (taperProgress * 0.3);
                  opacity = 1.0 - (taperProgress * 0.4);
                } else {
                  // Beyond visible area
                  scale = 0.7;
                  opacity = 0.6;
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _canAddMore
                          ? () {
                              widget.onColorAdded(color);
                              HapticFeedback.lightImpact();
                            }
                          : null,
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 50),
                        child: Opacity(
                          opacity: _canAddMore ? opacity : 0.3,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color == Colors.black
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: color == Colors.black
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: color.withOpacity(0.4 * scale),
                                        blurRadius: 8 * scale,
                                        spreadRadius: 1 * scale,
                                      ),
                                    ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

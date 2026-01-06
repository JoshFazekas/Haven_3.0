import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Speed slider with center-origin track (-100 to +100 range)
class SpeedSlider extends StatelessWidget {
  /// Title label for the section
  final String title;
  
  /// Current speed value (-100 to +100)
  final double value;
  
  /// Callback when value changes
  final void Function(double value) onChanged;
  
  /// Label for negative direction (default: '← Reverse')
  final String reverseLabel;
  
  /// Label for positive direction (default: 'Forward →')
  final String forwardLabel;
  
  /// Label when value is 0 (default: 'Still')
  final String stillLabel;
  
  /// Snap threshold - values within ±this will snap to 0 (default: 3)
  final double snapThreshold;

  const SpeedSlider({
    super.key,
    this.title = 'Speed',
    required this.value,
    required this.onChanged,
    this.reverseLabel = '← Reverse',
    this.forwardLabel = 'Forward →',
    this.stillLabel = 'Still',
    this.snapThreshold = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              reverseLabel,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              forwardLabel,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.1),
            trackShape: const CenterOriginSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: -100,
            max: 100,
            divisions: 200,
            onChanged: (sliderValue) {
              // Snap to 0 if within threshold
              if (sliderValue.abs() <= snapThreshold) {
                onChanged(0);
              } else {
                onChanged(sliderValue);
              }
            },
            onChangeEnd: (sliderValue) {
              HapticFeedback.lightImpact();
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              value == 0
                  ? stillLabel
                  : '${value > 0 ? '+' : ''}${value.round()}',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom slider track shape that draws from center (0 value) instead of left edge
class CenterOriginSliderTrackShape extends RoundedRectSliderTrackShape {
  const CenterOriginSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2.0,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackTop = trackRect.top + (trackRect.height - trackHeight) / 2;
    final double trackBottom = trackTop + trackHeight;
    final double trackLeft = trackRect.left;
    final double trackRight = trackRect.right;
    final double trackCenter = (trackLeft + trackRight) / 2;

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.white;

    final double radius = trackHeight / 2;

    // Draw full inactive track
    canvas.drawRRect(
      RRect.fromLTRBR(
        trackLeft,
        trackTop,
        trackRight,
        trackBottom,
        Radius.circular(radius),
      ),
      inactivePaint,
    );

    // Draw active track from center to thumb position
    if (thumbCenter.dx < trackCenter) {
      // Thumb is on the left side (negative values) - draw from thumb to center
      canvas.drawRRect(
        RRect.fromLTRBR(
          thumbCenter.dx,
          trackTop,
          trackCenter,
          trackBottom,
          Radius.circular(radius),
        ),
        activePaint,
      );
    } else if (thumbCenter.dx > trackCenter) {
      // Thumb is on the right side (positive values) - draw from center to thumb
      canvas.drawRRect(
        RRect.fromLTRBR(
          trackCenter,
          trackTop,
          thumbCenter.dx,
          trackBottom,
          Radius.circular(radius),
        ),
        activePaint,
      );
    }
    // If thumbCenter.dx == trackCenter, don't draw active track (speed is 0)
  }
}

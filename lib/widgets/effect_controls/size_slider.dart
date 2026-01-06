import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable size slider for ribbon size, background size, etc.
/// Range: 0.25ft (3 inches) to 100ft
class SizeSlider extends StatelessWidget {
  /// Title label for the section
  final String title;
  
  /// Current size value in feet (0.25 to 100)
  final double value;
  
  /// Callback when value changes
  final void Function(double value) onChanged;
  
  /// Callback to show manual input dialog (optional)
  final VoidCallback? onTapValue;
  
  /// Minimum label (default: '0.25ft')
  final String minLabel;
  
  /// Maximum label (default: '100ft')
  final String maxLabel;

  const SizeSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.onTapValue,
    this.minLabel = '0.25ft',
    this.maxLabel = '100ft',
  });

  /// Get valid step values: 3in (0.25), 6in (0.5), 9in (0.75), 1ft, 2ft, ... 100ft
  static List<double> getValidSteps() {
    return [0.25, 0.5, 0.75, for (int i = 1; i <= 100; i++) i.toDouble()];
  }

  /// Find closest step index for a given value
  static int findClosestStepIndex(double value) {
    final steps = getValidSteps();
    int closestIndex = 0;
    double minDiff = (steps[0] - value).abs();
    for (int i = 1; i < steps.length; i++) {
      final diff = (steps[i] - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  /// Format the size display (e.g., "3in", "1ft", "50ft")
  static String formatSize(double feet) {
    if (feet < 1.0) {
      final inches = (feet * 12).round();
      return '${inches}in';
    } else {
      return '${feet.round()}ft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = getValidSteps();
    final currentIndex = findClosestStepIndex(value);

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
              minLabel,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              maxLabel,
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
          ),
          child: Slider(
            value: currentIndex.toDouble(),
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            onChanged: (sliderValue) {
              onChanged(steps[sliderValue.round()]);
            },
            onChangeEnd: (sliderValue) {
              HapticFeedback.lightImpact();
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: onTapValue,
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
                formatSize(value),
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
    );
  }
}

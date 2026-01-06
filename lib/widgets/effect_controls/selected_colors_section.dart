import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays selected colors as a grid with ability to remove colors
class SelectedColorsSection extends StatelessWidget {
  /// Title label for the section
  final String title;
  
  /// List of currently selected colors
  final List<Color> selectedColors;
  
  /// Callback when a color is removed (receives the index)
  final void Function(int index)? onRemoveColor;
  
  /// Maximum number of colors allowed
  final int maxColors;
  
  /// Minimum number of colors required (cannot go below this)
  final int minColors;

  const SelectedColorsSection({
    super.key,
    this.title = 'Ribbons',
    required this.selectedColors,
    this.onRemoveColor,
    this.maxColors = 8,
    this.minColors = 1,
  });

  @override
  Widget build(BuildContext context) {
    final canRemove = selectedColors.length > minColors;
    
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(selectedColors.length, (index) {
            return GestureDetector(
              onTap: canRemove && onRemoveColor != null
                  ? () {
                      onRemoveColor!(index);
                      HapticFeedback.lightImpact();
                    }
                  : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selectedColors[index],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColors[index].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: canRemove
                    ? const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }),
        ),
        if (selectedColors.length >= maxColors)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum $maxColors colors',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }
}

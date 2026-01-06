import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal bottom sheet picker for feet and inches selection
class SizePickerModal {
  /// Show the size picker modal
  /// 
  /// [context] - BuildContext for showing the modal
  /// [currentValue] - Current size value in feet (0.25 to 100)
  /// [title] - Title displayed in the header
  /// [onSave] - Callback with the selected value in feet
  static void show({
    required BuildContext context,
    required double currentValue,
    required String title,
    required void Function(double value) onSave,
  }) {
    int feet = currentValue >= 1.0 ? currentValue.round() : 0;
    int inches = currentValue < 1.0 ? (currentValue * 12).round() : 0;
    
    // Snap inches to valid values (0, 3, 6, 9)
    if (inches > 0 && inches < 3) {
      inches = 3;
    } else if (inches > 3 && inches < 6) {
      inches = 6;
    } else if (inches > 6 && inches < 9) {
      inches = 9;
    } else if (inches > 9) {
      inches = 0;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Enforce minimum of 3 inches if feet is 0
                          final finalInches = (feet == 0 && inches == 0) ? 3 : inches;
                          final totalFeet = feet + (finalInches / 12.0);
                          final clampedValue = totalFeet.clamp(0.25, 100.0);
                          onSave(clampedValue);
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Color(0xFF3A3A3C), height: 1),
                
                // Picker section
                Builder(
                  builder: (context) {
                    // Create persistent controllers
                    final inchesController = FixedExtentScrollController(
                      initialItem: inches == 9 ? 3 : (inches == 6 ? 2 : (inches == 3 ? 1 : 0)),
                    );
                    
                    return SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          // Feet picker
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Feet',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 44,
                                    perspective: 0.003,
                                    diameterRatio: 1.5,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: FixedExtentScrollController(
                                      initialItem: feet,
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setModalState(() {
                                        feet = index;
                                        // If feet becomes 0 and inches is 0, auto-select 3 inches and animate
                                        if (feet == 0 && inches == 0) {
                                          inches = 3;
                                          // Animate the inches picker to index 1 (which is 3 inches)
                                          inchesController.animateToItem(
                                            1,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 101,
                                      builder: (context, index) {
                                        final isSelected = index == feet;
                                        return Center(
                                          child: Text(
                                            '$index',
                                            style: TextStyle(
                                              fontFamily: 'SpaceMono',
                                              fontSize: isSelected ? 24 : 18,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected 
                                                  ? const Color(0xFFD75F00) 
                                                  : Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Inches picker
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Inches',
                                    style: TextStyle(
                                      fontFamily: 'SpaceMono',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 44,
                                    perspective: 0.003,
                                    diameterRatio: 1.5,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: inchesController,
                                    onSelectedItemChanged: (index) {
                                      setModalState(() {
                                        // If feet is 0, minimum is 3 inches (index 1)
                                        if (feet == 0 && index == 0) {
                                          inches = 3; // Don't allow 0 inches when feet is 0
                                          // Animate back to index 1 (3 inches)
                                          inchesController.animateToItem(
                                            1,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        } else {
                                          inches = [0, 3, 6, 9][index];
                                        }
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 4,
                                      builder: (context, index) {
                                        final inchValue = [0, 3, 6, 9][index];
                                        final isSelected = inchValue == inches;
                                        // Grey out 0 inches when feet is 0
                                        final isDisabled = feet == 0 && inchValue == 0;
                                        return Center(
                                          child: Text(
                                            '$inchValue',
                                            style: TextStyle(
                                              fontFamily: 'SpaceMono',
                                              fontSize: isSelected ? 24 : 18,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isDisabled
                                                  ? Colors.white.withOpacity(0.15)
                                                  : (isSelected 
                                                      ? const Color(0xFFD75F00) 
                                                      : Colors.white.withOpacity(0.3)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

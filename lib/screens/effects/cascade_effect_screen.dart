import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'effect_saved_screen.dart';
import '../../widgets/effect_controls/effect_controls.dart';

/// Configuration screen for the Cascade effect
class CascadeEffectScreen extends StatefulWidget {
  final AnimationController animationController;
  final VoidCallback onBack;
  final VoidCallback? onSaveComplete; // Called after effect is saved to go back to My Effects
  final Function(VoidCallback)? onSaveCallbackReady; // Expose save dialog trigger to parent

  const CascadeEffectScreen({
    super.key,
    required this.animationController,
    required this.onBack,
    this.onSaveComplete,
    this.onSaveCallbackReady,
  });

  @override
  State<CascadeEffectScreen> createState() => _CascadeEffectScreenState();
}

class _CascadeEffectScreenState extends State<CascadeEffectScreen> {
  // Default cascade colors
  List<Color> _selectedColors = [
    const Color(0xFFEC202C), // Red
    const Color(0xFF6ABC45), // Green
    const Color(0xFFFDD901), // Yellow
  ];

  Color? _backgroundColor; // null means no background (default)
  double _ribbonSize = 50.0; // In feet (range: 0.25 to 100 ft, where 0.25 = 3 inches)
  double _backgroundSize = 1.0; // In feet (range: 0.25 to 100 ft, where 0.25 = 3 inches)
  double _speed = -50.0; // -100 to +100 range (0 = stopped, negative = reverse)
  final ScrollController _colorScrollController = ScrollController();
  double _scrollOffset = 0.0;
  final ScrollController _backgroundScrollController = ScrollController();
  double _backgroundScrollOffset = 0.0;

  // Initial values to track changes
  late List<Color> _initialColors;
  late Color? _initialBackgroundColor;
  late double _initialRibbonSize;
  late double _initialBackgroundSize;
  late double _initialSpeed;

  // Check if user has made any changes
  bool get _hasChanges {
    if (_selectedColors.length != _initialColors.length) return true;
    for (int i = 0; i < _selectedColors.length; i++) {
      if (_selectedColors[i] != _initialColors[i]) return true;
    }
    if (_backgroundColor != _initialBackgroundColor) return true;
    if (_ribbonSize != _initialRibbonSize) return true;
    if (_backgroundSize != _initialBackgroundSize) return true;
    if (_speed != _initialSpeed) return true;
    return false;
  }

  void _addColor(Color color) {
    if (_selectedColors.length < 8) {
      setState(() {
        _selectedColors.add(color);
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeColor(int index) {
    if (_selectedColors.length > 1) {
      setState(() {
        _selectedColors.removeAt(index);
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  void initState() {
    super.initState();
    // Store initial values to track changes
    _initialColors = List.from(_selectedColors);
    _initialBackgroundColor = _backgroundColor;
    _initialRibbonSize = _ribbonSize;
    _initialBackgroundSize = _backgroundSize;
    _initialSpeed = _speed;
    
    // Expose the save dialog trigger to parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSaveCallbackReady?.call(_showSaveEffectDialog);
    });
  }

  @override
  void dispose() {
    _colorScrollController.dispose();
    _backgroundScrollController.dispose();
    super.dispose();
  }

  /// Generate an auto-populated effect name based on the first 3 ribbon colors
  String _generateEffectName() {
    final colorNames = <String>[];
    
    // Map colors to names (take up to 3 colors)
    for (int i = 0; i < _selectedColors.length && i < 3; i++) {
      colorNames.add(ColorPalette.getColorName(_selectedColors[i]));
    }
    
    // Create name: "Cascade [Color1] [Color2] [Color3]"
    return 'Cascade ${colorNames.join(' ')}';
  }

  /// Handle back button press - show confirmation if there are unsaved changes
  void _handleBack() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      widget.onBack();
    }
  }

  /// Show confirmation dialog when user tries to leave with unsaved changes
  void _showUnsavedChangesDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Unsaved Changes',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'You have unsaved changes. Are you sure you want to go back?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Divider(color: Color(0xFF3A3A3C), height: 1),
                  
                  // Buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Discard button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onBack();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Text(
                              'Discard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF3B30),
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
      ),
    );
  }

  void _showSaveEffectDialog() {
    final generatedName = _generateEffectName();
    final nameController = TextEditingController(text: generatedName);
    
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                          const Text(
                            'Name Effect',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final effectName = nameController.text.trim();
                              if (effectName.isNotEmpty) {
                                // TODO: Save the effect with the name
                                // This will save: effectName, _selectedColors, _backgroundColor, 
                                // _ribbonSize, _backgroundSize, _speed
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                // Show success screen
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EffectSavedScreen(
                                      effectName: effectName,
                                      onComplete: () {
                                        Navigator.of(context).pop();
                                        // Go back to My Effects tab
                                        if (widget.onSaveComplete != null) {
                                          widget.onSaveComplete!();
                                        } else {
                                          widget.onBack();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD75F00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(color: Color(0xFF3A3A3C), height: 1),
                    
                    // Name input field
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter effect name',
                          hintStyle: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD75F00),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleBack,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cascade',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: Column(
            children: [
              // Fixed preview at top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPreviewSection(),
              ),
              
              const SizedBox(height: 24),
              
              // Scrollable controls
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected colors section
                      _buildSelectedColorsSection(),

                      const SizedBox(height: 24),

                      // Add colors section
                      _buildAddColorsSection(),

                      const SizedBox(height: 24),

                      // Ribbon size slider
                      _buildRibbonSizeSection(),

                      const SizedBox(height: 24),

                      // Background color section
                      _buildBackgroundColorSection(),

                      // Background size slider (only shown when background is selected)
                      if (_backgroundColor != null) ...[
                        const SizedBox(height: 24),
                        _buildBackgroundSizeSection(),
                      ],

                      const SizedBox(height: 24),

                      // Speed slider
                      _buildSpeedSection(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AnimatedBuilder(
          animation: widget.animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: CascadePreviewPainter(
                animationValue: widget.animationController.value,
                colors: _selectedColors,
                backgroundColor: _backgroundColor,
                ribbonSize: _ribbonSize,
                backgroundSize: _backgroundSize,
                speed: _speed,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ribbons',
          style: TextStyle(
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
          children: List.generate(_selectedColors.length, (index) {
            return GestureDetector(
              onTap: () => _removeColor(index),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedColors[index],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedColors[index].withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _selectedColors.length > 1
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
        if (_selectedColors.length >= 8)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum 8 colors',
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

  Widget _buildAddColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Add Color',
          style: TextStyle(
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
                  _scrollOffset = _colorScrollController.offset;
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _colorScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 0, right: 16),
              itemCount: ColorPalette.availableColors.length,
              itemBuilder: (context, index) {
                final color = ColorPalette.availableColors[index];
                final canAddMore = _selectedColors.length < 8;

                // Calculate scale based on position from left edge
                final itemWidth = 56.0; // 48 + 8 padding
                final itemPosition =
                    (index * itemWidth) - _scrollOffset; // position from left edge
                
                // First 5 items (within ~280px from left) stay full size
                // Then taper the next 2 items on the right
                final fullSizeZone = itemWidth * 5; // First 5 items zone
                final taperZone = itemWidth * 2.0; // Next 2 items taper
                
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
                  scale = 1.0 - (taperProgress * 0.3); // 1.0 -> 0.7
                  opacity = 1.0 - (taperProgress * 0.4); // 1.0 -> 0.6
                } else {
                  // Beyond visible area
                  scale = 0.7;
                  opacity = 0.6;
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: canAddMore
                          ? () => _addColor(color)
                          : null,
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 50),
                        child: Opacity(
                          opacity: canAddMore
                              ? opacity
                              : 0.3,
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
        const SizedBox(height: 8),
        // Hint text
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
    );
  }

  Widget _buildBackgroundColorSection() {
    // Background colors: null (no background) first, then all available colors
    final backgroundOptions = <Color?>[null, ...ColorPalette.availableColors];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background',
          style: TextStyle(
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
                  _backgroundScrollOffset = _backgroundScrollController.offset;
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _backgroundScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 0, right: 16),
              itemCount: backgroundOptions.length,
              itemBuilder: (context, index) {
                final color = backgroundOptions[index];
                final isSelected = _backgroundColor == color;
                final isNoBackground = color == null;

                // Calculate scale based on position from left edge
                final itemWidth = 56.0; // 48 + 8 padding
                final itemPosition =
                    (index * itemWidth) - _backgroundScrollOffset;
                
                // First 5 items (within ~280px from left) stay full size
                // Then taper the next 2 items on the right
                final fullSizeZone = itemWidth * 5;
                final taperZone = itemWidth * 2.0;
                
                double scale;
                double baseOpacity;
                
                if (itemPosition < 0) {
                  // Off screen to the left
                  scale = 0.7;
                  baseOpacity = 0.6;
                } else if (itemPosition <= fullSizeZone) {
                  // First 5 - full size
                  scale = 1.0;
                  baseOpacity = 1.0;
                } else if (itemPosition <= fullSizeZone + taperZone) {
                  // Next 2 on the right - taper from 1.0 to 0.7
                  final taperProgress = (itemPosition - fullSizeZone) / taperZone;
                  scale = 1.0 - (taperProgress * 0.3);
                  baseOpacity = 1.0 - (taperProgress * 0.4);
                } else {
                  // Beyond visible area
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
                        setState(() {
                          _backgroundColor = color;
                        });
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
        const SizedBox(height: 8),
        // Hint text
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
    );
  }

  Widget _buildBackgroundSizeSection() {
    // Valid steps: 3in (0.25), 6in (0.5), 9in (0.75), 1ft, 2ft, ... 100ft
    List<double> getValidSteps() {
      return [0.25, 0.5, 0.75, for (int i = 1; i <= 100; i++) i.toDouble()];
    }
    
    final steps = getValidSteps();
    
    // Find closest step index for current value
    int findClosestStepIndex(double value) {
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
    
    // Format the size display
    String formatSize(double feet) {
      if (feet < 1.0) {
        final inches = (feet * 12).round();
        return '${inches}in';
      } else {
        return '${feet.round()}ft';
      }
    }

    final currentIndex = findClosestStepIndex(_backgroundSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Size',
          style: TextStyle(
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
              '0.25ft',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              '100ft',
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
            onChanged: (value) {
              setState(() {
                _backgroundSize = steps[value.round()];
              });
            },
            onChangeEnd: (value) {
              HapticFeedback.lightImpact();
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _showManualBackgroundSizeDialog(),
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
                formatSize(_backgroundSize),
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

  void _showManualBackgroundSizeDialog() {
    int feet = _backgroundSize >= 1.0 ? _backgroundSize.round() : 0;
    int inches = _backgroundSize < 1.0 ? (_backgroundSize * 12).round() : 0;
    // Snap inches to valid values (0, 3, 6, 9)
    if (inches > 0 && inches < 3) inches = 3;
    else if (inches > 3 && inches < 6) inches = 6;
    else if (inches > 6 && inches < 9) inches = 9;
    else if (inches > 9) inches = 0;

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
                      const Text(
                        'Background Size',
                        style: TextStyle(
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
                          setState(() {
                            _backgroundSize = clampedValue;
                          });
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

  Widget _buildRibbonSizeSection() {
    // Valid steps: 3in (0.25), 6in (0.5), 9in (0.75), 1ft, 2ft, ... 100ft
    List<double> getValidSteps() {
      return [0.25, 0.5, 0.75, for (int i = 1; i <= 100; i++) i.toDouble()];
    }
    
    final steps = getValidSteps();
    
    // Find closest step index for current value
    int findClosestStepIndex(double value) {
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
    
    // Format the ribbon size display
    String formatRibbonSize(double feet) {
      if (feet < 1.0) {
        final inches = (feet * 12).round();
        return '${inches}in';
      } else {
        return '${feet.round()}ft';
      }
    }

    final currentIndex = findClosestStepIndex(_ribbonSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ribbon Size',
          style: TextStyle(
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
              '0.25ft',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              '100ft',
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
            onChanged: (value) {
              setState(() {
                _ribbonSize = steps[value.round()];
              });
            },
            onChangeEnd: (value) {
              HapticFeedback.lightImpact();
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _showManualLengthDialog(),
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
                formatRibbonSize(_ribbonSize),
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

  void _showManualLengthDialog() {
    int feet = _ribbonSize >= 1.0 ? _ribbonSize.round() : 0;
    int inches = _ribbonSize < 1.0 ? (_ribbonSize * 12).round() : 0;
    // Snap inches to valid values (0, 3, 6, 9)
    if (inches > 0 && inches < 3) inches = 3;
    else if (inches > 3 && inches < 6) inches = 6;
    else if (inches > 6 && inches < 9) inches = 9;
    else if (inches > 9) inches = 0;

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
                      const Text(
                        'Ribbon Length',
                        style: TextStyle(
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
                          setState(() {
                            _ribbonSize = clampedValue;
                          });
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

  Widget _buildSpeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speed',
          style: TextStyle(
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
              '← Reverse',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            Text(
              'Forward →',
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
            trackShape: _CenterOriginSliderTrackShape(),
          ),
          child: Slider(
            value: _speed,
            min: -100,
            max: 100,
            divisions: 200,
            onChanged: (value) {
              setState(() {
                // Snap to 0 if within ±3 units
                if (value.abs() <= 3) {
                  _speed = 0;
                } else {
                  _speed = value;
                }
              });
            },
            onChangeEnd: (value) {
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
              _speed == 0
                  ? 'Still'
                  : '${_speed > 0 ? '+' : ''}${_speed.round()}',
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

/// Cascade effect preview painter
class CascadePreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final Color? backgroundColor; // null means no background
  final double ribbonSize; // 0.25-100 range (in feet)
  final double backgroundSize; // 0.25-100 range (in feet) - gap size between ribbons
  final double speed; // -100 to +100 range

  CascadePreviewPainter({
    required this.animationValue,
    required this.colors,
    this.backgroundColor,
    this.ribbonSize = 50.0,
    this.backgroundSize = 1.0,
    this.speed = -50.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background if set
    if (backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor!,
      );
    }

    // Calculate segment width based on ribbon size
    // Map 0.25-100 ft to visual preview: min = thin visible lines, max = ~1/5 of screen per color
    final totalColors = colors.length;
    
    // Normalize ribbon size: 0.25ft -> 0, 100ft -> 1
    final normalizedRibbonSize = (ribbonSize - 0.25) / (100.0 - 0.25);
    
    // Min width: 4px (thin but visible), Max width: screen width / 5
    final minWidth = 4.0;
    final maxWidth = size.width / 5;
    final segmentWidth = minWidth + (normalizedRibbonSize * (maxWidth - minWidth));

    // Calculate gap width based on background size (only if background is set)
    double gapWidth = 0.0;
    if (backgroundColor != null) {
      final normalizedBackgroundSize = (backgroundSize - 0.25) / (100.0 - 0.25);
      final minGapWidth = 2.0;
      final maxGapWidth = size.width / 6;
      gapWidth = minGapWidth + (normalizedBackgroundSize * (maxGapWidth - minGapWidth));
    }
    
    final totalSegmentWidth = segmentWidth + gapWidth;
    final totalPatternWidth = totalSegmentWidth * totalColors;

    // Animation offset - speed controls direction and rate
    // speed: -100 to +100, where 0 = stopped
    // Positive speed = left to right, Negative speed = right to left
    final speedFactor = -speed / 100.0; // Negated so positive = left-to-right
    final offset = animationValue * totalPatternWidth * speedFactor;

    // Draw color segments with gaps
    double currentX = -offset - totalPatternWidth;

    // Keep drawing until we've covered the visible area plus buffer
    while (currentX < size.width + totalPatternWidth * 2) {
      for (int i = 0; i < colors.length; i++) {
        final segmentX = currentX + (i * totalSegmentWidth);

        // Only draw if segment is visible
        if (segmentX + segmentWidth > 0 && segmentX < size.width) {
          canvas.drawRect(
            Rect.fromLTWH(segmentX, 0, segmentWidth, size.height),
            Paint()..color = colors[i],
          );
        }
      }
      currentX += totalPatternWidth;
    }
  }

  @override
  bool shouldRepaint(CascadePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.ribbonSize != ribbonSize ||
      oldDelegate.backgroundSize != backgroundSize ||
      oldDelegate.speed != speed ||
      oldDelegate.colors.length != colors.length;
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

/// Custom slider track shape that draws from center (0 value) instead of left edge
class _CenterOriginSliderTrackShape extends RoundedRectSliderTrackShape {
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

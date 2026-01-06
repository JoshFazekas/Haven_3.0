import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Content widget for the "Create Effects" view within the Effects tab.
/// This is displayed as a subfolder-like view within "My Effects".
class CreateEffectContent extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool)? onConfigScreenChanged; // Notify when entering/exiting effect configuration

  const CreateEffectContent({
    super.key,
    required this.onBack,
    this.onConfigScreenChanged,
  });

  @override
  State<CreateEffectContent> createState() => _CreateEffectContentState();
}

class _CreateEffectContentState extends State<CreateEffectContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedEffectType; // Track which effect is being configured

  // List of effect types with their configurations
  static const List<Map<String, dynamic>> _effectTypes = [
    {
      'name': 'Marquee',
      'type': 'marquee',
      'description': 'Scrolling light pattern',
    },
    {
      'name': 'Cascade',
      'type': 'cascade',
      'description': 'Flowing waterfall effect',
    },
    {
      'name': 'Checkerboard',
      'type': 'checkerboard',
      'description': 'Alternating pattern',
    },
    {
      'name': '3 Wave',
      'type': 'wave3',
      'description': 'Triple wave overlay',
    },
    {
      'name': '2 Wave',
      'type': 'wave2',
      'description': 'Double wave blend',
    },
    {
      'name': '1 Wave',
      'type': 'wave1',
      'description': 'Single smooth wave',
    },
    {
      'name': 'Sparkle',
      'type': 'sparkle',
      'description': 'Twinkling lights',
    },
    {
      'name': 'Multi Color Sparkle',
      'type': 'multiSparkle',
      'description': 'Colorful twinkles',
    },
    {
      'name': 'Race',
      'type': 'race',
      'description': 'Racing light chase',
    },
    {
      'name': 'Comet',
      'type': 'comet',
      'description': 'Shooting trails',
    },
    {
      'name': 'Lava',
      'type': 'lava',
      'description': 'Flowing lava effect',
    },
    {
      'name': 'Matrix',
      'type': 'matrix',
      'description': 'Digital rain effect',
    },
    {
      'name': 'Water',
      'type': 'water',
      'description': 'Rippling water',
    },
    {
      'name': 'Cool Colors',
      'type': 'coolColors',
      'description': 'Blue & green palette',
    },
    {
      'name': 'Warm Colors',
      'type': 'warmColors',
      'description': 'Red & orange palette',
    },
    {
      'name': 'All Colors',
      'type': 'allColors',
      'description': 'Full rainbow spectrum',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show effect configuration screen if an effect is selected
    if (_selectedEffectType == 'cascade') {
      // Notify parent that we're in a config screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onConfigScreenChanged?.call(true);
      });
      
      return _CascadeConfigScreen(
        animationController: _animationController,
        onBack: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _selectedEffectType = null;
          });
          // Notify parent that we've exited the config screen
          widget.onConfigScreenChanged?.call(false);
        },
      );
    }
    
    // Notify parent that we're on the main selection screen (not in config)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onConfigScreenChanged?.call(false);
    });
    
    // Default: show the effect types grid
    return Column(
      children: [
        // Back button header (same style as other folders)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onBack();
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/images/createeffect.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Create Effect',
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
        // Effect types grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _effectTypes.length,
              itemBuilder: (context, index) {
                final effectType = _effectTypes[index];
                return _EffectTypeCard(
                  effectType: effectType,
                  animationController: _animationController,
                  getEffectPreviewPainter: _getEffectPreviewPainter,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final type = effectType['type'] as String;
                    if (type == 'cascade') {
                      setState(() {
                        _selectedEffectType = type;
                      });
                    } else {
                      debugPrint('Selected effect type: ${effectType['name']}');
                      // TODO: Navigate to other effect configuration screens
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  CustomPainter _getEffectPreviewPainter(String type, double animationValue) {
    switch (type) {
      case 'wave3':
        return _WavePreviewPainter(
          animationValue: animationValue,
          waveCount: 3,
          colors: [const Color(0xFF6053A2), const Color(0xFFEC2180), const Color(0xFF4165AF)],
        );
      case 'wave2':
        return _WavePreviewPainter(
          animationValue: animationValue,
          waveCount: 2,
          colors: [const Color(0xFF6ABC45), const Color(0xFF4165AF)],
        );
      case 'wave1':
        return _WavePreviewPainter(
          animationValue: animationValue,
          waveCount: 1,
          colors: [const Color(0xFFEC202C)],
        );
      case 'sparkle':
        return _SparklePreviewPainter(
          animationValue: animationValue,
          sparkleColor: const Color(0xFFFFD700),
          backgroundColor: const Color(0xFF1A1A1A),
        );
      case 'multiSparkle':
        return _SparklePreviewPainter(
          animationValue: animationValue,
          sparkleColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFF1A1A1A),
          isMultiColor: true,
        );
      case 'comet':
        return _CometPreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFFEC202C), const Color(0xFFFFD700)],
        );
      case 'marquee':
        return _MarqueePreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFFEC202C), const Color(0xFF4165AF), const Color(0xFFFFFFFF)],
        );
      case 'cascade':
        return _CascadePreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFFEC202C), const Color(0xFF6ABC45), const Color(0xFFFFD700)],
        );
      case 'checkerboard':
        return _CheckerboardPreviewPainter(
          animationValue: animationValue,
          color1: const Color(0xFFEC202C),
          color2: const Color(0xFF6ABC45),
        );
      case 'race':
        return _RacePreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFFEC202C), const Color(0xFF4165AF), const Color(0xFF6ABC45)],
        );
      case 'lava':
        return _LavaPreviewPainter(animationValue: animationValue);
      case 'matrix':
        return _MatrixPreviewPainter(animationValue: animationValue);
      case 'water':
        return _WaterPreviewPainter(animationValue: animationValue);
      case 'coolColors':
        return _ColorPatternPreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFF4165AF), const Color(0xFF70C9CC), const Color(0xFF6ABC45), const Color(0xFF6053A2)],
        );
      case 'warmColors':
        return _ColorPatternPreviewPainter(
          animationValue: animationValue,
          colors: [const Color(0xFFEC202C), const Color(0xFFFF6B00), const Color(0xFFFFD700), const Color(0xFFEC2180)],
        );
      case 'allColors':
        return _ColorPatternPreviewPainter(
          animationValue: animationValue,
          colors: [
            const Color(0xFFEC202C),
            const Color(0xFFFF6B00),
            const Color(0xFFFFD700),
            const Color(0xFF6ABC45),
            const Color(0xFF4165AF),
            const Color(0xFF6053A2),
            const Color(0xFFEC2180),
          ],
        );
      default:
        return _WavePreviewPainter(
          animationValue: animationValue,
          waveCount: 1,
          colors: [const Color(0xFF4165AF)],
        );
    }
  }
}

/// A card widget that only animates when visible on screen
class _EffectTypeCard extends StatefulWidget {
  final Map<String, dynamic> effectType;
  final AnimationController animationController;
  final CustomPainter Function(String type, double animationValue) getEffectPreviewPainter;
  final VoidCallback? onTap;

  const _EffectTypeCard({
    required this.effectType,
    required this.animationController,
    required this.getEffectPreviewPainter,
    this.onTap,
  });

  @override
  State<_EffectTypeCard> createState() => _EffectTypeCardState();
}

class _EffectTypeCardState extends State<_EffectTypeCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('effect-card-${widget.effectType['type']}'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0;
        if (visible != _isVisible) {
          setState(() {
            _isVisible = visible;
          });
        }
      },
      child: GestureDetector(
        onTap: widget.onTap ?? () {
          HapticFeedback.mediumImpact();
          debugPrint('Selected effect type: ${widget.effectType['name']}');
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animation preview area
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: RepaintBoundary(
                    child: _isVisible
                        ? AnimatedBuilder(
                            animation: widget.animationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: widget.getEffectPreviewPainter(
                                  widget.effectType['type'] as String,
                                  widget.animationController.value,
                                ),
                                size: Size.infinite,
                              );
                            },
                          )
                        : CustomPaint(
                            // Static frame when not visible (frozen at 0)
                            painter: widget.getEffectPreviewPainter(
                              widget.effectType['type'] as String,
                              0.0,
                            ),
                            size: Size.infinite,
                          ),
                  ),
                ),
              ),
              // Label area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  widget.effectType['name'] as String,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration screen for the Cascade effect
class _CascadeConfigScreen extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onBack;

  const _CascadeConfigScreen({
    required this.animationController,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back button header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
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
        // TODO: Add cascade configuration options here
        Expanded(
          child: Center(
            child: Text(
              'Cascade Configuration',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple visibility detector widget
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final void Function(VisibilityInfo info) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _childKey = GlobalKey();
  double _lastVisibleFraction = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(VisibilityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    
    final RenderObject? renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      if (_lastVisibleFraction != 0.0) {
        _lastVisibleFraction = 0.0;
        widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 0.0));
      }
      return;
    }

    final RenderBox box = renderObject as RenderBox;
    final Offset topLeft = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate visible area
    final visibleTop = topLeft.dy.clamp(0.0, screenSize.height);
    final visibleBottom = (topLeft.dy + size.height).clamp(0.0, screenSize.height);
    final visibleHeight = (visibleBottom - visibleTop).clamp(0.0, size.height);
    
    final visibleFraction = size.height > 0 ? visibleHeight / size.height : 0.0;
    
    // Only notify if visibility changed significantly
    final wasVisible = _lastVisibleFraction > 0;
    final isVisible = visibleFraction > 0;
    
    if (wasVisible != isVisible) {
      _lastVisibleFraction = visibleFraction;
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: visibleFraction));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Check visibility on any scroll event
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
        return false;
      },
      child: KeyedSubtree(
        key: _childKey,
        child: widget.child,
      ),
    );
  }
}

class VisibilityInfo {
  final double visibleFraction;
  
  VisibilityInfo({required this.visibleFraction});
}

// Preview painters for each effect type

class _WavePreviewPainter extends CustomPainter {
  final double animationValue;
  final int waveCount;
  final List<Color> colors;

  _WavePreviewPainter({
    required this.animationValue,
    required this.waveCount,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    for (int w = 0; w < waveCount; w++) {
      final path = Path();
      final color = colors[w % colors.length];
      final phaseOffset = w * 0.33;
      final amplitude = size.height * 0.15 * (1 - w * 0.2);
      final centerY = size.height * (0.35 + w * 0.15);

      path.moveTo(0, size.height);
      path.lineTo(0, centerY);

      for (double x = 0; x <= size.width; x += 2) {
        final y = centerY +
            amplitude *
                math.sin((x / size.width * 2 * math.pi) +
                    (animationValue * 2 * math.pi) +
                    (phaseOffset * 2 * math.pi));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _SparklePreviewPainter extends CustomPainter {
  final double animationValue;
  final Color sparkleColor;
  final Color backgroundColor;
  final bool isMultiColor;

  _SparklePreviewPainter({
    required this.animationValue,
    required this.sparkleColor,
    required this.backgroundColor,
    this.isMultiColor = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final random = math.Random(42); // Fixed seed for consistent positions
    final multiColors = [
      const Color(0xFFEC202C),
      const Color(0xFFFFD700),
      const Color(0xFF6ABC45),
      const Color(0xFF4165AF),
      const Color(0xFFEC2180),
    ];

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final baseSize = 2 + random.nextDouble() * 4;
      final phase = random.nextDouble();
      final twinkle = (math.sin((animationValue + phase) * 2 * math.pi) + 1) / 2;
      final currentSize = baseSize * twinkle;

      final color = isMultiColor
          ? multiColors[i % multiColors.length]
          : sparkleColor;

      canvas.drawCircle(
        Offset(x, y),
        currentSize,
        Paint()..color = color.withOpacity(twinkle * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _CometPreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  _CometPreviewPainter({
    required this.animationValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A1A),
    );

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i * 0.33) % 1.0;
      final x = progress * size.width * 1.3 - size.width * 0.15;
      final y = size.height * (0.25 + i * 0.25);
      final color = colors[i % colors.length];
      final tailLength = size.width * 0.25;

      // Draw tail
      for (int t = 0; t < 10; t++) {
        final tailProgress = t / 10;
        final tailX = x - tailLength * tailProgress;
        final tailOpacity = (1 - tailProgress) * 0.8;
        final tailSize = 4 * (1 - tailProgress * 0.5);

        canvas.drawCircle(
          Offset(tailX, y),
          tailSize,
          Paint()..color = color.withOpacity(tailOpacity),
        );
      }

      // Draw head
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_CometPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _MarqueePreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  _MarqueePreviewPainter({
    required this.animationValue,
    required this.colors,
  });

  // Pre-defined segment lengths (varying short and long)
  static const List<double> _segmentLengths = [
    0.8, 0.4, 1.2, 0.5, 0.9, 0.3, 1.0, 0.6, 0.7, 1.1, 0.35, 0.85,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate total pattern width based on segment lengths
    final baseUnit = size.width / 6;
    double totalPatternWidth = 0;
    for (final length in _segmentLengths) {
      totalPatternWidth += baseUnit * length;
    }

    // Animation offset - scrolls the entire pattern (slowed down by 0.3x)
    final offset = animationValue * totalPatternWidth * 0.3;

    // Draw segments filling the entire height (as a strip of lights)
    double currentX = -offset;
    int segmentIndex = 0;

    // Keep drawing until we've covered the visible area plus buffer
    while (currentX < size.width + totalPatternWidth) {
      final segmentLength = baseUnit * _segmentLengths[segmentIndex % _segmentLengths.length];
      final color = colors[segmentIndex % colors.length];

      // Draw the segment as a full-height rectangle (no gaps)
      canvas.drawRect(
        Rect.fromLTWH(currentX, 0, segmentLength, size.height),
        Paint()..color = color,
      );

      currentX += segmentLength;
      segmentIndex++;
    }
  }

  @override
  bool shouldRepaint(_MarqueePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _CascadePreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final double gapWidth;

  _CascadePreviewPainter({
    required this.animationValue,
    required this.colors,
    this.gapWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Calculate segment width based on available space - all segments equal size
    final totalColors = colors.length;
    final segmentWidth = size.width / (totalColors * 2); // Equal sized segments
    final totalSegmentWidth = segmentWidth + gapWidth;
    final totalPatternWidth = totalSegmentWidth * totalColors;

    // Animation offset - scrolls the entire pattern (slowed down by 0.3x)
    final offset = animationValue * totalPatternWidth * 0.3;

    // Draw color segments with gaps
    double currentX = -offset;

    // Keep drawing until we've covered the visible area plus buffer
    while (currentX < size.width + totalPatternWidth) {
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
  bool shouldRepaint(_CascadePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _CheckerboardPreviewPainter extends CustomPainter {
  final double animationValue;
  final Color color1;
  final Color color2;

  _CheckerboardPreviewPainter({
    required this.animationValue,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 4;
    final phase = (animationValue * 2).floor() % 2;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final isEven = (row + col + phase) % 2 == 0;
        final color = isEven ? color1 : color2;
        
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          Paint()..color = color.withOpacity(0.85),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _RacePreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  _RacePreviewPainter({
    required this.animationValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    final bubbleCount = colors.length;
    final spacing = size.height / (bubbleCount + 1);

    for (int i = 0; i < bubbleCount; i++) {
      // Each bubble has a phase offset for variety
      final phaseOffset = i * 0.15;
      final progress = (animationValue + phaseOffset) % 1.0;
      
      // Sine wave oscillation: slow start -> fast middle -> slow stop -> reverse
      // Using sin gives smooth acceleration/deceleration
      final oscillation = math.sin(progress * 2 * math.pi);
      
      // Map oscillation (-1 to 1) to x position across the width
      final centerX = size.width / 2;
      final maxTravel = size.width * 0.35; // How far bubbles travel from center
      final x = centerX + (oscillation * maxTravel);
      
      final y = spacing * (i + 1);
      final color = colors[i % colors.length];

      // Draw bubble with glow effect
      canvas.drawCircle(
        Offset(x, y),
        14,
        Paint()..color = color.withOpacity(0.3),
      );
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()..color = color,
      );
      // Highlight
      canvas.drawCircle(
        Offset(x - 3, y - 3),
        3,
        Paint()..color = Colors.white.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RacePreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _LavaPreviewPainter extends CustomPainter {
  final double animationValue;

  _LavaPreviewPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark red background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2A0A0A),
    );

    final random = math.Random(42);
    final colors = [
      const Color(0xFFFF4500),
      const Color(0xFFFF6B00),
      const Color(0xFFFFD700),
    ];

    for (int i = 0; i < 8; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final phase = random.nextDouble();
      final blobSize = 15 + random.nextDouble() * 20;

      final offset = math.sin((animationValue + phase) * 2 * math.pi) * 10;
      final scale = 0.8 + math.sin((animationValue + phase) * 2 * math.pi) * 0.2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX, baseY + offset),
          width: blobSize * scale,
          height: blobSize * scale * 1.2,
        ),
        Paint()..color = colors[i % colors.length].withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_LavaPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _MatrixPreviewPainter extends CustomPainter {
  final double animationValue;

  _MatrixPreviewPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A0A0A),
    );

    final columns = 8;
    final columnWidth = size.width / columns;
    final random = math.Random(42);

    for (int col = 0; col < columns; col++) {
      final speed = 0.5 + random.nextDouble() * 0.5;
      final offset = (animationValue * speed + random.nextDouble()) % 1.0;
      final x = col * columnWidth + columnWidth / 2;

      for (int dot = 0; dot < 6; dot++) {
        final y = ((offset + dot * 0.15) % 1.0) * size.height;
        final opacity = 1.0 - dot * 0.15;
        final dotSize = 4 - dot * 0.5;

        canvas.drawCircle(
          Offset(x, y),
          dotSize.clamp(1.0, 4.0),
          Paint()..color = const Color(0xFF00FF00).withOpacity(opacity.clamp(0.2, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _WaterPreviewPainter extends CustomPainter {
  final double animationValue;

  _WaterPreviewPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep blue background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A2040),
    );

    // Draw ripples
    for (int i = 0; i < 3; i++) {
      final centerX = size.width * (0.3 + i * 0.2);
      final centerY = size.height * 0.5;
      final phase = (animationValue + i * 0.3) % 1.0;

      for (int ring = 0; ring < 3; ring++) {
        final radius = 10 + (phase + ring * 0.2) * 40;
        final opacity = (1.0 - (phase + ring * 0.2)).clamp(0.0, 0.6);

        canvas.drawCircle(
          Offset(centerX, centerY),
          radius,
          Paint()
            ..color = const Color(0xFF70C9CC).withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WaterPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _ColorPatternPreviewPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  _ColorPatternPreviewPainter({
    required this.animationValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate which two colors we're transitioning between
    final totalColors = colors.length;
    final scaledProgress = animationValue * totalColors;
    final currentIndex = scaledProgress.floor() % totalColors;
    final nextIndex = (currentIndex + 1) % totalColors;
    final lerpProgress = scaledProgress - scaledProgress.floor();
    
    // Smoothly interpolate between current and next color
    final currentColor = colors[currentIndex];
    final nextColor = colors[nextIndex];
    final morphedColor = Color.lerp(currentColor, nextColor, lerpProgress)!;
    
    // Fill entire canvas with the morphed color
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = morphedColor,
    );
    
    // Add subtle gradient overlay for depth
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
          Colors.black.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(_ColorPatternPreviewPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

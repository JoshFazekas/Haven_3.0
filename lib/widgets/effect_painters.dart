import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for Wave3 effect - draws 3 overlapping sine waves
/// with different wavelengths, amplitudes, speeds, and directions
class Wave3EffectPainter extends CustomPainter {
  final double animationValue;
  final Color startColor;
  final Color peakColor;
  final Color valleyColor;
  final List<Map<String, dynamic>> waves;
  final double opacity;
  final bool isOn;
  final double brightness;

  Wave3EffectPainter({
    required this.animationValue,
    required this.startColor,
    required this.peakColor,
    required this.valleyColor,
    required this.waves,
    required this.opacity,
    required this.isOn,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate effective opacity based on isOn state and brightness
    // When off: stroke stays same, fill is very dim (0.15 opacity)
    // When on: full brightness effect based on brightness slider
    final double effectiveFillOpacity;
    if (!isOn || brightness == 0) {
      effectiveFillOpacity = 0.15; // Very dim when off
    } else {
      // Scale from 0.15 (at brightness 0) to 1.0 (at brightness 100)
      effectiveFillOpacity = 0.15 + (0.85 * (brightness / 100));
    }

    final double effectiveStrokeOpacity = 1.0; // Stroke always visible

    // Draw background gradient (valley color)
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          valleyColor.withOpacity(0.8 * effectiveFillOpacity),
          valleyColor.withOpacity(effectiveFillOpacity),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw each wave
    for (int waveIndex = 0; waveIndex < waves.length; waveIndex++) {
      final wave = waves[waveIndex];
      _drawWave(
        canvas,
        size,
        wavelength: wave['wavelength'] as double,
        amplitude: wave['amplitude'] as double,
        speed: wave['speed'] as double,
        direction: wave['direction'] as double,
        phase: wave['phase'] as double,
        waveIndex: waveIndex,
        fillOpacity: effectiveFillOpacity,
        strokeOpacity: effectiveStrokeOpacity,
      );
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double wavelength,
    required double amplitude,
    required double speed,
    required double direction,
    required double phase,
    required int waveIndex,
    required double fillOpacity,
    required double strokeOpacity,
  }) {
    final path = Path();

    // Calculate the time-based offset for animation
    final timeOffset = animationValue * speed * direction * 2 * math.pi;

    // Number of points to draw for smooth wave
    const int points = 100;
    final dx = size.width / points;

    // Amplitude is capped by the opacity parameter (40%)
    final effectiveAmplitude = (size.height * 0.3) * amplitude * opacity;
    final centerY = size.height * 0.5;

    // Start the path
    path.moveTo(0, size.height);

    // Draw wave points from left to right
    for (int i = 0; i <= points; i++) {
      final x = i * dx;

      // Calculate normalized position (0 to 1) along the width
      final normalizedX = x / size.width;

      // Calculate the wave value using sine
      // wavelength controls how many complete waves fit in the container
      final waveValue = math.sin(
        (normalizedX * wavelength * 2 * math.pi) +
            timeOffset +
            (phase * 2 * math.pi),
      );

      // Calculate y position
      final y = centerY + (waveValue * effectiveAmplitude);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Complete the path to fill
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Create gradient paint for the wave
    // Color interpolates from valley (bottom) to peak (top of wave) to start (middle)
    // Apply fillOpacity to make waves dim when light is off
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          valleyColor.withOpacity((0.2 + (waveIndex * 0.15)) * fillOpacity),
          startColor.withOpacity((0.5 + (waveIndex * 0.1)) * fillOpacity),
          peakColor.withOpacity((0.6 + (waveIndex * 0.1)) * fillOpacity),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, wavePaint);

    // Draw a subtle glow/stroke on top of the wave for definition
    // Stroke remains visible even when light is off
    final strokePath = Path();
    strokePath.moveTo(
      0,
      centerY +
          (math.sin(timeOffset + (phase * 2 * math.pi)) * effectiveAmplitude),
    );

    for (int i = 0; i <= points; i++) {
      final x = i * dx;
      final normalizedX = x / size.width;
      final waveValue = math.sin(
        (normalizedX * wavelength * 2 * math.pi) +
            timeOffset +
            (phase * 2 * math.pi),
      );
      final y = centerY + (waveValue * effectiveAmplitude);
      strokePath.lineTo(x, y);
    }

    final strokePaint = Paint()
      ..color = peakColor.withOpacity((0.3 + (waveIndex * 0.1)) * strokeOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(Wave3EffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isOn != isOn ||
        oldDelegate.brightness != brightness;
  }
}

/// Data class to store pre-generated random properties for each comet
class CometData {
  final int colorIndex;
  final double yPosition;
  final double speed;
  final double phase;
  final double size;

  CometData({
    required this.colorIndex,
    required this.yPosition,
    required this.speed,
    required this.phase,
    required this.size,
  });
}

/// Custom painter for Comet effect - draws multiple comets with fading tails
/// moving at random slow speeds across the container
class CometEffectPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final int cometCount;
  final double tailLength;
  final double minSpeed;
  final double maxSpeed;
  final bool isOn;
  final double brightness;

  // Pre-generated random values for each comet (seeded for consistency)
  static final List<CometData> _comets = [];

  CometEffectPainter({
    required this.animationValue,
    required this.colors,
    required this.cometCount,
    required this.tailLength,
    required this.minSpeed,
    required this.maxSpeed,
    required this.isOn,
    required this.brightness,
  }) {
    // Initialize comets if not already done or count changed
    if (_comets.length != cometCount) {
      _comets.clear();
      final random = math.Random(42); // Fixed seed for consistent randomness
      
      // Calculate available whole number speeds between min and max
      final int minSpeedInt = minSpeed.ceil();
      final int maxSpeedInt = maxSpeed.floor();
      final int speedRange = maxSpeedInt - minSpeedInt + 1;
      
      for (int i = 0; i < cometCount; i++) {
        // Use whole number speeds for seamless looping
        // Each comet completes exactly N full trips per animation cycle
        final int wholeSpeed = minSpeedInt + random.nextInt(speedRange.clamp(1, 10));
        
        _comets.add(CometData(
          colorIndex: random.nextInt(colors.length),
          yPosition: 0.1 + random.nextDouble() * 0.8, // 10-90% of height
          speed: wholeSpeed.toDouble(), // Whole number for seamless loop
          phase: random.nextDouble(), // Random starting position
          size: 3.0 + random.nextDouble() * 4.0, // Head size 3-7
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate effective brightness
    final double effectiveOpacity;
    if (!isOn || brightness == 0) {
      effectiveOpacity = 0.15;
    } else {
      effectiveOpacity = 0.15 + (0.85 * (brightness / 100));
    }

    // Draw black background
    final bgPaint = Paint()
      ..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw each comet
    for (int i = 0; i < _comets.length; i++) {
      final comet = _comets[i];
      _drawComet(
        canvas,
        size,
        comet: comet,
        color: colors[comet.colorIndex % colors.length],
        opacity: effectiveOpacity,
      );
    }
  }

  void _drawComet(
    Canvas canvas,
    Size size, {
    required CometData comet,
    required Color color,
    required double opacity,
  }) {
    // Calculate comet position based on animation
    // Each comet moves at its own speed and has its own phase
    final progress = ((animationValue * comet.speed) + comet.phase) % 1.0;
    
    // Comet moves from right to left (off-screen to off-screen)
    // Start position: just off right edge, End position: just off left edge
    final totalTravel = size.width + (size.width * tailLength);
    final headX = size.width + (size.width * tailLength * 0.5) - (progress * totalTravel);
    final headY = comet.yPosition * size.height;

    // Don't draw if completely off screen
    if (headX < -size.width * tailLength || headX > size.width + comet.size) {
      return;
    }

    // Calculate tail length in pixels
    final tailLengthPx = size.width * tailLength;

    // Draw the comet tail with gradient (fading segments)
    const int segments = 25;
    for (int i = 0; i < segments; i++) {
      final segmentProgress = i / (segments - 1);
      
      // Quadratic falloff for opacity (bright at head, fading to nothing)
      final segmentOpacity = math.pow(1 - segmentProgress, 2) * opacity;
      
      if (segmentOpacity < 0.02) continue;

      // Calculate segment position (head at 0, tail extends to the right)
      final segmentX = headX + (segmentProgress * tailLengthPx);
      
      // Skip if segment is off screen
      if (segmentX < -comet.size || segmentX > size.width + comet.size) continue;

      // Taper the size (head is full size, tail gets thinner)
      final segmentSize = comet.size * (1 - segmentProgress * 0.7);

      // Draw glow
      final glowPaint = Paint()
        ..color = color.withOpacity(segmentOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(segmentX, headY),
        segmentSize + 3,
        glowPaint,
      );

      // Draw segment
      final segmentPaint = Paint()
        ..color = color.withOpacity(segmentOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(segmentX, headY),
        segmentSize,
        segmentPaint,
      );
    }

    // Draw bright head
    final headGlowPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(headX, headY),
      comet.size + 2,
      headGlowPaint,
    );

    final headPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headX, headY),
      comet.size,
      headPaint,
    );

    // Draw bright white core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headX, headY),
      comet.size * 0.4,
      corePaint,
    );
  }

  @override
  bool shouldRepaint(CometEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isOn != isOn ||
        oldDelegate.brightness != brightness;
  }
}

/// Custom painter for USA Flag waving effect
/// Draws an American flag with realistic wave distortion animation
class USAFlagEffectPainter extends CustomPainter {
  final double animationValue;
  final bool isOn;
  final double brightness;

  // USA Flag colors - darker, more subtle versions
  static const Color _red = Color(0xFF8B1A28);    // Darker red
  static const Color _white = Color(0xFFB0B0B0);  // Dimmed white/grey
  static const Color _blue = Color(0xFF2A2A4E);   // Darker blue

  USAFlagEffectPainter({
    required this.animationValue,
    required this.isOn,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw black background first
    final bgPaint = Paint()
      ..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Calculate effective opacity based on brightness
    // Keep opacity low to not overpower UI components
    final double effectiveOpacity;
    if (!isOn || brightness == 0) {
      effectiveOpacity = 0.10;
    } else {
      // Max opacity is 0.45 (45%) to keep it subtle
      effectiveOpacity = 0.10 + (0.35 * (brightness / 100));
    }

    // Flag dimensions (standard US flag ratio is 1.9:1)
    final flagWidth = size.width;
    final flagHeight = size.height;
    
    // Stripe dimensions (13 stripes)
    final stripeHeight = flagHeight / 13;
    
    // Union (blue canton) dimensions
    // Union spans 7 stripes in height and 40% of flag width
    final unionHeight = stripeHeight * 7;
    final unionWidth = flagWidth * 0.4;

    // Draw the 13 stripes with wave distortion
    for (int i = 0; i < 13; i++) {
      final isRedStripe = i % 2 == 0;
      final stripeColor = isRedStripe ? _red : _white;
      
      _drawWavyStripe(
        canvas,
        size,
        stripeIndex: i,
        stripeHeight: stripeHeight,
        color: stripeColor.withOpacity(effectiveOpacity),
        unionWidth: i < 7 ? unionWidth : 0, // First 7 stripes have union cutout
      );
    }

    // Draw the union (blue canton) with wave distortion
    _drawWavyUnion(
      canvas,
      size,
      unionWidth: unionWidth,
      unionHeight: unionHeight,
      color: _blue.withOpacity(effectiveOpacity),
    );

    // Draw stars on the union
    _drawStars(
      canvas,
      unionWidth: unionWidth,
      unionHeight: unionHeight,
      opacity: effectiveOpacity,
    );
  }

  /// Calculate wind intensity - creates a smooth gust cycle
  /// Goes from calm -> building -> peak -> calming -> calm in a smooth loop
  double _getWindIntensity() {
    // Use a combination of sine waves for smooth, natural wind gusting
    // This creates: stop -> slow -> fast -> slow -> stop loop
    
    // Main gust cycle (completes 1 full gust per animation loop)
    final mainGust = (math.sin(animationValue * 2 * math.pi - math.pi / 2) + 1) / 2;
    
    // Add a subtle secondary rhythm for more natural feel
    final secondaryGust = (math.sin(animationValue * 4 * math.pi) + 1) / 4;
    
    // Combine: mainGust provides 0->1->0 cycle, secondary adds variation
    // Use pow to make the calm periods longer and gusts more pronounced
    final intensity = math.pow(mainGust, 1.5) * 0.8 + secondaryGust * 0.2;
    
    // Ensure minimum movement even at "calm" (0.1) and max at gust (1.0)
    return 0.1 + (intensity * 0.9);
  }

  /// Calculate wave distortion at a given x position
  double _getWaveOffset(double x, double width, double amplitude) {
    // Get current wind intensity for smooth gusting effect
    final windIntensity = _getWindIntensity();
    
    // Multiple overlapping waves for realistic fabric movement
    final normalizedX = x / width;
    
    // Scale wave speeds by wind intensity - waves move faster during gusts
    final speedMultiplier = 0.3 + (windIntensity * 0.7);
    
    // Primary wave - large slow movement
    final wave1 = math.sin(
      (normalizedX * 2 * math.pi) + (animationValue * 2 * math.pi * 1.0 * speedMultiplier)
    ) * amplitude * 0.6 * windIntensity;
    
    // Secondary wave - medium frequency
    final wave2 = math.sin(
      (normalizedX * 4 * math.pi) + (animationValue * 2 * math.pi * 1.5 * speedMultiplier) + 0.5
    ) * amplitude * 0.3 * windIntensity;
    
    // Tertiary wave - small ripples (these persist slightly even in calm)
    final wave3 = math.sin(
      (normalizedX * 8 * math.pi) + (animationValue * 2 * math.pi * 2.0 * speedMultiplier) + 1.0
    ) * amplitude * 0.1 * (0.3 + windIntensity * 0.7);
    
    return wave1 + wave2 + wave3;
  }

  /// Draw a stripe with wave distortion
  void _drawWavyStripe(
    Canvas canvas,
    Size size, {
    required int stripeIndex,
    required double stripeHeight,
    required Color color,
    required double unionWidth,
  }) {
    final path = Path();
    final baseY = stripeIndex * stripeHeight;
    final amplitude = size.height * 0.05; // Reduced wave amplitude for subtlety
    
    const int segments = 50;
    
    // Start from left edge (or after union for top 7 stripes)
    final startX = stripeIndex < 7 ? unionWidth : 0.0;
    
    // Top edge of stripe
    path.moveTo(startX, baseY + _getWaveOffset(startX, size.width, amplitude));
    
    for (int i = 0; i <= segments; i++) {
      final x = (i / segments) * size.width;
      if (x < startX) continue;
      
      final waveOffset = _getWaveOffset(x, size.width, amplitude);
      path.lineTo(x, baseY + waveOffset);
    }
    
    // Bottom edge of stripe (going backwards)
    for (int i = segments; i >= 0; i--) {
      final x = (i / segments) * size.width;
      if (x < startX) continue;
      
      final waveOffset = _getWaveOffset(x, size.width, amplitude);
      path.lineTo(x, baseY + stripeHeight + waveOffset);
    }
    
    path.close();
    
    // Add subtle gradient for fabric shading based on wave position
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.1)!,
        ],
      ).createShader(Rect.fromLTWH(0, baseY, size.width, stripeHeight))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
  }

  /// Draw the union (blue canton) with wave distortion
  void _drawWavyUnion(
    Canvas canvas,
    Size size, {
    required double unionWidth,
    required double unionHeight,
    required Color color,
  }) {
    final path = Path();
    final amplitude = size.height * 0.05; // Reduced for subtlety
    
    const int segments = 30;
    
    // Top edge
    path.moveTo(0, _getWaveOffset(0, size.width, amplitude));
    for (int i = 0; i <= segments; i++) {
      final x = (i / segments) * unionWidth;
      final waveOffset = _getWaveOffset(x, size.width, amplitude);
      path.lineTo(x, waveOffset);
    }
    
    // Right edge
    for (int i = 0; i <= segments; i++) {
      final y = (i / segments) * unionHeight;
      final waveOffset = _getWaveOffset(unionWidth, size.width, amplitude);
      // Slightly vary the right edge wave based on y position
      final yWave = math.sin((y / unionHeight) * math.pi + animationValue * 2 * math.pi) * amplitude * 0.3;
      path.lineTo(unionWidth + yWave * 0.5, y + waveOffset);
    }
    
    // Bottom edge (going backwards)
    for (int i = segments; i >= 0; i--) {
      final x = (i / segments) * unionWidth;
      final waveOffset = _getWaveOffset(x, size.width, amplitude);
      path.lineTo(x, unionHeight + waveOffset);
    }
    
    // Left edge
    path.lineTo(0, _getWaveOffset(0, size.width, amplitude));
    path.close();
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
  }

  /// Draw the 50 stars on the union
  void _drawStars(
    Canvas canvas, {
    required double unionWidth,
    required double unionHeight,
    required double opacity,
  }) {
    final amplitude = unionHeight * 0.10; // Reduced for subtlety
    
    // Star grid: 6 columns x 5 rows alternating with 5 columns x 4 rows
    // Simplified: Draw 50 stars in a 9-row pattern
    // Rows 1,3,5,7,9: 6 stars
    // Rows 2,4,6,8: 5 stars
    
    final starSize = unionHeight * 0.04; // Slightly smaller stars
    final horizontalSpacing = unionWidth / 12;
    final verticalSpacing = unionHeight / 10;
    
    // Stars are dimmer to not overpower
    final starPaint = Paint()
      ..color = _white.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;
    
    for (int row = 0; row < 9; row++) {
      final isLongRow = row % 2 == 0;
      final starsInRow = isLongRow ? 6 : 5;
      final xOffset = isLongRow ? horizontalSpacing : horizontalSpacing * 2;
      
      for (int col = 0; col < starsInRow; col++) {
        final baseX = xOffset + (col * horizontalSpacing * 2);
        final baseY = verticalSpacing + (row * verticalSpacing);
        
        // Apply wave distortion to star position
        final waveOffset = _getWaveOffset(baseX, unionWidth * 2.5, amplitude);
        
        final starX = baseX;
        final starY = baseY + waveOffset;
        
        // Draw a simple 5-pointed star
        _drawStar(canvas, starX, starY, starSize, starPaint);
      }
    }
  }

  /// Draw a 5-pointed star at the given position
  void _drawStar(Canvas canvas, double cx, double cy, double size, Paint paint) {
    final path = Path();
    
    for (int i = 0; i < 5; i++) {
      // Outer point
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final outerX = cx + size * math.cos(outerAngle);
      final outerY = cy + size * math.sin(outerAngle);
      
      // Inner point (between outer points)
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      final innerX = cx + size * 0.4 * math.cos(innerAngle);
      final innerY = cy + size * 0.4 * math.sin(innerAngle);
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(USAFlagEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isOn != isOn ||
        oldDelegate.brightness != brightness;
  }
}

/// Data class for sparkle properties
class SparkleData {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double twinkleOffset;
  final double burstPhase;

  SparkleData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.twinkleOffset,
    required this.burstPhase,
  });
}

/// Custom painter for Sparkle effect - draws twinkling sparkles
/// with configurable background and sparkle colors
class SparkleEffectPainter extends CustomPainter {
  final double animationValue;
  final Color backgroundColor;
  final Color sparkleColor;
  final int sparkleCount;
  final double minSize;
  final double maxSize;
  final double twinkleSpeed;
  final bool isOn;
  final double brightness;

  // Pre-generated sparkle data for consistent positioning
  static List<SparkleData>? _sparkles;
  static int? _lastSparkleCount;

  SparkleEffectPainter({
    required this.animationValue,
    required this.backgroundColor,
    required this.sparkleColor,
    required this.sparkleCount,
    required this.minSize,
    required this.maxSize,
    required this.twinkleSpeed,
    required this.isOn,
    required this.brightness,
  }) {
    // Initialize sparkles if not done or count changed
    if (_sparkles == null || _lastSparkleCount != sparkleCount) {
      _sparkles = [];
      _lastSparkleCount = sparkleCount;
      final random = math.Random(123); // Fixed seed for consistency
      
      for (int i = 0; i < sparkleCount; i++) {
        _sparkles!.add(SparkleData(
          x: random.nextDouble(), // 0-1 normalized position
          y: random.nextDouble(), // 0-1 normalized position
          size: minSize + random.nextDouble() * (maxSize - minSize),
          phase: random.nextDouble(), // Random phase offset for twinkle
          twinkleOffset: random.nextDouble() * 2 * math.pi, // Random twinkle start
          burstPhase: random.nextDouble(), // When this sparkle "bursts"
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Calculate effective opacity based on brightness
    final double effectiveOpacity;
    if (!isOn || brightness == 0) {
      effectiveOpacity = 0.15;
    } else {
      effectiveOpacity = 0.15 + (0.85 * (brightness / 100));
    }

    // Draw each sparkle
    for (final sparkle in _sparkles!) {
      _drawSparkle(
        canvas,
        size,
        sparkle: sparkle,
        opacity: effectiveOpacity,
      );
    }
  }

  void _drawSparkle(
    Canvas canvas,
    Size size, {
    required SparkleData sparkle,
    required double opacity,
  }) {
    final x = sparkle.x * size.width;
    final y = sparkle.y * size.height;
    
    // Calculate twinkle intensity using multiple sine waves for organic feel
    // Each sparkle has its own phase so they don't all twinkle together
    final twinkleBase = math.sin(
      (animationValue * twinkleSpeed * 2 * math.pi) + sparkle.twinkleOffset
    );
    
    // Add a secondary faster twinkle for shimmer effect
    final twinkleShimmer = math.sin(
      (animationValue * twinkleSpeed * 4 * math.pi) + sparkle.twinkleOffset * 2
    ) * 0.3;
    
    // Combine and normalize to 0-1 range
    final rawIntensity = (twinkleBase + twinkleShimmer + 1.3) / 2.6;
    
    // Apply easing to make bright moments more pronounced
    final intensity = math.pow(rawIntensity, 0.7);
    
    // Skip nearly invisible sparkles
    if (intensity < 0.05) return;
    
    final sparkleOpacity = intensity * opacity;
    final currentSize = sparkle.size * (0.5 + intensity * 0.5);
    
    // Draw outer glow
    final glowPaint = Paint()
      ..color = sparkleColor.withOpacity(sparkleOpacity * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentSize * 1.5);
    canvas.drawCircle(
      Offset(x, y),
      currentSize * 2,
      glowPaint,
    );
    
    // Draw sparkle core
    final corePaint = Paint()
      ..color = sparkleColor.withOpacity(sparkleOpacity * 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x, y),
      currentSize,
      corePaint,
    );
    
    // Draw bright white center for extra sparkle
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(sparkleOpacity * intensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x, y),
      currentSize * 0.4,
      centerPaint,
    );
    
    // Draw 4-point star rays for extra sparkle effect when bright
    if (intensity > 0.6) {
      final rayOpacity = (intensity - 0.6) / 0.4 * sparkleOpacity * 0.6;
      final rayLength = currentSize * 2.5 * intensity;
      final rayPaint = Paint()
        ..color = sparkleColor.withOpacity(rayOpacity)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      // Horizontal ray
      canvas.drawLine(
        Offset(x - rayLength, y),
        Offset(x + rayLength, y),
        rayPaint,
      );
      // Vertical ray
      canvas.drawLine(
        Offset(x, y - rayLength),
        Offset(x, y + rayLength),
        rayPaint,
      );
      // Diagonal rays (smaller)
      final diagLength = rayLength * 0.6;
      canvas.drawLine(
        Offset(x - diagLength, y - diagLength),
        Offset(x + diagLength, y + diagLength),
        rayPaint,
      );
      canvas.drawLine(
        Offset(x + diagLength, y - diagLength),
        Offset(x - diagLength, y + diagLength),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SparkleEffectPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isOn != isOn ||
        oldDelegate.brightness != brightness;
  }
}

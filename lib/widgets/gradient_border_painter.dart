import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────
// ALL LIGHTS / ZONES  —  Container Styling
//
// Every visual constant for the DeviceControlCard lives here so the
// look-and-feel can be tweaked in one place.
// ─────────────────────────────────────────────────────────────────────

/// Style constants for the ALL LIGHTS / ZONES container card.
class AllLightsZonesStyle {
  AllLightsZonesStyle._(); // non-instantiable

  // ── Card ──
  static const double cardHeight = 101.0;
  static const double cardBorderRadius = 20.0;
  static const Color cardBackgroundColor = Color(0xFF1D1D1D);
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 10);

  // ── Gradient border ──
  static const double gradientBorderWidth = 1.5;
  static const double gradientBorderOpacity = 0.5;
  static const double gradientBorderDarken = 0.65; // 0 = black, 1 = full color
  static const Duration gradientSpinDuration = Duration(seconds: 4);

  // ── Title ──
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ── ON / OFF buttons ──
  static const Color buttonBackgroundColor = Color(0xFF484848);
  static const Color buttonBorderColor = Color(0xFF3D3D3D);
  static const double buttonBorderRadius = 12.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 9);
  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  // ── Icon buttons ──
  static const double iconButtonRadius = 12.0;
  static const double iconButtonPadding = 10.0;
  static const double iconSize = 24.0;

  // ── Right-side action buttons ──
  static const Color colorPaletteBackground = Color(0xFF2A2A2A);
  static const Color colorPaletteBorder = Color(0xFF9E9E9E);

  static const Color brightnessBackground = Color(0xFF3D2508);
  static const Color brightnessBorder = Color(0xFFD4842A);

  static const Color imageViewActiveBackground = Color(0xFF3A7BD5);
  static const Color imageViewInactiveBackground = Color(0xFF0D1F33);
  static const Color imageViewBorder = Color(0xFF3A7BD5);
}

// ─────────────────────────────────────────────────────────────────────
// Gradient Border Painter
// ─────────────────────────────────────────────────────────────────────

/// A [CustomPainter] that draws a rounded-rectangle border whose stroke
/// is a smooth [SweepGradient] built from a list of colors.
///
/// Each colour occupies an equal arc around the perimeter and the list
/// wraps so the gradient is seamless. The gradient slowly rotates via
/// [animationValue] (0 → 1).
class GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double borderWidth;
  final double borderRadius;
  final double animationValue;

  GradientBorderPainter({
    required this.colors,
    this.borderWidth = AllLightsZonesStyle.gradientBorderWidth,
    this.borderRadius = AllLightsZonesStyle.cardBorderRadius,
    this.animationValue = 0.0,
  });

  /// Darkens and fades a colour for a subtle border appearance.
  Color _subtleColor(Color c) {
    final hsl = HSLColor.fromColor(c);
    final darkened = hsl
        .withLightness((hsl.lightness * AllLightsZonesStyle.gradientBorderDarken).clamp(0.0, 1.0))
        .toColor();
    return darkened.withValues(alpha: AllLightsZonesStyle.gradientBorderOpacity);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Build gradient colors that distribute evenly around the perimeter.
    // Each colour is darkened and made semi-transparent for a subtle look.
    final gradientColors = <Color>[];
    if (colors.length == 1) {
      final c = _subtleColor(colors[0]);
      gradientColors.addAll([c, c]);
    } else {
      // Forward pass + reverse pass = each color shows up twice (mirrored)
      gradientColors.addAll(colors.map(_subtleColor));
      gradientColors.addAll(colors.reversed.map(_subtleColor));
      gradientColors.add(_subtleColor(colors.first)); // seamless wrap
    }

    // Evenly distribute stops.
    final stops = List<double>.generate(
      gradientColors.length,
      (i) => i / (gradientColors.length - 1),
    );

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: gradientColors,
      stops: stops,
      // Slowly rotate the gradient for a living, breathing effect
      transform: GradientRotation(animationValue * math.pi * 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.animationValue != animationValue;
  }
}

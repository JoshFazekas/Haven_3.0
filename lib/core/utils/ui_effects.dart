import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../screens/effects/cascade_effect_screen.dart';

// ╔═══════════════════════════════════════════════════════════════════╗
// ║                       UI EFFECTS                                  ║
// ║                                                                   ║
// ║  Maps API `lightingStateName` JSON blobs into parsed effect       ║
// ║  models and their matching CustomPainters for display on          ║
// ║  light/zone cards.                                                ║
// ║                                                                   ║
// ║  Detection logic:                                                 ║
// ║    • lightingStatus == "EFFECT"                                   ║
// ║    • lightingStateName contains the JSON config string            ║
// ║                                                                   ║
// ║  Supported effect types:                                          ║
// ║    • Cascade  – detected by the presence of `colorSelections`     ║
// ║                                                                   ║
// ║  Future effect types will be added here as they are supported.    ║
// ╚═══════════════════════════════════════════════════════════════════╝

// ═══════════════════════════════════════════════════════════════════
//  1.  EFFECT TYPE ENUM
// ═══════════════════════════════════════════════════════════════════

/// Every effect type the app can parse and display.
enum UIEffectType {
  cascade,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════
//  2.  PARSED EFFECT MODEL
// ═══════════════════════════════════════════════════════════════════

/// A fully-parsed effect ready for UI rendering.
///
/// Create one via [UIEffect.parse] and then call [painter] to get the
/// matching [CustomPainter] for the light/zone card or preview strip.
class UIEffect {
  /// Which effect template this is.
  final UIEffectType type;

  /// Cascade-specific config. Non-null only when [type] == [UIEffectType.cascade].
  final CascadeEffectConfig? cascadeConfig;

  const UIEffect._({
    required this.type,
    this.cascadeConfig,
  });

  /// A placeholder for when no effect is playing.
  static const UIEffect none = UIEffect._(type: UIEffectType.unknown);

  // ─────────────── Factory: parse from API fields ───────────────

  /// Attempts to parse the API fields into a [UIEffect].
  ///
  /// Returns [UIEffect.none] if [lightingStatus] is not `"EFFECT"` or
  /// the config string cannot be decoded.
  ///
  /// ```dart
  /// final effect = UIEffect.parse(
  ///   lightingStatus: item.lightingStatus,
  ///   lightingStateName: item.lightingStateName,
  /// );
  /// if (effect.type != UIEffectType.unknown) { … }
  /// ```
  static UIEffect parse({
    required String? lightingStatus,
    required String? lightingStateName,
  }) {
    // We parse the effect config regardless of lightingStatus because the
    // API keeps the last effect config in lightingStateName even when the
    // light is OFF.  The card uses this to:
    //   • Show the animated effect when ON  (lightingStatus == "EFFECT")
    //   • Keep the effect's primary color as the border when OFF
    //
    // We only skip parsing when there's genuinely no effect config — i.e.
    // the light is on a solid color / white and lightingStateName is a
    // plain color name (not JSON).

    if (lightingStateName == null || lightingStateName.isEmpty) {
      return UIEffect.none;
    }

    // Quick check: if it doesn't look like JSON at all, skip
    final trimmed = lightingStateName.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith(r'\{') && !trimmed.startsWith(r'\"')) {
      return UIEffect.none;
    }

    try {
      // The API returns lightingStateName as a JSON-encoded string inside
      // the outer JSON response. After the HTTP response is decoded the
      // value is a plain Dart string that jsonDecode can handle directly.
      // In rare cases it might arrive double-encoded (still containing
      // literal backslash-quotes), so we try twice.
      dynamic decoded;
      try {
        decoded = jsonDecode(lightingStateName);
      } catch (_) {
        // Might be double-encoded — try stripping one layer of escaping
        final cleaned = lightingStateName
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
        decoded = jsonDecode(cleaned);
      }

      if (decoded is! Map<String, dynamic>) {
        debugPrint('UIEffect.parse: decoded value is not a Map — ${decoded.runtimeType}');
        return UIEffect.none;
      }

      debugPrint('UIEffect.parse: detected keys = ${decoded.keys.toList()}');
      return _parseFromJson(decoded);
    } catch (e) {
      debugPrint('UIEffect.parse: failed to decode lightingStateName — $e');
      debugPrint('UIEffect.parse: raw value = "$lightingStateName"');
      return UIEffect.none;
    }
  }

  /// Route to the correct parser based on JSON keys.
  static UIEffect _parseFromJson(Map<String, dynamic> json) {
    // ── Cascade: detected by the presence of "colorSelections" ──
    if (json.containsKey('colorSelections')) {
      final config = CascadeEffectConfig._fromJson(json);
      return UIEffect._(type: UIEffectType.cascade, cascadeConfig: config);
    }

    // ── Add future effect parsers here ──
    // if (json.containsKey('someOtherKey')) { … }

    return UIEffect.none;
  }

  // ─────────────── Painter factory ───────────────

  /// Returns the [CustomPainter] that should be used to render this
  /// effect on a card or preview strip.
  ///
  /// [animationValue] is the current 0.0–1.0 progress of the
  /// repeating animation controller on the card.
  CustomPainter? painter({required double animationValue}) {
    switch (type) {
      case UIEffectType.cascade:
        if (cascadeConfig == null) return null;
        return CascadePreviewPainter(
          animationValue: animationValue,
          colors: cascadeConfig!.colors,
          backgroundColor: cascadeConfig!.backgroundColor,
          ribbonSize: cascadeConfig!.ribbonSizeFeet,
          backgroundSize: cascadeConfig!.backgroundSizeFeet,
          speed: cascadeConfig!.speed,
        );
      case UIEffectType.unknown:
        return null;
    }
  }

  /// The primary/dominant color of this effect, useful for card
  /// border tinting.  Falls back to white.
  Color get primaryColor {
    switch (type) {
      case UIEffectType.cascade:
        return cascadeConfig?.colors.firstOrNull ?? Colors.white;
      case UIEffectType.unknown:
        return Colors.white;
    }
  }

  /// Whether this represents a valid, displayable effect.
  bool get isValid => type != UIEffectType.unknown;
}

// ═══════════════════════════════════════════════════════════════════
//  3.  CASCADE CONFIG
// ═══════════════════════════════════════════════════════════════════

/// Parsed configuration for a **Cascade** effect.
///
/// Example API JSON (escaped inside `lightingStateName`):
/// ```json
/// {
///   "colorSelections": ["0,100,100", "37,70,100", "120,100,100"],
///   "bgColor": [0.0, 0.0, 0.0],
///   "colorLength": 48.0,
///   "paddingLength": 24.0,
///   "transitionType": "None",
///   "movingSpeed": 94.0,
///   "enableMirror": 0,
///   "mirrorPosition": 0.0,
///   "oscAmp": 0.0,
///   "oscPeriod": 1.0
/// }
/// ```
///
/// Key mappings:
/// - `colorSelections`  → list of "H,S,V" strings → [colors] (the ribbon segments)
/// - `bgColor`          → [h, s, v] array → [backgroundColor] (padding color between ribbons)
/// - `colorLength`      → LED count → [ribbonSizeFeet] (÷ 12) — width of each color ribbon
/// - `paddingLength`    → LED count → [backgroundSizeFeet] (÷ 12) — gap between ribbons filled with bgColor
/// - `movingSpeed`      → 0–100 → [speed]
class CascadeEffectConfig {
  /// The ribbon colors, converted from HSV to Flutter [Color].
  final List<Color> colors;

  /// The background/padding color between ribbon segments.
  /// `null` only when paddingLength is 0 (ribbons touch with no gap).
  /// When bgColor is [0,0,0] this is black — a real color, not "no background".
  final Color? backgroundColor;

  /// Ribbon size in feet (derived from `colorLength` LED count ÷ 12).
  final double ribbonSizeFeet;

  /// Gap/padding size in feet (derived from `paddingLength` LED count ÷ 12).
  final double backgroundSizeFeet;

  /// Movement speed.  Positive = forward, negative = reverse.
  /// Range roughly -100 to +100.
  final double speed;

  /// Raw `colorLength` from the API (in LED count).
  final double colorLength;

  /// Raw `paddingLength` from the API (in LED count).
  final double paddingLength;

  const CascadeEffectConfig({
    required this.colors,
    this.backgroundColor,
    required this.ribbonSizeFeet,
    required this.backgroundSizeFeet,
    required this.speed,
    required this.colorLength,
    required this.paddingLength,
  });

  /// Parse from the decoded JSON blob.
  factory CascadeEffectConfig._fromJson(Map<String, dynamic> json) {
    // ── Colors: "H,S,V" strings → Flutter Colors ──
    final rawColors = (json['colorSelections'] as List<dynamic>?) ?? [];
    final colors = rawColors.map((entry) {
      return _hsvStringToColor(entry as String);
    }).toList();

    // ── Background color: [h, s, v] array ──
    // This is the padding color between each color ribbon segment.
    // bgColor = [0,0,0] means black padding (not "no background").
    // We only treat it as null (no gap) when paddingLength is 0.
    Color? bgColor;
    final rawBg = json['bgColor'];
    if (rawBg is List && rawBg.length >= 3) {
      final h = (rawBg[0] as num).toDouble();
      final s = (rawBg[1] as num).toDouble();
      final v = (rawBg[2] as num).toDouble();
      bgColor = HSVColor.fromAHSV(
        1.0,
        h.clamp(0.0, 360.0),
        (s / 100.0).clamp(0.0, 1.0),
        (v / 100.0).clamp(0.0, 1.0),
      ).toColor();
    }

    // ── Sizes: LED count → feet (12 LEDs per foot) ──
    final colorLength = (json['colorLength'] as num?)?.toDouble() ?? 48.0;
    final paddingLength = (json['paddingLength'] as num?)?.toDouble() ?? 24.0;
    final ribbonFeet = colorLength / 12.0;
    final bgFeet = paddingLength / 12.0;

    // If padding is effectively zero, there's no gap to render
    if (paddingLength <= 0) {
      bgColor = null;
    }

    // ── Speed ──
    final movingSpeed = (json['movingSpeed'] as num?)?.toDouble() ?? 0.0;

    return CascadeEffectConfig(
      colors: colors.isEmpty ? [Colors.white] : colors,
      backgroundColor: bgColor,
      ribbonSizeFeet: ribbonFeet.clamp(0.25, 100.0),
      backgroundSizeFeet: bgFeet.clamp(0.25, 100.0),
      speed: movingSpeed,
      colorLength: colorLength,
      paddingLength: paddingLength,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  White temperature HSV → predefined UI color mapping
  //
  //  The API encodes the 8 white temperatures as specific HSV
  //  values. When we detect these exact values, we substitute our
  //  richer predefined UI colors instead of doing a raw HSV→RGB
  //  conversion (which produces washed-out yellows).
  //
  //  HSV string        Temp    UI hex
  //  ──────────────    ─────   ──────────
  //  "26,94,100"  →    2700K → #F8E96C
  //  "26,92,100"  →    3000K → #F6F08E
  //  "31,87,100"  →    3500K → #F4F4AC
  //  "31,86,100"  →    3700K → #F2F4C2
  //  "32,82,100"  →    4000K → #ECF5DA
  //  "35,75,100"  →    4100K → #E3F3E9
  //  "33,73,100"  →    4700K → #DDF1F2
  //  "37,70,100"  →    5000K → #D6EFF6
  // ─────────────────────────────────────────────────────────────
  static const Map<String, Color> _whiteTemperatureMap = {
    '26,94,100': Color(0xFFF8E96C), // 2700K  Warm White
    '26,92,100': Color(0xFFF6F08E), // 3000K  Soft White
    '31,87,100': Color(0xFFF4F4AC), // 3500K  White
    '31,86,100': Color(0xFFF2F4C2), // 3700K  Cool White
    '32,82,100': Color(0xFFECF5DA), // 4000K  Bright White
    '35,75,100': Color(0xFFE3F3E9), // 4100K  Daylight
    '33,73,100': Color(0xFFDDF1F2), // 4700K  Ice White
    '37,70,100': Color(0xFFD6EFF6), // 5000K  Blue White
  };

  /// Converts an "H,S,V" string (e.g. "0,100,100") to a Flutter [Color].
  ///
  /// If the HSV string matches one of the 8 white temperature presets,
  /// the predefined UI color is returned instead of a raw HSV conversion.
  ///
  /// H = 0–360 (hue degrees)
  /// S = 0–100 (saturation percent)
  /// V = 0–100 (value/brightness percent)
  static Color _hsvStringToColor(String hsvString) {
    // Normalize whitespace for consistent lookups
    final normalized = hsvString.split(',').map((p) => p.trim()).join(',');

    // Check for a white temperature match first
    final whiteMatch = _whiteTemperatureMap[normalized];
    if (whiteMatch != null) return whiteMatch;

    final parts = normalized.split(',');
    if (parts.length < 3) return Colors.white;

    final h = double.tryParse(parts[0]) ?? 0.0;
    final s = double.tryParse(parts[1]) ?? 100.0;
    final v = double.tryParse(parts[2]) ?? 100.0;

    return HSVColor.fromAHSV(
      1.0,
      h.clamp(0.0, 360.0),
      (s / 100.0).clamp(0.0, 1.0),
      (v / 100.0).clamp(0.0, 1.0),
    ).toColor();
  }
}

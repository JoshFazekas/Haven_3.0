import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/utils/ui_effects.dart';
import 'effect_painters.dart';

// ─────────────────────────────────────────────────────────────────────
// Shared light-card visual component.
//
// Both the list-page LightZoneCard and the bottom card inside
// LightControlWrapper render through this single widget so they
// always look identical for the same light state.
// ─────────────────────────────────────────────────────────────────────

// White temperature color values to detect (must match ColorCapability whites)
const Set<int> _whiteTemperatureValues = {
  0xFFF8E96C, // 2700K
  0xFFF6F08E, // 3000K
  0xFFF4F4AC, // 3500K
  0xFFF2F4C2, // 3700K
  0xFFECF5DA, // 4000K
  0xFFE3F3E9, // 4100K
  0xFFDDF1F2, // 4700K
  0xFFD6EFF6, // 5000K
};

bool isWhiteTemperature(Color color) {
  return _whiteTemperatureValues.contains(color.value);
}

/// Calculates the card background and border colors for a light card.
///
/// Extracted so both LightZoneCard and LightControlWrapper use the
/// exact same logic — no visual drift.
({Color cardColor, Color borderColor}) computeCardColors({
  required bool isOn,
  required double brightness,
  required Color selectedColor,
  required Map<String, dynamic>? playingEffectConfig,
  required UIEffect apiEffect,
}) {
  final isPlayingEffect = playingEffectConfig != null;
  final isPlayingApiEffect = apiEffect.isValid && !isPlayingEffect;
  final isWhite = isWhiteTemperature(selectedColor);

  Color cardColor;
  Color borderColor;

  if (isPlayingApiEffect) {
    borderColor = isOn
        ? apiEffect.primaryColor.withOpacity(0.7)
        : apiEffect.primaryColor.withOpacity(0.35);
    cardColor = isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
  } else if (isPlayingEffect) {
    final effectType = playingEffectConfig['effectType'] as String?;

    if (effectType == 'wave3') {
      final waveConfig =
          playingEffectConfig['waveConfig'] as Map<String, dynamic>;
      final peakColor = waveConfig['peakColor'] as Color;
      borderColor = peakColor.withOpacity(0.7);
      cardColor = isOn ? const Color(0xFF1A1A1A) : const Color(0xFF1D1D1D);
    } else if (effectType == 'comet') {
      final cometConfig =
          playingEffectConfig['cometConfig'] as Map<String, dynamic>;
      final colors = (cometConfig['colors'] as List).cast<Color>();
      final primaryColor = colors.isNotEmpty ? colors[0] : Colors.purple;
      borderColor = primaryColor.withOpacity(0.7);
      cardColor = isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
    } else if (effectType == 'usaFlag') {
      borderColor = const Color(0xFF3C3B6E).withOpacity(0.7);
      cardColor = isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
    } else if (effectType == 'sparkle') {
      final sparkleConfig =
          playingEffectConfig['sparkleConfig'] as Map<String, dynamic>;
      final sparkleColor = sparkleConfig['sparkleColor'] as Color;
      borderColor = sparkleColor.withOpacity(0.7);
      final bgColor = sparkleConfig['backgroundColor'] as Color;
      cardColor = isOn ? bgColor : const Color(0xFF1D1D1D);
    } else {
      borderColor = Colors.white.withOpacity(0.3);
      cardColor = const Color(0xFF1D1D1D);
    }
  } else if (isWhite) {
    cardColor = isOn
        ? (brightness == 0
              ? const Color(0xFF212121)
              : Color.lerp(
                  const Color(0xFF1D1D1D),
                  selectedColor,
                  0.20 + (0.35 * (brightness / 100)),
                )!)
        : const Color(0xFF1D1D1D);
    borderColor = Color.lerp(
      const Color(0xFF1D1D1D),
      selectedColor,
      0.5,
    )!.withOpacity(0.7);
  } else {
    cardColor = isOn
        ? (brightness == 0
              ? const Color(0xFF212121)
              : HSLColor.fromColor(selectedColor)
                    .withLightness(
                      (HSLColor.fromColor(selectedColor).lightness * 0.18) +
                          (HSLColor.fromColor(selectedColor).lightness *
                              0.45 *
                              (brightness / 100)),
                    )
                    .toColor())
        : const Color(0xFF1D1D1D);
    borderColor = HSLColor.fromColor(selectedColor)
        .withLightness(HSLColor.fromColor(selectedColor).lightness * 0.4)
        .toColor()
        .withOpacity(0.7);
  }

  return (cardColor: cardColor, borderColor: borderColor);
}

/// Builds the effect background layers (wave, comet, sparkle, usa-flag,
/// API-driven effects) that sit behind the card content.
///
/// [cardHeight] lets callers pass their own height (88 for list card,
/// 115 for the control-wrapper card).
List<Widget> buildEffectBackgrounds({
  required bool isOn,
  required double brightness,
  required Map<String, dynamic>? playingEffectConfig,
  required UIEffect apiEffect,
  required AnimationController? effectAnimationController,
  required double cardHeight,
}) {
  final isPlayingEffect = playingEffectConfig != null;
  final isPlayingApiEffect = apiEffect.isValid && !isPlayingEffect;
  final widgets = <Widget>[];

  // Wave
  if (isPlayingEffect &&
      isOn &&
      playingEffectConfig['effectType'] == 'wave3' &&
      effectAnimationController != null) {
    widgets.add(
      Positioned.fill(
        child: AnimatedBuilder(
          animation: effectAnimationController,
          builder: (context, child) {
            final waveConfig =
                playingEffectConfig['waveConfig'] as Map<String, dynamic>;
            return CustomPaint(
              size: Size(double.infinity, cardHeight),
              painter: Wave3EffectPainter(
                animationValue: effectAnimationController.value,
                startColor: waveConfig['startColor'] as Color,
                peakColor: waveConfig['peakColor'] as Color,
                valleyColor: waveConfig['valleyColor'] as Color,
                waves: (waveConfig['waves'] as List)
                    .cast<Map<String, dynamic>>(),
                opacity: waveConfig['opacity'] as double,
                isOn: isOn,
                brightness: brightness,
              ),
            );
          },
        ),
      ),
    );
  }

  // Comet
  if (isPlayingEffect &&
      isOn &&
      playingEffectConfig['effectType'] == 'comet' &&
      effectAnimationController != null) {
    widgets.add(
      Positioned.fill(
        child: AnimatedBuilder(
          animation: effectAnimationController,
          builder: (context, child) {
            final cometConfig =
                playingEffectConfig['cometConfig'] as Map<String, dynamic>;
            return CustomPaint(
              size: Size(double.infinity, cardHeight),
              painter: CometEffectPainter(
                animationValue: effectAnimationController.value,
                colors: (cometConfig['colors'] as List).cast<Color>(),
                cometCount: cometConfig['cometCount'] as int,
                tailLength: cometConfig['tailLength'] as double,
                minSpeed: cometConfig['minSpeed'] as double,
                maxSpeed: cometConfig['maxSpeed'] as double,
                isOn: isOn,
                brightness: brightness,
              ),
            );
          },
        ),
      ),
    );
  }

  // USA Flag
  if (isPlayingEffect &&
      isOn &&
      playingEffectConfig['effectType'] == 'usaFlag' &&
      effectAnimationController != null) {
    widgets.add(
      Positioned.fill(
        child: AnimatedBuilder(
          animation: effectAnimationController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(double.infinity, cardHeight),
              painter: USAFlagEffectPainter(
                animationValue: effectAnimationController.value,
                isOn: isOn,
                brightness: brightness,
              ),
            );
          },
        ),
      ),
    );
  }

  // Sparkle
  if (isPlayingEffect &&
      isOn &&
      playingEffectConfig['effectType'] == 'sparkle' &&
      effectAnimationController != null) {
    widgets.add(
      Positioned.fill(
        child: AnimatedBuilder(
          animation: effectAnimationController,
          builder: (context, child) {
            final sparkleConfig =
                playingEffectConfig['sparkleConfig'] as Map<String, dynamic>;
            return CustomPaint(
              size: Size(double.infinity, cardHeight),
              painter: SparkleEffectPainter(
                animationValue: effectAnimationController.value,
                backgroundColor: sparkleConfig['backgroundColor'] as Color,
                sparkleColor: sparkleConfig['sparkleColor'] as Color,
                sparkleCount: sparkleConfig['sparkleCount'] as int,
                minSize: sparkleConfig['minSize'] as double,
                maxSize: sparkleConfig['maxSize'] as double,
                twinkleSpeed: sparkleConfig['twinkleSpeed'] as double,
                isOn: isOn,
                brightness: brightness,
              ),
            );
          },
        ),
      ),
    );
  }

  // API-driven effect (e.g. cascade from server)
  if (isPlayingApiEffect && isOn && effectAnimationController != null) {
    widgets.add(
      Positioned.fill(
        child: AnimatedBuilder(
          animation: effectAnimationController,
          builder: (context, child) {
            final painter = apiEffect.painter(
              animationValue: effectAnimationController.value,
            );
            if (painter == null) return const SizedBox.shrink();
            return CustomPaint(
              size: Size(double.infinity, cardHeight),
              painter: painter,
            );
          },
        ),
      ),
    );
  }

  // Dark overlay for API effects
  if (isPlayingApiEffect && isOn) {
    widgets.add(
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  return widgets;
}

/// Computes the active track color for the on/off switch.
Color? computeSwitchTrackColor({
  required bool isOn,
  required Color selectedColor,
  required bool isPlayingEffect,
  required bool isPlayingApiEffect,
}) {
  if (!isOn) return null;

  if (isPlayingEffect || isPlayingApiEffect) {
    return Colors.white.withOpacity(0.3);
  }

  if (isWhiteTemperature(selectedColor)) {
    return Color.lerp(const Color(0xFF2A2A2A), selectedColor, 0.3);
  }

  return HSLColor.fromColor(
    selectedColor,
  ).withLightness(HSLColor.fromColor(selectedColor).lightness * 0.3).toColor();
}

/// The visual body of a light card — background, effects, border.
///
/// This is a pure presentation widget: it receives all state as
/// parameters and renders the card.  The parent supplies callbacks
/// for toggle / menu / brightness / tap and decides the card height.
///
/// [bottomContent] is an optional widget placed below the toggle row
/// (e.g. the brightness slider in LightControlWrapper).
class LightCardBody extends StatelessWidget {
  final String lightName;
  final String? controllerTypeName;
  final bool isOn;
  final Color selectedColor;
  final double brightness;
  final double cardHeight;
  final Map<String, dynamic>? playingEffectConfig;
  final UIEffect apiEffect;
  final AnimationController? effectAnimationController;
  final EdgeInsetsGeometry padding;

  // Callbacks
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onMenuTap;
  final Widget? bottomContent;

  const LightCardBody({
    super.key,
    required this.lightName,
    this.controllerTypeName,
    required this.isOn,
    required this.selectedColor,
    required this.brightness,
    required this.cardHeight,
    this.playingEffectConfig,
    this.apiEffect = UIEffect.none,
    this.effectAnimationController,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.onToggleChanged,
    this.onMenuTap,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final isPlayingEffect = playingEffectConfig != null;
    final isPlayingApiEffect = apiEffect.isValid && !isPlayingEffect;

    final colors = computeCardColors(
      isOn: isOn,
      brightness: brightness,
      selectedColor: selectedColor,
      playingEffectConfig: playingEffectConfig,
      apiEffect: apiEffect,
    );

    final effectBgs = buildEffectBackgrounds(
      isOn: isOn,
      brightness: brightness,
      playingEffectConfig: playingEffectConfig,
      apiEffect: apiEffect,
      effectAnimationController: effectAnimationController,
      cardHeight: cardHeight,
    );

    final switchTrackColor = computeSwitchTrackColor(
      isOn: isOn,
      selectedColor: selectedColor,
      isPlayingEffect: isPlayingEffect,
      isPlayingApiEffect: isPlayingApiEffect,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderColor, width: 4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Effect backgrounds
              ...effectBgs,
              // Content overlay
              Padding(
                padding: padding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Light name + controller type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            lightName,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (controllerTypeName != null &&
                            controllerTypeName!.isNotEmpty)
                          Text(
                            controllerTypeName!,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    // Middle row: Toggle + menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.scale(
                          scale: 1.15,
                          alignment: Alignment.centerLeft,
                          child: Switch(
                            value: isOn,
                            onChanged: onToggleChanged,
                            activeColor: Colors.white,
                            activeTrackColor: switchTrackColor,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: const Color(0xFF3A3A3A),
                          ),
                        ),
                        if (onMenuTap != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onMenuTap,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Optional bottom content (e.g. brightness slider)
                    if (bottomContent != null) bottomContent!,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

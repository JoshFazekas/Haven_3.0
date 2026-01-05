import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/light_control_wrapper.dart';
import 'effect_painters.dart';

/// A card displaying a single light/zone with channel name and light name
class LightZoneCard extends StatefulWidget {
  final String channelName;
  final String lightName;
  final String? controllerTypeName;
  final int? lightId;
  final int? zoneId;
  final int? locationId;

  const LightZoneCard({
    super.key,
    required this.channelName,
    required this.lightName,
    this.controllerTypeName,
    this.lightId,
    this.zoneId,
    this.locationId,
  });

  @override
  State<LightZoneCard> createState() => _LightZoneCardState();
}

class _LightZoneCardState extends State<LightZoneCard>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  Color _selectedColor = Colors.orange;
  double _brightness = 100.0;
  Map<String, dynamic>? _playingEffectConfig;
  AnimationController? _effectAnimationController;

  // White temperature color values to detect
  static const Set<int> _whiteTemperatureValues = {
    0xFFF8E96C,
    0xFFF6F08E,
    0xFFF4F4AC,
    0xFFF2F4C2,
    0xFFECF5DA,
    0xFFE3F3E9,
    0xFFDDF1F2,
    0xFFD6EFF6,
  };

  bool _isWhiteTemperature(Color color) {
    return _whiteTemperatureValues.contains(color.value);
  }

  @override
  void initState() {
    super.initState();
    _effectAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _effectAnimationController?.dispose();
    super.dispose();
  }

  void _onToggleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOn = !_isOn;
    });
    debugPrint('Toggle tapped for ${widget.lightName}: $_isOn');
  }

  void _openColorPalette() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LightControlWrapper(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          locationId: widget.locationId,
          initialTabIndex: 0,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
          initialEffectConfig: _playingEffectConfig,
          onColorSelected: (Color color, bool isOn, double brightness, Map<String, dynamic>? effectConfig) {
            // Update the UI with the new color, state, brightness, and effect
            setState(() {
              _selectedColor = color;
              _isOn = isOn;
              _brightness = brightness;
              _playingEffectConfig = effectConfig;
              
              // Start or stop animation based on effect config
              if (effectConfig != null) {
                _effectAnimationController?.repeat();
              } else {
                _effectAnimationController?.stop();
                _effectAnimationController?.reset();
              }
            });
            debugPrint(
              'Light ${widget.lightName} updated: Color=$color, IsOn=$isOn, Brightness=$brightness, Effect=${effectConfig?['effectType']}',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlayingEffect = _playingEffectConfig != null;
    final isWhite = _isWhiteTemperature(_selectedColor);

    // Use different calculations for whites vs colors (matching LightControlWrapper)
    final Color cardColor;
    final Color borderColor;

    if (isPlayingEffect) {
      final effectType = _playingEffectConfig!['effectType'] as String?;
      
      if (effectType == 'wave3') {
        // Wave effect: use peak color for border
        final waveConfig =
            _playingEffectConfig!['waveConfig'] as Map<String, dynamic>;
        final peakColor = waveConfig['peakColor'] as Color;
        borderColor = peakColor.withOpacity(0.7);
        cardColor = _isOn ? const Color(0xFF1A1A1A) : const Color(0xFF1D1D1D);
      } else if (effectType == 'comet') {
        // Comet effect: use primary color for border
        final cometConfig =
            _playingEffectConfig!['cometConfig'] as Map<String, dynamic>;
        final colors = (cometConfig['colors'] as List).cast<Color>();
        final primaryColor = colors.isNotEmpty ? colors[0] : Colors.purple;
        borderColor = primaryColor.withOpacity(0.7);
        cardColor = _isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
      } else if (effectType == 'usaFlag') {
        // USA Flag effect: use blue for border
        borderColor = const Color(0xFF3C3B6E).withOpacity(0.7);
        cardColor = _isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
      } else if (effectType == 'sparkle') {
        // Sparkle effect: use sparkle color for border
        final sparkleConfig =
            _playingEffectConfig!['sparkleConfig'] as Map<String, dynamic>;
        final sparkleColor = sparkleConfig['sparkleColor'] as Color;
        borderColor = sparkleColor.withOpacity(0.7);
        final bgColor = sparkleConfig['backgroundColor'] as Color;
        cardColor = _isOn ? bgColor : const Color(0xFF1D1D1D);
      } else {
        borderColor = Colors.white.withOpacity(0.3);
        cardColor = const Color(0xFF1D1D1D);
      }
    } else if (isWhite) {
      // For whites: use Color.lerp for better blending
      cardColor = _isOn
          ? (_brightness == 0
                ? const Color(0xFF212121)
                : Color.lerp(
                    const Color(0xFF1D1D1D),
                    _selectedColor,
                    0.20 + (0.35 * (_brightness / 100)),
                  )!)
          : const Color(0xFF1D1D1D);
      borderColor = Color.lerp(
        const Color(0xFF1D1D1D),
        _selectedColor,
        0.5,
      )!.withOpacity(0.7);
    } else {
      // For colors: use HSL for richer color display
      cardColor = _isOn
          ? (_brightness == 0
                ? const Color(0xFF212121)
                : HSLColor.fromColor(_selectedColor)
                      .withLightness(
                        (HSLColor.fromColor(_selectedColor).lightness * 0.18) +
                            (HSLColor.fromColor(_selectedColor).lightness *
                                0.45 *
                                (_brightness / 100)),
                      )
                      .toColor())
          : const Color(0xFF1D1D1D);
      borderColor = HSLColor.fromColor(_selectedColor)
          .withLightness(HSLColor.fromColor(_selectedColor).lightness * 0.4)
          .toColor()
          .withOpacity(0.7);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: GestureDetector(
        onTap: _openColorPalette,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 88,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Wave effect background when playing and light is on
                  if (isPlayingEffect &&
                      _isOn &&
                      _playingEffectConfig!['effectType'] == 'wave3' &&
                      _effectAnimationController != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _effectAnimationController!,
                        builder: (context, child) {
                          final waveConfig =
                              _playingEffectConfig!['waveConfig']
                                  as Map<String, dynamic>;
                          return CustomPaint(
                            size: const Size(double.infinity, 88),
                            painter: Wave3EffectPainter(
                              animationValue: _effectAnimationController!.value,
                              startColor: waveConfig['startColor'] as Color,
                              peakColor: waveConfig['peakColor'] as Color,
                              valleyColor: waveConfig['valleyColor'] as Color,
                              waves: (waveConfig['waves'] as List)
                                  .cast<Map<String, dynamic>>(),
                              opacity: waveConfig['opacity'] as double,
                              isOn: _isOn,
                              brightness: _brightness,
                            ),
                          );
                        },
                      ),
                    ),
                  // Comet effect background when playing and light is on
                  if (isPlayingEffect &&
                      _isOn &&
                      _playingEffectConfig!['effectType'] == 'comet' &&
                      _effectAnimationController != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _effectAnimationController!,
                        builder: (context, child) {
                          final cometConfig =
                              _playingEffectConfig!['cometConfig']
                                  as Map<String, dynamic>;
                          return CustomPaint(
                            size: const Size(double.infinity, 88),
                            painter: CometEffectPainter(
                              animationValue: _effectAnimationController!.value,
                              colors: (cometConfig['colors'] as List).cast<Color>(),
                              cometCount: cometConfig['cometCount'] as int,
                              tailLength: cometConfig['tailLength'] as double,
                              minSpeed: cometConfig['minSpeed'] as double,
                              maxSpeed: cometConfig['maxSpeed'] as double,
                              isOn: _isOn,
                              brightness: _brightness,
                            ),
                          );
                        },
                      ),
                    ),
                  // USA Flag effect background when playing and light is on
                  if (isPlayingEffect &&
                      _isOn &&
                      _playingEffectConfig!['effectType'] == 'usaFlag' &&
                      _effectAnimationController != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _effectAnimationController!,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(double.infinity, 88),
                            painter: USAFlagEffectPainter(
                              animationValue: _effectAnimationController!.value,
                              isOn: _isOn,
                              brightness: _brightness,
                            ),
                          );
                        },
                      ),
                    ),
                  // Sparkle effect background when playing and light is on
                  if (isPlayingEffect &&
                      _isOn &&
                      _playingEffectConfig!['effectType'] == 'sparkle' &&
                      _effectAnimationController != null)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _effectAnimationController!,
                        builder: (context, child) {
                          final sparkleConfig =
                              _playingEffectConfig!['sparkleConfig']
                                  as Map<String, dynamic>;
                          return CustomPaint(
                            size: const Size(double.infinity, 88),
                            painter: SparkleEffectPainter(
                              animationValue: _effectAnimationController!.value,
                              backgroundColor: sparkleConfig['backgroundColor'] as Color,
                              sparkleColor: sparkleConfig['sparkleColor'] as Color,
                              sparkleCount: sparkleConfig['sparkleCount'] as int,
                              minSize: sparkleConfig['minSize'] as double,
                              maxSize: sparkleConfig['maxSize'] as double,
                              twinkleSpeed: sparkleConfig['twinkleSpeed'] as double,
                              isOn: _isOn,
                              brightness: _brightness,
                            ),
                          );
                        },
                      ),
                    ),
                  // Content overlay
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top row: Light name on left, Controller type on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Light name top left
                            Flexible(
                              child: Text(
                                widget.lightName,
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
                            // Controller type top right
                            if (widget.controllerTypeName != null &&
                                widget.controllerTypeName!.isNotEmpty)
                              Text(
                                widget.controllerTypeName!,
                                style: const TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        // Bottom row: Toggle on left, Menu on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Toggle switch bottom left
                            Transform.scale(
                              scale: 1.15,
                              alignment: Alignment.centerLeft,
                              child: Switch(
                                value: _isOn,
                                onChanged: (_) => _onToggleTap(),
                                activeColor: Colors.white,
                                activeTrackColor: _isOn
                                    ? (isPlayingEffect
                                          ? Colors.white.withOpacity(0.3)
                                          : (isWhite
                                                ? Color.lerp(
                                                    const Color(0xFF2A2A2A),
                                                    _selectedColor,
                                                    0.3,
                                                  )
                                                : HSLColor.fromColor(_selectedColor)
                                                      .withLightness(
                                                        HSLColor.fromColor(
                                                              _selectedColor,
                                                            ).lightness *
                                                            0.3,
                                                      )
                                                      .toColor()))
                                    : null,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: const Color(0xFF3A3A3A),
                              ),
                            ),
                            // 3-dot menu bottom right
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                debugPrint('Menu tapped for ${widget.lightName}');
                              },
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

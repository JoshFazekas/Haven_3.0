import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../widgets/effect_painters.dart';
import '../core/utils/color_capability.dart';
import 'create_effect_screen.dart';

// ─────────────── Tab definition ───────────────

/// The tabs a light control screen can show.
enum _TabDefinition {
  colors('Colors', 'assets/images/colorsicon.png'),
  whites('Whites', 'assets/images/whitesicon.png'),
  effects('Effects', ''),
  music('Music', 'assets/images/music.png');

  final String label;
  final String iconAsset;
  const _TabDefinition(this.label, this.iconAsset);
}

/// Determines which tabs to show based on capability and light type.
///
/// • Every light gets Colors + Whites (palette varies by capability).
/// • X Series ("TRIM LIGHT") also gets Effects + Music.
List<_TabDefinition> _buildAvailableTabs({
  required String? colorCapability,
  required String? lightType,
}) {
  final tabs = <_TabDefinition>[
    _TabDefinition.colors,
    _TabDefinition.whites,
  ];

  // X Series lights (TRIM LIGHT) get Effects + Music
  final isXSeries =
      lightType != null && lightType.toUpperCase() == 'TRIM LIGHT';
  if (isXSeries) {
    tabs.add(_TabDefinition.effects);
    tabs.add(_TabDefinition.music);
  }

  return tabs;
}

class LightControlWrapper extends StatefulWidget {
  final String lightName;
  final String? controllerTypeName;
  final Function(
    Color color,
    bool isOn,
    double brightness,
    Map<String, dynamic>? effectConfig,
  )?
  onColorSelected;
  final int? locationId;
  final int? lightId;
  final int? zoneId;
  final Color? initialColor;
  final bool? initialIsOn;
  final double? initialBrightness;
  final int initialTabIndex;
  final Map<String, dynamic>? initialEffectConfig;
  final String? colorCapability; // "Legacy" or "Extended"
  final String? lightType; // e.g. "TRIM LIGHT", "K SERIES", etc.

  const LightControlWrapper({
    super.key,
    required this.lightName,
    this.controllerTypeName,
    this.onColorSelected,
    this.locationId,
    this.lightId,
    this.zoneId,
    this.initialColor,
    this.initialIsOn,
    this.initialBrightness,
    this.initialTabIndex = 0,
    this.initialEffectConfig,
    this.colorCapability,
    this.lightType,
  });

  @override
  State<LightControlWrapper> createState() => _LightControlWrapperState();
}

class _LightControlWrapperState extends State<LightControlWrapper>
    with TickerProviderStateMixin {
  late int _selectedTabIndex;
  late Color _selectedColor;
  late bool _isOn;
  late double _brightness;

  /// Available tabs for this light, determined by colorCapability & lightType.
  late List<_TabDefinition> _tabs;
  bool _showBrightnessIndicator = false;
  Timer? _fadeTimer;
  AnimationController? _sliderFadeController;
  Animation<Color?>? _sliderColorAnimation;

  // Effect playing state
  Map<String, dynamic>? _playingEffectConfig;
  AnimationController? _effectAnimationController;

  // Effects tab folder selection state
  String? _effectsSelectedFolder;
  
  // Create effect view state
  bool _showCreateEffect = false;
  bool _inEffectConfigScreen = false; // Track if user is in an effect type config screen
  VoidCallback? _effectSaveCallback; // Save callback from effect config screens

  // Music tab animation controller
  AnimationController? _musicTabAnimationController;

  // Effects tab animation controller
  AnimationController? _effectsTabAnimationController;
  bool _effectsTabAnimationPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabs = _buildAvailableTabs(
      colorCapability: widget.colorCapability,
      lightType: widget.lightType,
    );
    _selectedTabIndex = widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _selectedColor = widget.initialColor ?? Colors.orange;
    _isOn = widget.initialIsOn ?? false;
    _brightness = widget.initialBrightness ?? 100.0;
    _playingEffectConfig = widget.initialEffectConfig;

    _sliderFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sliderColorAnimation =
        ColorTween(begin: Colors.white, end: const Color(0xFFB0B0B0)).animate(
          CurvedAnimation(
            parent: _sliderFadeController!,
            curve: Curves.easeInOut,
          ),
        );

    _effectAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // If there's an initial effect config, start the animation
    if (_playingEffectConfig != null) {
      _effectAnimationController?.repeat();
    }

    // Music tab animation controller
    _musicTabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _musicTabAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Keep animation at the last frame instead of looping
        _musicTabAnimationController!.stop();
      }
    });

    // Effects tab animation controller
    _effectsTabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _effectsTabAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Keep animation at the last frame instead of looping
        _effectsTabAnimationController!.stop();
        setState(() {
          _effectsTabAnimationPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _sliderFadeController?.dispose();
    _effectAnimationController?.dispose();
    _musicTabAnimationController?.dispose();
    _effectsTabAnimationController?.dispose();
    super.dispose();
  }

  void _onEffectStarted(Map<String, dynamic> effectConfig) {
    setState(() {
      _playingEffectConfig = effectConfig;
      _isOn = true;
    });
    _effectAnimationController?.repeat();
  }

  void _onEffectStopped() {
    setState(() {
      _playingEffectConfig = null;
      // Default to warm white (2700K) when effect is stopped
      _selectedColor = const Color(0xFFF8E96C);
    });
    _effectAnimationController?.stop();
    _effectAnimationController?.reset();
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) return;

    HapticFeedback.mediumImpact();
    
    // Reset create effect view when leaving Effects tab
    final oldTab = _tabs[_selectedTabIndex];
    final newTab = _tabs[index];

    if (oldTab == _TabDefinition.effects && newTab != _TabDefinition.effects) {
      _showCreateEffect = false;
    }
    
    // If Music tab is tapped, play animation from start
    if (newTab == _TabDefinition.music) {
      _musicTabAnimationController?.reset();
      _musicTabAnimationController?.forward();
    }
    
    // If Effects tab is tapped, play animation from start
    if (newTab == _TabDefinition.effects) {
      _effectsTabAnimationController?.reset();
      _effectsTabAnimationController?.forward();
      setState(() {
        _effectsTabAnimationPlaying = true;
      });
    }
    
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onColorChanged(Color color) {
    setState(() {
      _selectedColor = color;
      // Stop any playing effect when a color is selected
      if (_playingEffectConfig != null) {
        _playingEffectConfig = null;
        _effectAnimationController?.stop();
        _effectAnimationController?.reset();
      }
    });
  }

  void _onIsOnChanged(bool isOn) {
    setState(() {
      _isOn = isOn;
    });
  }

  void _onBrightnessChanged(double brightness) {
    setState(() {
      _brightness = brightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_tabs[_selectedTabIndex] == _TabDefinition.effects && _effectsSelectedFolder == 'My Effects' && !_showCreateEffect)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1.05),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _showCreateEffect = true;
                        });
                        debugPrint('Add effect button tapped');
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC56A21),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Restart animation by rebuilding
                  if (mounted &&
                      _tabs[_selectedTabIndex] == _TabDefinition.effects &&
                      _effectsSelectedFolder == 'My Effects') {
                    setState(() {});
                  }
                },
              ),
            ),
          if (_inEffectConfigScreen && _effectSaveCallback != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _effectSaveCallback?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (!_inEffectConfigScreen)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (widget.onColorSelected != null) {
                  widget.onColorSelected!(
                    _selectedColor,
                    _isOn,
                    _brightness,
                    _playingEffectConfig,
                  );
                }
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: !_showCreateEffect, // Allow content to extend to bottom when in create effect mode
        child: Column(
          children: [
            // Content area - switches between tab content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildTabContent(),
              ),
            ),
            // Floating tab selector - hide when in create effect screen
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCreateEffect
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTabSelector(),
                      ),
                    ),
            ),
            // Light card at the bottom - hide when in create effect screen
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCreateEffect
                  ? const SizedBox.shrink()
                  : _buildLightCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final currentTab = _tabs[_selectedTabIndex];
    switch (currentTab) {
      case _TabDefinition.colors:
        return ColorsTabContent(
          key: const ValueKey('colors'),
          selectedColor: _selectedColor,
          onColorChanged: _onColorChanged,
          isOn: _isOn,
          onIsOnChanged: _onIsOnChanged,
          onBrightnessChanged: _onBrightnessChanged,
          isEffectPlaying: _playingEffectConfig != null,
          colorCapability: widget.colorCapability,
        );
      case _TabDefinition.whites:
        return WhitesTabContent(
          key: const ValueKey('whites'),
          selectedColor: _selectedColor,
          onColorChanged: _onColorChanged,
          isOn: _isOn,
          onIsOnChanged: _onIsOnChanged,
          onBrightnessChanged: _onBrightnessChanged,
          isEffectPlaying: _playingEffectConfig != null,
          colorCapability: widget.colorCapability,
        );
      case _TabDefinition.effects:
        return EffectsTabContent(
          key: const ValueKey('effects'),
          selectedColor: _selectedColor,
          onColorChanged: _onColorChanged,
          onEffectStarted: _onEffectStarted,
          onEffectStopped: _onEffectStopped,
          playingEffectConfig: _playingEffectConfig,
          onFolderChanged: (folder) {
            setState(() {
              _effectsSelectedFolder = folder;
            });
          },
          showCreateEffect: _showCreateEffect,
          onCreateEffectBack: () {
            setState(() {
              _showCreateEffect = false;
              _inEffectConfigScreen = false;
              _effectSaveCallback = null;
            });
          },
          onConfigScreenChanged: (inConfigScreen) {
            setState(() {
              _inEffectConfigScreen = inConfigScreen;
            });
          },
          onSaveCallbackChanged: (saveCallback) {
            setState(() {
              _effectSaveCallback = saveCallback;
            });
          },
        );
      case _TabDefinition.music:
        return MusicTabContent(
          key: const ValueKey('music'),
          selectedColor: _selectedColor,
          onColorChanged: _onColorChanged,
        );
    }
  }

  // White temperature color values to detect (must match ColorCapability whites)
  static const Set<int> _whiteTemperatureValues = {
    0xFFFFAE5E, // 2700K
    0xFFFFC880, // 3000K
    0xFFFFDCA8, // 3500K
    0xFFFFE2B8, // 3700K
    0xFFFFEBCC, // 4000K
    0xFFFFEDD4, // 4100K
    0xFFF5F0E0, // 4700K
    0xFFF0F0F0, // 5000K
  };

  bool _isWhiteTemperature(Color color) {
    return _whiteTemperatureValues.contains(color.value);
  }

  Widget _buildLightCard() {
    final isPlayingEffect = _playingEffectConfig != null;
    final isWhite = _isWhiteTemperature(_selectedColor);

    // Use different calculations for whites vs colors
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
        // When off, use grey like other colors' off state
        cardColor = _isOn ? const Color(0xFF1A1A1A) : const Color(0xFF1D1D1D);
      } else if (effectType == 'comet') {
        // Comet effect: use primary color (first color) for border, black background
        final cometConfig =
            _playingEffectConfig!['cometConfig'] as Map<String, dynamic>;
        final colors = (cometConfig['colors'] as List).cast<Color>();
        final primaryColor = colors.isNotEmpty ? colors[0] : Colors.purple;
        borderColor = primaryColor.withOpacity(0.7);
        // Black background for comet effect, grey when off
        cardColor = _isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
      } else if (effectType == 'usaFlag') {
        // USA Flag effect: use blue for border (stars field color)
        borderColor = const Color(0xFF3C3B6E).withOpacity(0.7);
        // Black background for flag effect
        cardColor = _isOn ? const Color(0xFF000000) : const Color(0xFF1D1D1D);
      } else if (effectType == 'sparkle') {
        // Sparkle effect: use sparkle color for border
        final sparkleConfig =
            _playingEffectConfig!['sparkleConfig'] as Map<String, dynamic>;
        final sparkleColor = sparkleConfig['sparkleColor'] as Color;
        borderColor = sparkleColor.withOpacity(0.7);
        // Use background color from config
        final bgColor = sparkleConfig['backgroundColor'] as Color;
        cardColor = _isOn ? bgColor : const Color(0xFF1D1D1D);
      } else {
        // Default for other effect types
        borderColor = Colors.white.withOpacity(0.3);
        cardColor = _isOn ? const Color(0xFF1D1D1D) : const Color(0xFF1D1D1D);
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 9),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 115,
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
                          size: const Size(double.infinity, 115),
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
                          size: const Size(double.infinity, 115),
                          painter: CometEffectPainter(
                            animationValue: _effectAnimationController!.value,
                            colors: (cometConfig['colors'] as List)
                                .cast<Color>(),
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
                          size: const Size(double.infinity, 115),
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
                          size: const Size(double.infinity, 115),
                          painter: SparkleEffectPainter(
                            animationValue: _effectAnimationController!.value,
                            backgroundColor:
                                sparkleConfig['backgroundColor'] as Color,
                            sparkleColor:
                                sparkleConfig['sparkleColor'] as Color,
                            sparkleCount: sparkleConfig['sparkleCount'] as int,
                            minSize: sparkleConfig['minSize'] as double,
                            maxSize: sparkleConfig['maxSize'] as double,
                            twinkleSpeed:
                                sparkleConfig['twinkleSpeed'] as double,
                            isOn: _isOn,
                            brightness: _brightness,
                          ),
                        );
                      },
                    ),
                  ),
                // Content overlay
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.scale(
                            scale: 1.15,
                            alignment: Alignment.centerLeft,
                            child: Switch(
                              value: _isOn,
                              onChanged: (value) {
                                HapticFeedback.mediumImpact();
                                if (value && _brightness == 0) {
                                  // If turning on with brightness at 0, set to 100
                                  setState(() {
                                    _brightness = 100.0;
                                  });
                                }
                                _onIsOnChanged(value);
                              },
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
                                              : HSLColor.fromColor(
                                                      _selectedColor,
                                                    )
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
                      // Bottom row: Brightness slider with indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedBuilder(
                                  animation:
                                      _sliderFadeController ??
                                      AnimationController(vsync: this),
                                  builder: (context, child) {
                                    final sliderColor = _showBrightnessIndicator
                                        ? Colors.white
                                        : (_sliderColorAnimation?.value ??
                                              const Color(0xFFB0B0B0));

                                    return SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                        activeTrackColor: sliderColor,
                                        inactiveTrackColor: Colors.white
                                            .withOpacity(0.3),
                                        thumbColor: sliderColor,
                                        overlayColor: Colors.white.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _brightness,
                                        min: 0,
                                        max: 100,
                                        onChanged: (value) {
                                          _fadeTimer?.cancel();
                                          _sliderFadeController?.reset();

                                          setState(() {
                                            _brightness = value;
                                            _showBrightnessIndicator = true;
                                            if (value == 0 && _isOn) {
                                              _isOn = false;
                                            } else if (value > 0 && !_isOn) {
                                              _isOn = true;
                                            }
                                          });
                                        },
                                        onChangeStart: (value) {
                                          _fadeTimer?.cancel();
                                          _sliderFadeController?.reset();

                                          setState(() {
                                            _showBrightnessIndicator = true;
                                          });
                                        },
                                        onChangeEnd: (value) {
                                          HapticFeedback.mediumImpact();
                                          setState(() {
                                            _showBrightnessIndicator = false;
                                          });
                                          debugPrint(
                                            'Brightness set to: ${value.round()}%',
                                          );

                                          _fadeTimer?.cancel();
                                          _fadeTimer = Timer(
                                            const Duration(milliseconds: 500),
                                            () {
                                              _sliderFadeController?.forward();
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Brightness indicator
                          if (_showBrightnessIndicator)
                            Positioned(
                              top: -35,
                              left:
                                  (_brightness / 100) *
                                      (MediaQuery.of(context).size.width -
                                          110) +
                                  14 -
                                  5,
                              child: AnimatedOpacity(
                                opacity: _showBrightnessIndicator ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_brightness.round()}',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabCount = _tabs.length;

    return Container(
      width: tabCount == 2 ? 180.0 : 310.0,
      height: 77,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabCount;

          return Stack(
            children: [
              // Animated sliding indicator for selected tab
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _selectedTabIndex * tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: tabWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: -1,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab buttons
              Row(
                children: List.generate(tabCount, (index) {
                  final tab = _tabs[index];
                  final isSelected = _selectedTabIndex == index;
                  final isMusic = tab == _TabDefinition.music;
                  final isEffects = tab == _TabDefinition.effects;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.85,
                            child: isMusic
                                ? Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.8,
                                        colors: [
                                          Color(0xFF2A2A2A),
                                          Color(0xFF0A0A0A),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Lottie.asset(
                                        'assets/animations/music.json',
                                        width: 26,
                                        height: 26,
                                        fit: BoxFit.contain,
                                        controller: _musicTabAnimationController,
                                        onLoaded: (composition) {
                                          _musicTabAnimationController?.duration = composition.duration;
                                        },
                                      ),
                                    ),
                                  )
                                : isEffects
                                    ? Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          gradient: RadialGradient(
                                            center: Alignment.center,
                                            radius: 0.8,
                                            colors: [
                                              Color(0xFF1A3A6E),
                                              Color(0xFFEC202C),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: _effectsTabAnimationPlaying
                                              ? Lottie.asset(
                                                  'assets/animations/effecttab.json',
                                                  width: 22,
                                                  height: 22,
                                                  fit: BoxFit.contain,
                                                  controller: _effectsTabAnimationController,
                                                  onLoaded: (composition) {
                                                    _effectsTabAnimationController?.duration = composition.duration;
                                                  },
                                                )
                                              : Image.asset(
                                                  'assets/images/effecttab.png',
                                                  width: 22,
                                                  height: 22,
                                                  fit: BoxFit.contain,
                                                ),
                                        ),
                                      )
                                    : Image.asset(
                                        tab.iconAsset,
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.contain,
                                      ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFB0B0B0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Content-only widgets for each tab (no tab selector, no light card, no app bar)
class ColorsTabContent extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final bool isOn;
  final Function(bool) onIsOnChanged;
  final Function(double) onBrightnessChanged;
  final bool isEffectPlaying;
  final String? colorCapability;

  const ColorsTabContent({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.isOn,
    required this.onIsOnChanged,
    required this.onBrightnessChanged,
    this.isEffectPlaying = false,
    this.colorCapability,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorCapability.getColors(colorCapability);

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 0),
      child: GridView.builder(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 0.9,
        ),
        itemCount: palette.length,
        itemBuilder: (context, index) {
          final entry = palette[index];
          final colorName = entry['name'] as String;
          final color = entry['color'] as Color;
          // No color is selected when an effect is playing
          final isSelected = !isEffectPlaying && color == selectedColor;

          final displayColor = isSelected
              ? color
              : HSLColor.fromColor(color)
                    .withLightness(HSLColor.fromColor(color).lightness * 0.55)
                    .toColor();

          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onColorChanged(color);
              if (!isOn) {
                onBrightnessChanged(100.0);
                onIsOnChanged(true);
              }
              debugPrint('Color selected: $colorName - $color');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 4)
                    : Border.all(color: Colors.transparent, width: 4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              transform: isSelected
                  ? Matrix4.identity().scaled(1.05)
                  : Matrix4.identity(),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: isSelected ? 13 : 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: Colors.black,
                  ),
                  child: Text(colorName, textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WhitesTabContent extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final bool isOn;
  final Function(bool) onIsOnChanged;
  final Function(double) onBrightnessChanged;
  final bool isEffectPlaying;
  final String? colorCapability;

  const WhitesTabContent({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.isOn,
    required this.onIsOnChanged,
    required this.onBrightnessChanged,
    this.isEffectPlaying = false,
    this.colorCapability,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorCapability.getWhites(colorCapability);

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 0),
      child: GridView.builder(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 0.9,
        ),
        itemCount: palette.length,
        itemBuilder: (context, index) {
          final entry = palette[index];
          final tempName = entry['name'] as String;
          final color = entry['color'] as Color;
          // No color is selected when an effect is playing
          final isSelected = !isEffectPlaying && color == selectedColor;

          final displayColor = isSelected
              ? color
              : Color.fromRGBO(color.red, color.green, color.blue, 0.6);

          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onColorChanged(color);
              if (!isOn) {
                onBrightnessChanged(100.0);
                onIsOnChanged(true);
              }
              debugPrint('White temperature selected: $tempName - $color');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 4)
                    : Border.all(color: Colors.transparent, width: 4),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              transform: isSelected
                  ? Matrix4.identity().scaled(1.05)
                  : Matrix4.identity(),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: isSelected ? 13 : 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: Colors.black,
                  ),
                  child: Text(tempName, textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EffectsTabContent extends StatefulWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final Function(Map<String, dynamic> effectConfig)? onEffectStarted;
  final Function()? onEffectStopped;
  final Map<String, dynamic>? playingEffectConfig;
  final Function(String?)? onFolderChanged;
  final bool showCreateEffect;
  final VoidCallback? onCreateEffectBack;
  final Function(bool)? onConfigScreenChanged; // Notify parent about config screen state
  final Function(VoidCallback?)? onSaveCallbackChanged; // Pass save callback from effect config screens

  const EffectsTabContent({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.onEffectStarted,
    this.onEffectStopped,
    this.playingEffectConfig,
    this.onFolderChanged,
    this.showCreateEffect = false,
    this.onCreateEffectBack,
    this.onConfigScreenChanged,
    this.onSaveCallbackChanged,
  });

  @override
  State<EffectsTabContent> createState() => _EffectsTabContentState();
}

class _EffectsTabContentState extends State<EffectsTabContent>
    with TickerProviderStateMixin {
  int? _pressedPlayIndex;
  int? _sendingIndex;
  List<String> _folderPath = []; // Track nested folder navigation
  AnimationController? _sendingAnimationController;
  Animation<double>? _sendingAnimation;
  AnimationController? _waveAnimationController;

  @override
  void initState() {
    super.initState();
    _sendingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sendingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendingAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _sendingAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _sendingIndex = null;
        });
        _sendingAnimationController!.reset();
        _waveAnimationController!.repeat();
      }
    });
  }

  @override
  void dispose() {
    _sendingAnimationController?.dispose();
    _waveAnimationController?.dispose();
    super.dispose();
  }

  // Preset folders data
  static const Map<String, List<Map<String, dynamic>>> _presetFolders = {
    'My Effects': [
      {
        'name': 'Halloween Fade',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF6053A2),
          'peakColor': Color(0xFFEC2180),
          'valleyColor': Color(0xFF1A1A40),
          'waves': [
            {
              'wavelength': 2.5,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 1.5,
              'amplitude': 0.5,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.33,
            },
            {
              'wavelength': 0.8,
              'amplitude': 0.3,
              'speed': 2.0,
              'direction': 1.0,
              'phase': 0.66,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Valentines Comets',
        'type': 'Comet',
        'effectType': 'comet',
        'cometConfig': {
          'colors': [Color(0xFF6053A2), Color(0xFFEC2180), Color(0xFF1A1A40)],
          'cometCount': 5,
          'tailLength': 0.25,
          'minSpeed': 1.0,
          'maxSpeed': 3.0,
        },
      },
      {'name': 'America', 'type': 'USA Flag', 'effectType': 'usaFlag'},
      {
        'name': 'Halloween Sparkle',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF000000),
          'sparkleColor': Color(0xFFFF6B00),
          'sparkleCount': 25,
          'minSize': 2.0,
          'maxSize': 6.0,
          'twinkleSpeed': 2.0,
        },
      },
    ],
    // Holidays folder now contains subfolders - effects moved to _holidaySubfolders
    'Holidays': [],
    'Sports': [
      {'name': 'America', 'type': 'USA Flag', 'effectType': 'usaFlag'},
      {
        'name': 'Team Spirit Wave',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFFEC202C),
          'valleyColor': Color(0xFFFFFFFF),
          'waves': [
            {
              'wavelength': 1.8,
              'amplitude': 0.8,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Victory Gold',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF1A1A1A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 35,
          'minSize': 3.0,
          'maxSize': 8.0,
          'twinkleSpeed': 2.5,
        },
      },
      {
        'name': 'Game Day Red',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC202C),
          'peakColor': Color(0xFFFF4040),
          'valleyColor': Color(0xFF8B0000),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.5,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Game Day Blue',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFF5080FF),
          'valleyColor': Color(0xFF1A2A5A),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.5,
              'direction': -1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Game Day Green',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF00A86B),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFF0A3D1A),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.5,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Game Day Orange',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFFF6B00),
          'peakColor': Color(0xFFFAA819),
          'valleyColor': Color(0xFF8B3A00),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.5,
              'direction': -1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Game Day Purple',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF6053A2),
          'peakColor': Color(0xFF8A7FD4),
          'valleyColor': Color(0xFF2A1A5A),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.5,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
      {
        'name': 'Stadium Lights',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A0A0A),
          'sparkleColor': Color(0xFFFFFFFF),
          'sparkleCount': 50,
          'minSize': 2.0,
          'maxSize': 6.0,
          'twinkleSpeed': 4.0,
        },
      },
      {
        'name': 'Rally Time',
        'type': 'Comet',
        'effectType': 'comet',
        'cometConfig': {
          'colors': [Color(0xFFFFD700), Color(0xFFFFFFFF)],
          'cometCount': 8,
          'tailLength': 0.2,
          'minSpeed': 2.0,
          'maxSpeed': 4.0,
        },
      },
      {
        'name': 'Championship Gold',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFFFD700),
          'peakColor': Color(0xFFFFF8DC),
          'valleyColor': Color(0xFFB8860B),
          'waves': [
            {
              'wavelength': 1.5,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 1.0,
              'amplitude': 0.4,
              'speed': 1.5,
              'direction': -1.0,
              'phase': 0.5,
            },
          ],
          'opacity': 0.85,
        },
      },
    ],
    'Causes': [
      {
        'name': 'Breast Cancer Awareness',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC2180),
          'peakColor': Color(0xFFC94D9B),
          'valleyColor': Color(0xFFFFFFFF),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Autism Awareness',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFFFDD901),
          'valleyColor': Color(0xFFEC202C),
          'waves': [
            {
              'wavelength': 1.8,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 1.2,
              'amplitude': 0.4,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.5,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Mental Health',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF00A86B),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFFFFFFFF),
          'waves': [
            {
              'wavelength': 2.2,
              'amplitude': 0.5,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.75,
        },
      },
      {
        'name': 'Veterans Support',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFFFFFFFF),
          'valleyColor': Color(0xFFEC202C),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
    ],
  };

  // Holiday subfolders structure
  static const Map<String, List<Map<String, dynamic>>> _holidaySubfolders = {
    'New Year\'s': [
      {
        'name': 'New Years Eve',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A0A1A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 40,
          'minSize': 2.0,
          'maxSize': 10.0,
          'twinkleSpeed': 3.0,
        },
      },
      {
        'name': 'Midnight Celebration',
        'type': 'Comet',
        'effectType': 'comet',
        'cometConfig': {
          'colors': [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFC0C0C0)],
          'cometCount': 8,
          'tailLength': 0.25,
          'minSpeed': 2.0,
          'maxSpeed': 4.0,
        },
      },
    ],
    'Valentine\'s Day': [
      {
        'name': 'Valentines Day',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC2180),
          'peakColor': Color(0xFFFF4D6D),
          'valleyColor': Color(0xFF8B0A3A),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Love Sparkle',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF2A0A1A),
          'sparkleColor': Color(0xFFFF69B4),
          'sparkleCount': 30,
          'minSize': 2.0,
          'maxSize': 8.0,
          'twinkleSpeed': 2.5,
        },
      },
    ],
    'St. Patrick\'s Day': [
      {
        'name': 'St Patricks Day',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF00A86B),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFF2E5A1C),
          'waves': [
            {
              'wavelength': 1.8,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Lucky Sparkle',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A2A0A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 20,
          'minSize': 3.0,
          'maxSize': 8.0,
          'twinkleSpeed': 2.5,
        },
      },
    ],
    'Easter': [
      {
        'name': 'Easter Pastels',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFFFB6C1),
          'peakColor': Color(0xFF87CEEB),
          'valleyColor': Color(0xFF98FB98),
          'waves': [
            {
              'wavelength': 2.2,
              'amplitude': 0.5,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 1.4,
              'amplitude': 0.4,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.5,
            },
          ],
          'opacity': 0.75,
        },
      },
      {
        'name': 'Spring Bloom',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF1A2A1A),
          'sparkleColor': Color(0xFFFFB6C1),
          'sparkleCount': 25,
          'minSize': 2.0,
          'maxSize': 6.0,
          'twinkleSpeed': 2.0,
        },
      },
    ],
    'Memorial Day': [
      {
        'name': 'Memorial Day',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC202C),
          'peakColor': Color(0xFFFFFFFF),
          'valleyColor': Color(0xFF4165AF),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {'name': 'America', 'type': 'USA Flag', 'effectType': 'usaFlag'},
    ],
    'Independence Day': [
      {
        'name': 'Fourth of July',
        'type': 'Comet',
        'effectType': 'comet',
        'cometConfig': {
          'colors': [Color(0xFFEC202C), Color(0xFFFFFFFF), Color(0xFF4165AF)],
          'cometCount': 6,
          'tailLength': 0.3,
          'minSpeed': 2.0,
          'maxSpeed': 4.0,
        },
      },
      {'name': 'America', 'type': 'USA Flag', 'effectType': 'usaFlag'},
      {
        'name': 'Fireworks',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF000000),
          'sparkleColor': Color(0xFFFFFFFF),
          'sparkleCount': 50,
          'minSize': 2.0,
          'maxSize': 10.0,
          'twinkleSpeed': 4.0,
        },
      },
    ],
    'Halloween': [
      {
        'name': 'Halloween Fade',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF6053A2),
          'peakColor': Color(0xFFEC2180),
          'valleyColor': Color(0xFF1A1A40),
          'waves': [
            {
              'wavelength': 2.5,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 0.8,
              'amplitude': 0.3,
              'speed': 2.0,
              'direction': 1.0,
              'phase': 0.66,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Halloween Sparkle',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF000000),
          'sparkleColor': Color(0xFFFF6B00),
          'sparkleCount': 25,
          'minSize': 2.0,
          'maxSize': 6.0,
          'twinkleSpeed': 2.0,
        },
      },
      {
        'name': 'Spooky Purple',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF2D0A4E),
          'peakColor': Color(0xFF6A0DAD),
          'valleyColor': Color(0xFF1A0A2A),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
    ],
    'Thanksgiving': [
      {
        'name': 'Thanksgiving',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFD2691E),
          'peakColor': Color(0xFFFAA819),
          'valleyColor': Color(0xFF8B4513),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Autumn Glow',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF1A1008),
          'sparkleColor': Color(0xFFFAA819),
          'sparkleCount': 20,
          'minSize': 3.0,
          'maxSize': 8.0,
          'twinkleSpeed': 2.0,
        },
      },
    ],
    'Hanukkah': [
      {
        'name': 'Hanukkah',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFFFFFFFF),
          'valleyColor': Color(0xFF1A3A6A),
          'waves': [
            {
              'wavelength': 1.8,
              'amplitude': 0.6,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Menorah Glow',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A1A3A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 8,
          'minSize': 4.0,
          'maxSize': 10.0,
          'twinkleSpeed': 1.5,
        },
      },
    ],
    'Diwali': [
      {
        'name': 'Festival of Lights',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF1A0A2A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 50,
          'minSize': 2.0,
          'maxSize': 8.0,
          'twinkleSpeed': 3.0,
        },
      },
      {
        'name': 'Diwali Colors',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFFF6B00),
          'peakColor': Color(0xFFFFD700),
          'valleyColor': Color(0xFFEC2180),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.0,
            },
          ],
          'opacity': 0.85,
        },
      },
    ],
    'Christmas': [
      {
        'name': 'Christmas Magic',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC202C),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFFFFFFFF),
          'waves': [
            {
              'wavelength': 2.0,
              'amplitude': 0.7,
              'speed': 1.0,
              'direction': -1.0,
              'phase': 0.0,
            },
            {
              'wavelength': 1.5,
              'amplitude': 0.5,
              'speed': 1.0,
              'direction': 1.0,
              'phase': 0.33,
            },
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Christmas Sparkle',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A3D0A),
          'sparkleColor': Color(0xFFFFD700),
          'sparkleCount': 30,
          'minSize': 2.0,
          'maxSize': 8.0,
          'twinkleSpeed': 2.5,
        },
      },
      {
        'name': 'Winter Wonderland',
        'type': 'Sparkle',
        'effectType': 'sparkle',
        'sparkleConfig': {
          'backgroundColor': Color(0xFF0A1A2A),
          'sparkleColor': Color(0xFFFFFFFF),
          'sparkleCount': 35,
          'minSize': 2.0,
          'maxSize': 6.0,
          'twinkleSpeed': 2.0,
        },
      },
    ],
  };

  void _openFolder(String folderName) {
    HapticFeedback.mediumImpact();
    setState(() {
      _folderPath.add(folderName);
    });
    widget.onFolderChanged?.call(folderName);
  }

  void _goBack() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_folderPath.isNotEmpty) {
        _folderPath.removeLast();
      }
    });
    widget.onFolderChanged?.call(_folderPath.isEmpty ? null : _folderPath.last);
  }

  String _getFolderImage(String folderName) {
    switch (folderName) {
      case 'My Effects':
        return 'assets/images/myeffects.png';
      case 'Holidays':
        return 'assets/images/holiday.png';
      case 'Sports':
        return 'assets/images/sportseffects.png';
      case 'Causes':
        return 'assets/images/cause.png';
      default:
        return 'assets/images/myeffects.png';
    }
  }

  String _getFolderAnimation(String folderName) {
    switch (folderName) {
      case 'My Effects':
        return 'assets/animations/myeffectsreveal.json';
      case 'Holidays':
        return 'assets/animations/holidayreveal.json';
      case 'Sports':
        return 'assets/animations/sportsreveal.json';
      case 'Causes':
        return 'assets/animations/causereveal.json';
      // Holiday subfolder animations - use holiday animation for all
      case 'New Year\'s':
      case 'Valentine\'s Day':
      case 'St. Patrick\'s Day':
      case 'Easter':
      case 'Memorial Day':
      case 'Independence Day':
      case 'Halloween':
      case 'Thanksgiving':
      case 'Hanukkah':
      case 'Diwali':
      case 'Christmas':
        return 'assets/animations/holidayreveal.json';
      default:
        return 'assets/animations/myeffectsreveal.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show create effect view when triggered from app bar
    if (widget.showCreateEffect) {
      return CreateEffectContent(
        onBack: () {
          widget.onCreateEffectBack?.call();
        },
        onConfigScreenChanged: widget.onConfigScreenChanged,
        onSaveCallbackChanged: widget.onSaveCallbackChanged,
      );
    }
    
    if (_folderPath.isEmpty) {
      return _buildFoldersGrid();
    } else if (_folderPath.length == 1 && _folderPath[0] == 'Holidays') {
      // Show holiday subfolders
      return _buildHolidaySubfoldersGrid();
    } else if (_folderPath.length == 2 && _folderPath[0] == 'Holidays') {
      // Show effects in holiday subfolder
      return _buildEffectsList(_folderPath[1], isSubfolder: true);
    } else {
      return _buildEffectsList(_folderPath[0]);
    }
  }

  Widget _buildFoldersGrid() {
    final folders = _presetFolders.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folderName = folders[index];

          // For Holidays, show subfolder count; for others, show effect count
          final String countText;
          if (folderName == 'Holidays') {
            final subfolderCount = _holidaySubfolders.keys.length;
            countText = '$subfolderCount categories';
          } else {
            final effectCount = _presetFolders[folderName]!.length;
            countText = '$effectCount effects';
          }

          return GestureDetector(
            onTap: () => _openFolder(folderName),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Lottie.asset(
                        _getFolderAnimation(folderName),
                        fit: BoxFit.contain,
                        repeat: false,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to static image if animation fails
                          return Image.asset(
                            _getFolderImage(folderName),
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      folderName,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countText,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Holiday dates for sorting (month, day) - approximate for variable holidays
  static const Map<String, List<int>> _holidayDates = {
    'New Year\'s': [1, 1],
    'Valentine\'s Day': [2, 14],
    'St. Patrick\'s Day': [3, 17],
    'Easter': [4, 20], // Approximate - varies each year
    'Memorial Day': [5, 26], // Last Monday of May - approximate
    'Independence Day': [7, 4],
    'Halloween': [10, 31],
    'Thanksgiving': [11, 28], // Fourth Thursday of November - approximate
    'Hanukkah': [12, 15], // Varies - approximate
    'Diwali': [11, 1], // Varies - approximate
    'Christmas': [12, 25],
  };

  // Calculate days until a holiday from today
  int _daysUntilHoliday(String holidayName) {
    final now = DateTime.now();
    final holidayDate = _holidayDates[holidayName];
    if (holidayDate == null) return 365;

    final month = holidayDate[0];
    final day = holidayDate[1];

    // Create this year's holiday date
    var holidayThisYear = DateTime(now.year, month, day);

    // If the holiday has passed this year, use next year's date
    if (holidayThisYear.isBefore(now) ||
        (holidayThisYear.day == now.day &&
            holidayThisYear.month == now.month &&
            holidayThisYear.year == now.year)) {
      // If it's today, show it first (0 days)
      if (holidayThisYear.day == now.day &&
          holidayThisYear.month == now.month) {
        return 0;
      }
      holidayThisYear = DateTime(now.year + 1, month, day);
    }

    return holidayThisYear.difference(now).inDays;
  }

  // Get holidays sorted by upcoming date
  List<String> _getSortedHolidays() {
    final holidays = _holidaySubfolders.keys.toList();
    holidays.sort(
      (a, b) => _daysUntilHoliday(a).compareTo(_daysUntilHoliday(b)),
    );
    return holidays;
  }

  Widget _buildHolidaySubfoldersGrid() {
    final subfolders = _getSortedHolidays();

    return Column(
      children: [
        // Back button header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _goBack,
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      _getFolderImage('Holidays'),
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Holidays',
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
        // Subfolders grid
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
              itemCount: subfolders.length,
              itemBuilder: (context, index) {
                final subfolderName = subfolders[index];
                final effectCount = _holidaySubfolders[subfolderName]!.length;

                return GestureDetector(
                  onTap: () => _openFolder(subfolderName),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: _getSubfolderIcon(subfolderName),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subfolderName,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$effectCount effects',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getHolidayImage(String subfolderName) {
    switch (subfolderName) {
      case 'New Year\'s':
        return 'assets/images/newyears.png';
      case 'Valentine\'s Day':
        return 'assets/images/valentines.png';
      case 'St. Patrick\'s Day':
        return 'assets/images/stpats.png';
      case 'Easter':
        return 'assets/images/easter.png';
      case 'Memorial Day':
        return 'assets/images/memorial.png';
      case 'Independence Day':
        return 'assets/images/4th.png';
      case 'Halloween':
        return 'assets/images/halloween.png';
      case 'Thanksgiving':
        return 'assets/images/thanksgiving.png';
      case 'Hanukkah':
        return 'assets/images/hanukkah.png';
      case 'Diwali':
        return 'assets/images/diwali.png';
      case 'Christmas':
        return 'assets/images/christmas.png';
      default:
        return 'assets/images/holiday.png';
    }
  }

  String _getHolidayAnimation(String subfolderName) {
    switch (subfolderName) {
      case 'New Year\'s':
        return 'assets/animations/newyears.json';
      case 'Valentine\'s Day':
        return 'assets/animations/valentines.json';
      case 'St. Patrick\'s Day':
        return 'assets/animations/stpats.json';
      case 'Easter':
        return 'assets/animations/easter.json';
      case 'Memorial Day':
        return 'assets/animations/memorial.json';
      case 'Independence Day':
        return 'assets/animations/4th.json';
      case 'Halloween':
        return 'assets/animations/halloween.json';
      case 'Thanksgiving':
        return 'assets/animations/thanksgiving.json';
      case 'Hanukkah':
        return 'assets/animations/hanukkah.json';
      case 'Diwali':
        return 'assets/animations/diwali.json';
      case 'Christmas':
        return 'assets/animations/christmas.json';
      default:
        return 'assets/animations/holiday.json';
    }
  }

  Widget _getSubfolderIcon(String subfolderName) {
    return Lottie.asset(
      _getHolidayAnimation(subfolderName),
      fit: BoxFit.contain,
      repeat: false,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to static image if animation fails
        return Image.asset(
          _getHolidayImage(subfolderName),
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        );
      },
    );
  }

  Widget _buildEffectsList(String folderName, {bool isSubfolder = false}) {
    final effects = isSubfolder
        ? (_holidaySubfolders[folderName] ?? [])
        : (_presetFolders[folderName] ?? []);

    return Column(
      children: [
        // Back button header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _goBack,
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 2),
                    isSubfolder
                        ? Image.asset(
                            _getHolidayImage(folderName),
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            _getFolderImage(folderName),
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                folderName,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Effects list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              itemCount: effects.length,
              itemBuilder: (context, index) {
                final effect = effects[index];
                final isPlayPressed = _pressedPlayIndex == index;
                final isSending = _sendingIndex == index;
                final isPlaying =
                    widget.playingEffectConfig != null &&
                    widget.playingEffectConfig!['name'] == effect['name'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effect['name'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      effect['type'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTapDown: (_) {
                                  if (!isPlaying) {
                                    setState(() {
                                      _pressedPlayIndex = index;
                                    });
                                  }
                                },
                                onTapUp: (_) {
                                  if (isPlaying) {
                                    HapticFeedback.mediumImpact();
                                    _waveAnimationController!.stop();
                                    _waveAnimationController!.reset();
                                    widget.onEffectStopped?.call();
                                    debugPrint('Stop ${effect['name']}');
                                  } else {
                                    HapticFeedback.mediumImpact();
                                    if (widget.onEffectStarted != null) {
                                      widget.onEffectStarted!(effect);
                                    }
                                    debugPrint('Play ${effect['name']}');

                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        if (mounted) {
                                          setState(() {
                                            _pressedPlayIndex = null;
                                            _sendingIndex = index;
                                          });
                                          _sendingAnimationController!
                                              .forward();
                                        }
                                      },
                                    );
                                  }
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _pressedPlayIndex = null;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                  width: 44,
                                  height: 44,
                                  transform: isPlayPressed
                                      ? (Matrix4.identity()..scale(0.90))
                                      : Matrix4.identity(),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? const Color(0xFF8B3A3A)
                                        : (isPlayPressed
                                              ? const Color(0xFF3A5070)
                                              : const Color(0xFF274060)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isPlaying
                                        ? const Icon(
                                            Icons.stop_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          )
                                        : Transform.translate(
                                            offset: const Offset(1, 0),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Show orange circle with edit icon for non-"My Effects" folders
                              if (folderName != 'My Effects')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      debugPrint('Edit ${effect['name']}');
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFF58220),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/edit.png',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                // Show 3-dot menu for "My Effects" folder
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  color: const Color(0xFF2A2A2A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  offset: const Offset(0, 40),
                                  onSelected: (value) {
                                    HapticFeedback.mediumImpact();
                                    if (value == 'edit') {
                                      debugPrint('Edit ${effect['name']}');
                                      // TODO: Navigate to edit screen
                                    } else if (value == 'delete') {
                                      debugPrint('Delete ${effect['name']}');
                                      // TODO: Show confirmation dialog and delete
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/edit.png',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Edit Effect',
                                            style: TextStyle(
                                              fontFamily: 'SpaceMono',
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFEC202C),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Delete Effect',
                                            style: TextStyle(
                                              fontFamily: 'SpaceMono',
                                              fontSize: 14,
                                              color: Color(0xFFEC202C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isSending)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _sendingAnimation!,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _SendingBorderPainter(
                                  progress: _sendingAnimation!.value,
                                  borderRadius: 16,
                                  strokeWidth: 3,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MusicTabContent extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;

  const MusicTabContent({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spotify logo
              Image.asset(
                'assets/images/spotify.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Sync your lights to the music you love. Connect your Spotify account to get started.',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  debugPrint('Connect to Spotify tapped');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Connect Spotify',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendingBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double strokeWidth;
  final Color color;

  _SendingBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Create the path for the rounded rectangle border
    final path = Path()..addRRect(rrect);

    // Get the total length of the path
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;

    // Calculate overall opacity - fade in at start, fade out at end
    double overallOpacity;
    if (progress < 0.1) {
      overallOpacity = progress / 0.1;
    } else if (progress > 0.9) {
      overallOpacity = (1.0 - progress) / 0.1;
    } else {
      overallOpacity = 1.0;
    }
    overallOpacity = overallOpacity.clamp(0.0, 1.0);

    // Comet tail length (30% of the border)
    final cometLength = totalLength * 0.30;
    final headPosition = totalLength * progress;

    // Draw the comet as multiple segments with tapering opacity
    const int segments = 20;
    for (int i = 0; i < segments; i++) {
      // Calculate position for this segment (0 = tail, segments-1 = head)
      final segmentProgress = i / (segments - 1);
      final segmentOpacity =
          segmentProgress *
          segmentProgress *
          overallOpacity; // Quadratic falloff for smoother taper

      if (segmentOpacity < 0.02) continue; // Skip nearly invisible segments

      // Calculate segment position along the comet
      final segmentOffset = cometLength * (1 - segmentProgress);
      final segmentPos = headPosition - segmentOffset;

      // Calculate small chunk of the path for this segment
      final chunkSize = cometLength / segments;
      final startDist = (segmentPos - chunkSize / 2).clamp(0.0, totalLength);
      final endDist = (segmentPos + chunkSize / 2).clamp(0.0, totalLength);

      if (endDist <= startDist) continue;

      // Taper the stroke width too - head is full width, tail is thinner
      final taperWidth = strokeWidth * (0.4 + 0.6 * segmentProgress);
      final glowTaperWidth = (strokeWidth + 6) * (0.3 + 0.7 * segmentProgress);

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowTaperWidth
        ..color = color.withOpacity(0.5 * segmentOpacity)
        ..strokeCap = StrokeCap.round;

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = taperWidth
        ..color = color.withOpacity(segmentOpacity)
        ..strokeCap = StrokeCap.round;

      final extractedPath = pathMetrics.extractPath(startDist, endDist);
      canvas.drawPath(extractedPath, glowPaint);
      canvas.drawPath(extractedPath, strokePaint);

      // Handle wrap-around for segments at the beginning
      if (segmentPos < 0) {
        final wrapPos = totalLength + segmentPos;
        final wrapStart = (wrapPos - chunkSize / 2).clamp(0.0, totalLength);
        final wrapEnd = (wrapPos + chunkSize / 2).clamp(0.0, totalLength);
        if (wrapEnd > wrapStart) {
          final wrapPath = pathMetrics.extractPath(wrapStart, wrapEnd);
          canvas.drawPath(wrapPath, glowPaint);
          canvas.drawPath(wrapPath, strokePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SendingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'colors_tab_view.dart';
import 'whites_tab_view.dart';
import 'store_tab_view.dart';

class EffectsTabView extends StatefulWidget {
  final String lightName;
  final String? controllerTypeName;
  final Function(Color color, bool isOn)? onColorSelected;
  final int? locationId;
  final int? lightId;
  final int? zoneId;
  final Color? initialColor;
  final bool? initialIsOn;
  final double? initialBrightness;

  const EffectsTabView({
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
  });

  @override
  State<EffectsTabView> createState() => _EffectsTabViewState();
}

class _EffectsTabViewState extends State<EffectsTabView> {
  late Color _selectedColor;
  late bool _isOn;
  late double _brightness;
  int _selectedTabIndex = 2; // Effects tab is index 2

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.purple;
    _isOn = widget.initialIsOn ?? false;
    _brightness = widget.initialBrightness ?? 100.0;
  }

  // Currently selected folder
  String? _selectedFolder;

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
            {'wavelength': 2.5, 'amplitude': 0.7, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
            {'wavelength': 1.5, 'amplitude': 0.5, 'speed': 1.0, 'direction': 1.0, 'phase': 0.33},
            {'wavelength': 0.8, 'amplitude': 0.3, 'speed': 2.0, 'direction': 1.0, 'phase': 0.66},
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
    'Holidays': [
      {
        'name': 'Christmas Magic',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC202C),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFFFFFFFF),
          'waves': [
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
            {'wavelength': 1.5, 'amplitude': 0.5, 'speed': 1.0, 'direction': 1.0, 'phase': 0.33},
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
        'name': 'Valentines Day',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFEC2180),
          'peakColor': Color(0xFFFF4D6D),
          'valleyColor': Color(0xFF8B0A3A),
          'waves': [
            {'wavelength': 2.0, 'amplitude': 0.6, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'St Patricks Day',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF00A86B),
          'peakColor': Color(0xFF6ABC45),
          'valleyColor': Color(0xFF2E5A1C),
          'waves': [
            {'wavelength': 1.8, 'amplitude': 0.7, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Easter Pastels',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFFFB6C1),
          'peakColor': Color(0xFF87CEEB),
          'valleyColor': Color(0xFF98FB98),
          'waves': [
            {'wavelength': 2.2, 'amplitude': 0.5, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
            {'wavelength': 1.4, 'amplitude': 0.4, 'speed': 1.0, 'direction': -1.0, 'phase': 0.5},
          ],
          'opacity': 0.75,
        },
      },
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
      {
        'name': 'Halloween Fade',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF6053A2),
          'peakColor': Color(0xFFEC2180),
          'valleyColor': Color(0xFF1A1A40),
          'waves': [
            {'wavelength': 2.5, 'amplitude': 0.7, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
            {'wavelength': 0.8, 'amplitude': 0.3, 'speed': 2.0, 'direction': 1.0, 'phase': 0.66},
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
        'name': 'Thanksgiving',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFFD2691E),
          'peakColor': Color(0xFFFAA819),
          'valleyColor': Color(0xFF8B4513),
          'waves': [
            {'wavelength': 2.0, 'amplitude': 0.6, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Hanukkah',
        'type': 'Wave',
        'effectType': 'wave3',
        'waveConfig': {
          'startColor': Color(0xFF4165AF),
          'peakColor': Color(0xFFFFFFFF),
          'valleyColor': Color(0xFF1A3A6A),
          'waves': [
            {'wavelength': 1.8, 'amplitude': 0.6, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
    ],
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
            {'wavelength': 1.8, 'amplitude': 0.8, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.5, 'direction': 1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.5, 'direction': -1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.5, 'direction': 1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.5, 'direction': -1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.5, 'direction': 1.0, 'phase': 0.0},
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
            {'wavelength': 1.5, 'amplitude': 0.6, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
            {'wavelength': 1.0, 'amplitude': 0.4, 'speed': 1.5, 'direction': -1.0, 'phase': 0.5},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
      {
        'name': 'Pride Celebration',
        'type': 'Comet',
        'effectType': 'comet',
        'cometConfig': {
          'colors': [
            Color(0xFFEC202C),
            Color(0xFFFDD901),
            Color(0xFF6ABC45),
            Color(0xFF4165AF),
            Color(0xFF6053A2),
          ],
          'cometCount': 6,
          'tailLength': 0.3,
          'minSpeed': 1.0,
          'maxSpeed': 2.0,
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
            {'wavelength': 1.8, 'amplitude': 0.6, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
            {'wavelength': 1.2, 'amplitude': 0.4, 'speed': 1.0, 'direction': -1.0, 'phase': 0.5},
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
            {'wavelength': 2.2, 'amplitude': 0.5, 'speed': 1.0, 'direction': 1.0, 'phase': 0.0},
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
            {'wavelength': 2.0, 'amplitude': 0.7, 'speed': 1.0, 'direction': -1.0, 'phase': 0.0},
          ],
          'opacity': 0.8,
        },
      },
    ],
  };

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
      default:
        return 'assets/animations/myeffectsreveal.json';
    }
  }

  void _openFolder(String folderName) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedFolder = folderName;
    });
  }

  void _closeFolder() {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedFolder = null;
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
        leading: _selectedFolder != null
            ? GestureDetector(
                onTap: _closeFolder,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            : null,
        title: _selectedFolder != null
            ? Text(
                _selectedFolder!,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (widget.onColorSelected != null) {
                  widget.onColorSelected!(_selectedColor, _isOn);
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
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Content area - either folders grid or effects list
            Expanded(
              child: _selectedFolder == null
                  ? _buildFoldersGrid()
                  : _buildEffectsList(_selectedFolder!),
            ),
            // Tab selector
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTabSelector(),
              ),
            ),
            // Light card at the bottom
            _buildLightCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersGrid() {
    final folders = _presetFolders.keys.toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          final effectCount = _presetFolders[folderName]!.length;
          
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
    );
  }

  Widget _buildEffectsList(String folderName) {
    final effects = _presetFolders[folderName] ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        debugPrint('Play ${effect['name']}');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF274060),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Transform.translate(
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        debugPrint('Menu for ${effect['name']}');
                      },
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 28,
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

  Widget _buildLightCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 9),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: HSLColor.fromColor(_selectedColor)
                .withLightness(
                  HSLColor.fromColor(_selectedColor).lightness * 0.3,
                )
                .toColor()
                .withOpacity(0.6),
            width: 4,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 115,
          decoration: BoxDecoration(
            color: _isOn
                ? (_brightness == 0
                      ? const Color(0xFF212121)
                      : HSLColor.fromColor(_selectedColor)
                            .withLightness(
                              (HSLColor.fromColor(_selectedColor).lightness *
                                      0.15) +
                                  (HSLColor.fromColor(
                                        _selectedColor,
                                      ).lightness *
                                      0.35 *
                                      (_brightness / 100)),
                            )
                            .toColor())
                : const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                        color: Color(0xFF9E9E9E),
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
                        setState(() {
                          _isOn = value;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: _isOn
                          ? HSLColor.fromColor(_selectedColor)
                                .withLightness(
                                  HSLColor.fromColor(_selectedColor).lightness *
                                      0.3,
                                )
                                .toColor()
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
                      color: Color(0xFF9E9E9E),
                      size: 32,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: 100,
                        min: 0,
                        max: 100,
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    const List<Map<String, String>> tabs = [
      {'label': 'Colors', 'icon': 'assets/images/colorsicon.png'},
      {'label': 'Whites', 'icon': 'assets/images/whitesicon.png'},
      {'label': 'Effects', 'icon': 'assets/images/effectsicon.png'},
      {'label': 'Store', 'icon': 'assets/images/storeicon.png'},
    ];

    return Container(
      width: 310,
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
          final tabWidth = constraints.maxWidth / 4;

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
                children: List.generate(tabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _onTabSelected(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.85,
                            child: Image.asset(
                              tabs[index]['icon']!,
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            tabs[index]['label']!,
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

  void _onTabSelected(int index) {
    if (index == 2) return; // Already on Effects tab

    // Animate the indicator and navigate immediately (async)
    setState(() {
      _selectedTabIndex = index;
    });

    // Navigate immediately - don't wait for animation
    Widget targetView;
    switch (index) {
      case 0:
        targetView = ColorsTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      case 1:
        targetView = WhitesTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      case 3:
        targetView = StoreTabView(
          lightName: widget.lightName,
          controllerTypeName: widget.controllerTypeName,
          onColorSelected: widget.onColorSelected,
          locationId: widget.locationId,
          lightId: widget.lightId,
          zoneId: widget.zoneId,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
        );
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetView,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

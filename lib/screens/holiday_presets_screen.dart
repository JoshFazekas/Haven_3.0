import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class HolidayPresetsScreen extends StatefulWidget {
  const HolidayPresetsScreen({super.key});

  @override
  State<HolidayPresetsScreen> createState() => _HolidayPresetsScreenState();
}

class _HolidayPresetsScreenState extends State<HolidayPresetsScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Holiday selections (Step 1)
  final Map<String, bool> _holidaySelections = {
    'Christmas': true,
    'Halloween': true,
    'St. Patrick\'s Day': true,
    '4th of July': true,
    'New Year\'s': true,
    'Easter': true,
    'Mother\'s Day': false,
    'Father\'s Day': false,
    'Diwali': false,
    'Hanukkah': false,
  };

  // Holiday icons mapping
  final Map<String, String> _holidayIcons = {
    'Christmas': 'assets/images/christmas.png',
    'Halloween': 'assets/images/halloween.png',
    'St. Patrick\'s Day': 'assets/images/stpats.png',
    '4th of July': 'assets/images/4th.png',
    'New Year\'s': 'assets/images/newyears.png',
    'Easter': 'assets/images/easter.png',
    'Mother\'s Day': 'assets/images/mother.png',
    'Father\'s Day': 'assets/images/father.png',
    'Diwali': 'assets/images/diwali.png',
    'Hanukkah': 'assets/images/hanukkah.png',
  };

  // Holiday animations mapping (for holidays with Lottie animations)
  final Map<String, String> _holidayAnimations = {
    'Christmas': 'assets/animations/christmas.json',
    'Halloween': 'assets/animations/halloween.json',
    'St. Patrick\'s Day': 'assets/animations/stpats.json',
    '4th of July': 'assets/animations/4th.json',
    'New Year\'s': 'assets/animations/newyears.json',
    'Easter': 'assets/animations/easter.json',
    'Mother\'s Day': 'assets/animations/mother.json',
    'Father\'s Day': 'assets/animations/father.json',
    'Diwali': 'assets/animations/diwali.json',
    'Hanukkah': 'assets/animations/hanukkah.json',
  };

  // Track which holidays are currently playing animation
  final Map<String, bool> _playingAnimations = {};

  // Security event selection (Step 2)
  bool? _securityEventEnabled = true; // null = not selected, true = yes, false = no

  // Sun/Moon animation state (Step 2)
  bool _showingSun = true; // true = sun.json, false = moon.json

  // Expanded state for holidays list (Step 3)
  bool _isHolidaysExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep < 2) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _fadeController.forward();
      });
    } else {
      // Complete - go back
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentStep--;
        });
        _fadeController.forward();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _previousStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Step indicators
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentStep;
                      final isCompleted = index < _currentStep;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFC56A21)
                              : isCompleted
                                  ? const Color(0xFFC56A21).withOpacity(0.5)
                                  : const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildStepContent(),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GestureDetector(
                onTap: _nextStep,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC56A21), Color(0xFFE8923A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC56A21).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentStep == 2 ? 'Done' : 'Continue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1HolidaySelection();
      case 1:
        return _buildStep2SecurityEvent();
      case 2:
        return _buildStep3Complete();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1HolidaySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Fun header with emojis
          const Center(
            child: Text(
              'Select Your Holidays!',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Which holidays do you want setup for your system?',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Popular holidays section
          const Text(
            'Most Popular',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC56A21),
            ),
          ),
          const SizedBox(height: 12),
          _buildHolidayGrid([
            'Christmas',
            'Halloween',
            'St. Patrick\'s Day',
            '4th of July',
            'New Year\'s',
            'Easter',
          ]),

          const SizedBox(height: 24),

          // Other holidays section
          const Text(
            'Others',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 12),
          _buildHolidayGrid([
            'Mother\'s Day',
            'Father\'s Day',
            'Diwali',
            'Hanukkah',
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHolidayGrid(List<String> holidays) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: holidays.length,
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        final isSelected = _holidaySelections[holiday] ?? false;
        final hasAnimation = _holidayAnimations.containsKey(holiday);
        final isPlayingAnimation = _playingAnimations[holiday] ?? false;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            final wasSelected = _holidaySelections[holiday] ?? false;
            setState(() {
              _holidaySelections[holiday] = !wasSelected;
            });
            
            // Play animation if selecting (not deselecting) and holiday has animation
            if (!wasSelected && hasAnimation) {
              setState(() {
                _playingAnimations[holiday] = true;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3D2A1A)
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC56A21)
                    : const Color(0xFF3A3A3A),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC56A21).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Holiday icon or animation
                      if (hasAnimation && isPlayingAnimation)
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Lottie.asset(
                            _holidayAnimations[holiday]!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            repeat: false,
                            onLoaded: (composition) {
                              // Animation will stop after playing once
                              Future.delayed(composition.duration, () {
                                if (mounted) {
                                  setState(() {
                                    _playingAnimations[holiday] = false;
                                  });
                                }
                              });
                            },
                          ),
                        )
                      else
                        Image.asset(
                          _holidayIcons[holiday] ?? 'assets/images/holiday.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.celebration,
                                color: Colors.white54,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      Text(
                        holiday,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Checkmark
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC56A21),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2SecurityEvent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Sun/Moon animation
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              _showingSun 
                  ? 'assets/animations/sun.json' 
                  : 'assets/animations/moon.json',
              key: ValueKey(_showingSun ? 'sun' : 'moon'),
              repeat: false,
              animate: true,
              onLoaded: (composition) {
                // Schedule switch to other animation after this one completes + delay
                Future.delayed(composition.duration + const Duration(milliseconds: 800), () {
                  if (mounted && _currentStep == 1) {
                    setState(() {
                      _showingSun = !_showingSun;
                    });
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 32),
          // Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Non-Holiday Days',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'On days without a holiday, would you like your lights to fade in warm white at sunset and turn off in the morning?',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 16,
                color: Color(0xFF9E9E9E),
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 48),

          // Yes/No options
          Row(
            children: [
              Expanded(
                child: _buildSecurityOption(
                  label: 'Yes',
                  isSelected: _securityEventEnabled == true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _securityEventEnabled = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSecurityOption(
                  label: 'No',
                  isSelected: _securityEventEnabled == false,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _securityEventEnabled = false;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info text
          if (_securityEventEnabled == true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lights will fade to warm white at sunset and turn off at sunrise',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3D2A1A)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC56A21)
                : const Color(0xFF3A3A3A),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC56A21).withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFC56A21) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3Complete() {
    // Get selected holidays count
    final selectedCount = _holidaySelections.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration animation
          SizedBox(
            width: 150,
            height: 150,
            child: Lottie.asset(
              'assets/animations/dibe.json',
              repeat: true,
              animate: true,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'You\'re All Set!',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'You can manage, edit and remove scenes and events at anytime.',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Selected holidays list
          ..._buildHolidaysList(selectedCount),
        ],
      ),
    );
  }

  List<Widget> _buildHolidaysList(int selectedCount) {
    final selectedHolidays = _holidaySelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedHolidays.isEmpty) {
      return [];
    }

    const int initialDisplayCount = 6;
    final bool hasMore = selectedHolidays.length > initialDisplayCount;
    final int displayCount = _isHolidaysExpanded ? selectedHolidays.length : initialDisplayCount;

    List<Widget> widgets = [];

    // Wrap with holiday chips
    widgets.add(
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: selectedHolidays
            .take(displayCount)
            .map((holiday) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    holiday,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ))
            .toList(),
      ),
    );

    // Add expand/collapse button if there are more holidays
    if (hasMore) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isHolidaysExpanded = !_isHolidaysExpanded;
              });
            },
            child: Text(
              _isHolidaysExpanded 
                  ? 'Show Less' 
                  : '+${selectedHolidays.length - initialDisplayCount} more',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 12,
                color: Color(0xFFC56A21),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

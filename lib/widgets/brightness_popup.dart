import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern frosted-glass popup that lets the user pick one of 10 brightness
/// levels (10 %–100 %).
///
/// Returns the selected **brightnessId** (1–10) via [Navigator.pop], or `null`
/// if dismissed.
///
/// Usage:
/// ```dart
/// final brightnessId = await showBrightnessPopup(context);
/// ```
Future<int?> showBrightnessPopup(BuildContext context) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss brightness',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => const _BrightnessPopupContent(),
  );
}

class _BrightnessPopupContent extends StatelessWidget {
  const _BrightnessPopupContent();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.white.withOpacity(0.85),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BRIGHTNESS',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 10 brightness buttons in a 5×2 grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final brightnessId = index + 1; // 1–10
                        final percent = brightnessId * 10; // 10–100
                        // Opacity ramps from 0.15 (10%) to 1.0 (100%)
                        final fillOpacity = 0.15 + (brightnessId / 10) * 0.85;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context, brightnessId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                fillOpacity * 0.25,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  fillOpacity * 0.5,
                                ),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$percent%',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(
                                  0.5 + fillOpacity * 0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
}

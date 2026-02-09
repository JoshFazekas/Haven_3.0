import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';

/// A small frosted-glass environment badge that floats below the Dynamic Island.
/// Only visible when running in non-production environments (dev, local).
class DevIndicator extends StatelessWidget {
  const DevIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (!EnvironmentConfig.showBadge) return const SizedBox.shrink();

    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Positioned(
      top: topPadding + 4,
      left: 0,
      right: 0,
      child: Center(
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  EnvironmentConfig.badgeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

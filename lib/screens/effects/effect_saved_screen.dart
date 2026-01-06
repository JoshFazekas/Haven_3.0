import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Success screen shown after saving an effect to My Effects
class EffectSavedScreen extends StatefulWidget {
  final String effectName;
  final VoidCallback onComplete;

  const EffectSavedScreen({
    super.key,
    required this.effectName,
    required this.onComplete,
  });

  @override
  State<EffectSavedScreen> createState() => _EffectSavedScreenState();
}

class _EffectSavedScreenState extends State<EffectSavedScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateBack();
      }
    });

    // Fallback timeout in case animation fails to load
    Future.delayed(const Duration(seconds: 3), () {
      if (!_hasNavigated && mounted) {
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/effectcreated.json',
              controller: _animationController,
              onLoaded: (composition) {
                _animationController
                  ..duration = composition.duration
                  ..forward();
              },
              errorBuilder: (context, error, stackTrace) {
                // If animation fails to load, navigate after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  _navigateBack();
                });
                return const Icon(
                  Icons.check_circle,
                  color: Color(0xFFD75F00),
                  size: 120,
                );
              },
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'Added to My Effects!',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

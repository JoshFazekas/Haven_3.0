import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haven/core/theme/app_colors.dart';
import 'package:haven/screens/sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showSignIn = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    // Show sign-in screen after 2 seconds regardless of animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    setState(() {
      _showSignIn = true;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Lottie animation
          Center(
            child: Lottie.asset(
              'assets/animations/Animation.json',
              controller: _lottieController,
              onLoaded: (composition) {
                // Play at original speed
                _lottieController
                  ..duration = composition.duration
                  ..forward();
              },
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          // Sign in screen fades in on top
          if (_showSignIn)
            FadeTransition(
              opacity: _fadeAnimation,
              child: const SignInScreen(),
            ),
        ],
      ),
    );
  }
}

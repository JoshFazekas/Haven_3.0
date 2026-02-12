import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haven/core/theme/app_colors.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:haven/core/services/haven_api.dart';
import 'package:haven/core/services/location_data_service.dart';
import 'package:haven/screens/auth_screen.dart';
import 'package:haven/screens/lights_screen.dart';

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
  bool _navigatedAway = false;

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

    // Restore the last-selected location from secure storage so the
    // location name is available as soon as LightsScreen loads.
    LocationDataService().loadCachedLocation();

    // Try to resume the previous session while the splash plays.
    _tryAutoLogin();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ───────────────── Auto-login ─────────────────

  /// Attempts to restore the previous session.
  ///
  /// 1. Load stored credentials from secure storage.
  /// 2. If they exist, try refreshing the bearer token (fast path).
  /// 3. If the refresh fails, re-authenticate with email + password.
  /// 4. Fetch fresh location data.
  /// 5. Navigate straight to [LightsScreen].
  ///
  /// If anything fails we fall back to showing [SignInScreen].
  Future<void> _tryAutoLogin() async {
    try {
      final authState = AuthState();
      final hasCredentials = await authState.loadStoredCredentials();

      if (!hasCredentials || !mounted) {
        _showSignInScreen();
        return;
      }

      // Try token refresh first (cheapest network call)
      final api = HavenApi();
      bool tokenValid = await api.refreshTokens();

      if (!tokenValid) {
        // Refresh failed — try a full re-authenticate with stored password
        final email = authState.email;
        final password = authState.password;

        if (email == null || password == null) {
          _showSignInScreen();
          return;
        }

        try {
          final result = await api.authenticate(
            email: email,
            password: password,
          );
          await authState.updateToken(
            token: result['token'] as String,
            refreshToken: result['refreshToken'] as String,
            userId: result['id'] as int,
          );
          tokenValid = true;
        } catch (_) {
          // Credentials may have changed — send the user to sign in
          _showSignInScreen();
          return;
        }
      }

      if (!mounted) return;

      // We have a valid token — fetch location data so the home screen
      // is fully populated when it appears.
      final locationDataService = LocationDataService();
      final locationId =
          authState.defaultLocationId ??
          locationDataService.selectedLocationId;

      if (locationId != null && locationId > 0) {
        try {
          final locationData = await api.getLocationLightsZones(
            token: authState.token!,
            locationId: locationId,
          );
          authState.saveLocationLightsZones(locationData);
          await locationDataService.loadFromApiResponse(locationData);
        } catch (e) {
          debugPrint('Auto-login: Failed to fetch location data: $e');
          // Non-fatal — we'll land on LightsScreen with cached data.
        }
      }

      if (!mounted) return;

      // Skip the sign-in screen entirely.
      _navigatedAway = true;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LightsScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      if (mounted) _showSignInScreen();
    }
  }

  /// Falls back to showing the sign-in screen.
  void _showSignInScreen() {
    if (!mounted || _navigatedAway) return;
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

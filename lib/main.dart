import 'package:flutter/material.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';
import 'package:haven/core/constants/api_constants.dart';

/// Default main - defaults to dev environment
/// For explicit environment control, use:
/// - main_dev.dart for development
/// - main_prod.dart for production
void main() {
  // Default to dev if running main.dart directly (not recommended)
  ApiConstants.init(Environment.dev);
  runApp(const HavenApp());
}

/// Main Haven App Widget
/// This is shared between main_dev.dart and main_prod.dart
class HavenApp extends StatelessWidget {
  const HavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven',
      debugShowCheckedModeBanner: ApiConstants.isDev, // Show banner in dev only
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}


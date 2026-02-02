import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';

/// Entry point for HavenApp-PROD scheme
/// Targets: https://stg-api.havenlighting.com
void main() {
  EnvironmentConfig.init(Environment.prod);
  runApp(const HavenApp());
}

class HavenApp extends StatelessWidget {
  const HavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

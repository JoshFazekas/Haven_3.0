import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';

/// Entry point for HavenApp-DEV scheme
/// Targets: https://dev-api.havenlighting.com
void main() {
  EnvironmentConfig.init(Environment.dev);
  runApp(const HavenApp());
}

class HavenApp extends StatelessWidget {
  const HavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven${EnvironmentConfig.isDev ? ' (DEV)' : ''}',
      debugShowCheckedModeBanner: EnvironmentConfig.isDev,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

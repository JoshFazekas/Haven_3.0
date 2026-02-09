import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';
import 'package:haven/widgets/dev_indicator.dart';

/// Entry point for HavenApp-LOCAL scheme
/// Targets: http://localhost:5001
void main() {
  EnvironmentConfig.init(Environment.local);
  runApp(const HavenApp());
}

class HavenApp extends StatelessWidget {
  const HavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven (LOCAL)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const DevIndicator(),
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';
import 'package:haven/widgets/dev_indicator.dart';

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

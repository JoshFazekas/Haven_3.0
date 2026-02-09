import 'package:flutter/material.dart';
import 'package:haven/core/config/environment.dart';
import 'package:haven/core/theme/app_theme.dart';
import 'package:haven/screens/splash_screen.dart';
import 'package:haven/widgets/dev_indicator.dart';

void main() {
  // Default to DEV environment when using main.dart
  EnvironmentConfig.init(Environment.dev);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haven',
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

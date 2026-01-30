import 'package:flutter/material.dart';
import 'package:haven/core/constants/api_constants.dart';
import 'package:haven/main.dart';

/// Development entry point
/// 
/// Run with: flutter run --flavor dev -t lib/main_dev.dart
/// Build with: flutter build ios --flavor dev -t lib/main_dev.dart
/// Build with: flutter build apk --flavor dev -t lib/main_dev.dart
void main() {
  // Initialize the API environment to DEV
  ApiConstants.init(Environment.dev);
  
  // Run the app
  runApp(const HavenApp());
}

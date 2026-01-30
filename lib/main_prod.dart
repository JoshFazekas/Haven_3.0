import 'package:flutter/material.dart';
import 'package:haven/core/constants/api_constants.dart';
import 'package:haven/main.dart';

/// Production entry point
/// 
/// Run with: flutter run --flavor prod -t lib/main_prod.dart
/// Build with: flutter build ios --flavor prod -t lib/main_prod.dart
/// Build with: flutter build apk --flavor prod -t lib/main_prod.dart
void main() {
  // Initialize the API environment to PROD
  ApiConstants.init(Environment.prod);
  
  // Run the app
  runApp(const HavenApp());
}

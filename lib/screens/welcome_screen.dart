import 'package:flutter/material.dart';
import 'package:haven/widgets/location_header.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image for empty state
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/spacey.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationHeader(
                    locationName: 'Home',
                    onLocationTap: () {
                      // TODO: Show location picker
                      debugPrint('Location tapped');
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "It's a little empty here..",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Add your first device to get started",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF828282),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Add Controller button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          // TODO: Navigate to add controller
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF57F20),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Add Controller',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:haven/screens/menu_screen.dart';

class LocationHeader extends StatelessWidget {
  final String locationName;
  final VoidCallback? onLocationTap;

  const LocationHeader({
    super.key,
    this.locationName = 'Home',
    this.onLocationTap,
  });

  void _navigateToMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to make font size dynamic
    final screenWidth = MediaQuery.of(context).size.width;
    // Base font size that scales with screen width
    final fontSize = screenWidth * 0.07; // 7% of screen width

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Location name with dropdown
        GestureDetector(
          onTap: onLocationTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locationName,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: fontSize.clamp(24.0, 36.0), // Min 24, max 36
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: fontSize.clamp(24.0, 32.0),
              ),
            ],
          ),
        ),

        // Menu button
        GestureDetector(
          onTap: () => _navigateToMenu(context),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Image.asset(
              'assets/images/menuicon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

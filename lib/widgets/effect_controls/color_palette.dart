import 'package:flutter/material.dart';

/// Shared color palette constants used across the app
class ColorPalette {
  ColorPalette._();

  /// All supported colors from the color palette
  static const List<Color> paletteColors = [
    Color(0xFFEC202C), // Red
    Color(0xFFED2F24), // Pumpkin
    Color(0xFFEF5023), // Orange
    Color(0xFFF37A20), // Marigold
    Color(0xFFFAA819), // Sunset
    Color(0xFFFDD901), // Yellow
    Color(0xFFEFE814), // Lemon
    Color(0xFFC7D92C), // Lime
    Color(0xFFA7CE38), // Pear
    Color(0xFF88C440), // Emerald
    Color(0xFF75BF43), // Lt Green
    Color(0xFF6ABC45), // Green
    Color(0xFF6CBD45), // Sea Foam
    Color(0xFF71BE48), // Teal
    Color(0xFF71C178), // Turquoise
    Color(0xFF70C5A2), // Arctic
    Color(0xFF70C9CC), // Ocean
    Color(0xFF61CAE5), // Sky
    Color(0xFF43B4E7), // Water
    Color(0xFF4782C3), // Sapphire
    Color(0xFF4165AF), // Lt Blue
    Color(0xFF3E57A6), // Deep Blue
    Color(0xFF3C54A3), // Indigo
    Color(0xFF4B53A3), // Orchid
    Color(0xFF6053A2), // Purple
    Color(0xFF7952A0), // Lavender
    Color(0xFF94519F), // Lilac
    Color(0xFFB2519E), // Pink
    Color(0xFFC94D9B), // Bubblegum
    Color(0xFFE63A94), // Flamingo
    Color(0xFFEC2180), // Hot Pink
    Color(0xFFED1F52), // Deep Pink
  ];

  /// White temperature colors
  static const List<Color> whiteColors = [
    Color(0xFFF8E96C), // 2700K
    Color(0xFFF6F08E), // 3000K
    Color(0xFFF4F4AC), // 3500K
    Color(0xFFF2F4C2), // 3700K
    Color(0xFFECF5DA), // 4000K
    Color(0xFFE3F3E9), // 4100K
    Color(0xFFDDF1F2), // 4700K
    Color(0xFFD6EFF6), // 5000K
  ];

  /// Combined available colors (OFF/black first, then palette, then whites)
  static List<Color> get availableColors => [
    Colors.black, // OFF
    ...paletteColors,
    ...whiteColors,
  ];

  /// Get color name from color value
  static String getColorName(Color color) {
    // Match against palette colors
    if (color == const Color(0xFFEC202C)) return 'Red';
    if (color == const Color(0xFFED2F24)) return 'Pumpkin';
    if (color == const Color(0xFFEF5023)) return 'Orange';
    if (color == const Color(0xFFF37A20)) return 'Marigold';
    if (color == const Color(0xFFFAA819)) return 'Sunset';
    if (color == const Color(0xFFFDD901)) return 'Yellow';
    if (color == const Color(0xFFEFE814)) return 'Lemon';
    if (color == const Color(0xFFC7D92C)) return 'Lime';
    if (color == const Color(0xFFA7CE38)) return 'Pear';
    if (color == const Color(0xFF88C440)) return 'Emerald';
    if (color == const Color(0xFF75BF43)) return 'Lt Green';
    if (color == const Color(0xFF6ABC45)) return 'Green';
    if (color == const Color(0xFF6CBD45)) return 'Sea Foam';
    if (color == const Color(0xFF71BE48)) return 'Teal';
    if (color == const Color(0xFF71C178)) return 'Turquoise';
    if (color == const Color(0xFF70C5A2)) return 'Arctic';
    if (color == const Color(0xFF70C9CC)) return 'Ocean';
    if (color == const Color(0xFF61CAE5)) return 'Sky';
    if (color == const Color(0xFF43B4E7)) return 'Water';
    if (color == const Color(0xFF4782C3)) return 'Sapphire';
    if (color == const Color(0xFF4165AF)) return 'Lt Blue';
    if (color == const Color(0xFF3E57A6)) return 'Deep Blue';
    if (color == const Color(0xFF3C54A3)) return 'Indigo';
    if (color == const Color(0xFF4B53A3)) return 'Orchid';
    if (color == const Color(0xFF6053A2)) return 'Purple';
    if (color == const Color(0xFF7952A0)) return 'Lavender';
    if (color == const Color(0xFF94519F)) return 'Lilac';
    if (color == const Color(0xFFB2519E)) return 'Pink';
    if (color == const Color(0xFFC94D9B)) return 'Bubblegum';
    if (color == const Color(0xFFE63A94)) return 'Flamingo';
    if (color == const Color(0xFFEC2180)) return 'Hot Pink';
    if (color == const Color(0xFFED1F52)) return 'Deep Pink';
    if (color == Colors.black) return 'Off';
    // White temperatures
    if (color == const Color(0xFFF8E96C)) return 'Warm White';
    if (color == const Color(0xFFF6F08E)) return 'Soft White';
    if (color == const Color(0xFFF4F4AC)) return 'White';
    if (color == const Color(0xFFF2F4C2)) return 'Cool White';
    if (color == const Color(0xFFECF5DA)) return 'Bright White';
    if (color == const Color(0xFFE3F3E9)) return 'Daylight';
    if (color == const Color(0xFFDDF1F2)) return 'Ice White';
    if (color == const Color(0xFFD6EFF6)) return 'Blue White';
    
    return 'Color';
  }
}

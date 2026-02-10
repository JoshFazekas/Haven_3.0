import 'package:flutter/material.dart';

/// Defines color and white palettes based on a light's `colorCapability`.
///
/// The API returns `"colorCapability": "Legacy"` or `"Extended"` per light.
/// This class builds the correct palette for each capability type.
class ColorCapability {
  ColorCapability._(); // prevent instantiation

  // ───────────────── Capability Types ─────────────────

  static const String legacy = 'Legacy';
  static const String extended = 'Extended';

  // ───────────────── Legacy Colors (id 11–30) ─────────────────

  /// Each entry: { 'id': int, 'name': String, 'color': Color }
  static const List<Map<String, dynamic>> legacyColors = [
    {'id': 11, 'name': 'Red', 'color': Color(0xFFEC202C)},
    {'id': 12, 'name': 'Fire', 'color': Color(0xFFED3A1A)},
    {'id': 13, 'name': 'Pumpkin', 'color': Color(0xFFEF5023)},
    {'id': 14, 'name': 'Amber', 'color': Color(0xFFF17B20)},
    {'id': 15, 'name': 'Tangerine', 'color': Color(0xFFF39220)},
    {'id': 16, 'name': 'Marigold', 'color': Color(0xFFF5A623)},
    {'id': 17, 'name': 'Sunset', 'color': Color(0xFFFAA819)},
    {'id': 18, 'name': 'Yellow', 'color': Color(0xFFFDD901)},
    {'id': 19, 'name': 'Lime', 'color': Color(0xFFC7D92C)},
    {'id': 20, 'name': 'Light Green', 'color': Color(0xFF8DC63F)},
    {'id': 21, 'name': 'Green', 'color': Color(0xFF00A651)},
    {'id': 22, 'name': 'Sea Foam', 'color': Color(0xFF00B89C)},
    {'id': 23, 'name': 'Turquoise', 'color': Color(0xFF00BCD4)},
    {'id': 24, 'name': 'Ocean', 'color': Color(0xFF0076C0)},
    {'id': 25, 'name': 'Deep Blue', 'color': Color(0xFF1B3FA0)},
    {'id': 26, 'name': 'Violet', 'color': Color(0xFF6A3FA0)},
    {'id': 27, 'name': 'Purple', 'color': Color(0xFF93278F)},
    {'id': 28, 'name': 'Lavender', 'color': Color(0xFFB576BD)},
    {'id': 29, 'name': 'Pink', 'color': Color(0xFFE84C8A)},
    {'id': 30, 'name': 'Hot Pink', 'color': Color(0xFFEC2180)},
  ];

  // ───────────────── Extended Colors (id 11–57) ─────────────────

  /// Extended capability includes the legacy colors plus additional ones.
  /// Each entry: { 'id': int, 'name': String, 'color': Color }
  static const List<Map<String, dynamic>> extendedColors = [
    {'id': 11, 'name': 'Red', 'color': Color(0xFFEC202C)},
    {'id': 12, 'name': 'Fire', 'color': Color(0xFFED3A1A)},
    {'id': 13, 'name': 'Pumpkin', 'color': Color(0xFFEF5023)},
    {'id': 14, 'name': 'Amber', 'color': Color(0xFFF17B20)},
    {'id': 15, 'name': 'Tangerine', 'color': Color(0xFFF39220)},
    {'id': 16, 'name': 'Marigold', 'color': Color(0xFFF5A623)},
    {'id': 17, 'name': 'Sunset', 'color': Color(0xFFFAA819)},
    {'id': 18, 'name': 'Yellow', 'color': Color(0xFFFDD901)},
    {'id': 19, 'name': 'Lime', 'color': Color(0xFFC7D92C)},
    {'id': 20, 'name': 'Light Green', 'color': Color(0xFF8DC63F)},
    {'id': 21, 'name': 'Green', 'color': Color(0xFF00A651)},
    {'id': 22, 'name': 'Sea Foam', 'color': Color(0xFF00B89C)},
    {'id': 25, 'name': 'Deep Blue', 'color': Color(0xFF1B3FA0)},
    {'id': 27, 'name': 'Purple', 'color': Color(0xFF93278F)},
    {'id': 28, 'name': 'Lavender', 'color': Color(0xFFB576BD)},
    {'id': 29, 'name': 'Pink', 'color': Color(0xFFE84C8A)},
    {'id': 30, 'name': 'Hot Pink', 'color': Color(0xFFEC2180)},
    {'id': 39, 'name': 'Orange', 'color': Color(0xFFFF6B00)},
    {'id': 40, 'name': 'Lemon', 'color': Color(0xFFEFE814)},
    {'id': 41, 'name': 'Pale Green', 'color': Color(0xFFA8D8A8)},
    {'id': 42, 'name': 'Emerald', 'color': Color(0xFF00875A)},
    {'id': 44, 'name': 'Arctic', 'color': Color(0xFFB0E0E6)},
    {'id': 45, 'name': 'Sky', 'color': Color(0xFF56C4E8)},
    {'id': 46, 'name': 'Water', 'color': Color(0xFF00A4CC)},
    {'id': 47, 'name': 'Sapphire', 'color': Color(0xFF0047AB)},
    {'id': 48, 'name': 'Light Blue', 'color': Color(0xFF5DADE2)},
    {'id': 50, 'name': 'Orchid', 'color': Color(0xFF9B59B6)},
    {'id': 51, 'name': 'Lilac', 'color': Color(0xFFC39BD3)},
    {'id': 52, 'name': 'Bubblegum', 'color': Color(0xFFFF85A2)},
    {'id': 53, 'name': 'Flamingo', 'color': Color(0xFFFC6882)},
    {'id': 54, 'name': 'Deep Pink', 'color': Color(0xFFD5006D)},
    {'id': 55, 'name': 'Aqua', 'color': Color(0xFF00CED1)},
    {'id': 56, 'name': 'Apple Green', 'color': Color(0xFF76D94C)},
    {'id': 57, 'name': 'Royal Blue', 'color': Color(0xFF2E5CB8)},
  ];

  // ───────────────── Extended Whites (id 1–8) ─────────────────

  /// Extended whites — same 8 temperatures as legacy.
  static const List<Map<String, dynamic>> extendedWhites = legacyWhites;

  // ───────────────── Legacy Whites (id 1–8) ─────────────────

  /// Each entry: { 'id': int, 'name': String, 'color': Color }
  static const List<Map<String, dynamic>> legacyWhites = [
    {'id': 1, 'name': '2700K', 'color': Color(0xFFFFAE5E)},
    {'id': 2, 'name': '3000K', 'color': Color(0xFFFFC880)},
    {'id': 3, 'name': '3500K', 'color': Color(0xFFFFDCA8)},
    {'id': 4, 'name': '3700K', 'color': Color(0xFFFFE2B8)},
    {'id': 5, 'name': '4000K', 'color': Color(0xFFFFEBCC)},
    {'id': 6, 'name': '4100K', 'color': Color(0xFFFFEDD4)},
    {'id': 7, 'name': '4700K', 'color': Color(0xFFF5F0E0)},
    {'id': 8, 'name': '5000K', 'color': Color(0xFFF0F0F0)},
  ];

  // ───────────────── Palette Builders ─────────────────

  /// Returns the color palette for the given capability.
  static List<Map<String, dynamic>> getColors(String? capability) {
    switch (capability?.toUpperCase()) {
      case 'LEGACY':
        return legacyColors;
      case 'EXTENDED':
        return extendedColors;
      default:
        return legacyColors;
    }
  }

  /// Returns the whites palette for the given capability.
  static List<Map<String, dynamic>> getWhites(String? capability) {
    switch (capability?.toUpperCase()) {
      case 'LEGACY':
        return legacyWhites;
      case 'EXTENDED':
        return extendedWhites;
      default:
        return legacyWhites;
    }
  }

  /// Look up a color entry by its ID (works across colors + whites).
  /// Returns null if not found.
  static Map<String, dynamic>? findById(int id, {String? capability}) {
    final colors = getColors(capability);
    final whites = getWhites(capability);

    for (final entry in [...colors, ...whites]) {
      if (entry['id'] == id) return entry;
    }
    return null;
  }

  /// Look up just the [Color] for a given ID. Returns null if not found.
  static Color? colorForId(int id, {String? capability}) {
    return findById(id, capability: capability)?['color'] as Color?;
  }

  /// Look up just the display name for a given ID. Returns null if not found.
  static String? nameForId(int id, {String? capability}) {
    return findById(id, capability: capability)?['name'] as String?;
  }
}

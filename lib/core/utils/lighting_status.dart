/// Utility class for determining lighting status across the app.
///
/// Provides brightness mapping from API `lightBrightnessId` values
/// (1–10) to display percentages (10%–100%), and helpers for
/// determining whether a light / zone / channel is on or off.
class LightingStatus {
  LightingStatus._(); // prevent instantiation

  // ───────────────── Brightness ─────────────────

  /// Maps a `lightBrightnessId` (1–10) to a display percentage (10–100).
  ///
  /// • `null` or `0`  → 0 %  (light is off)
  /// • `1`            → 10 %
  /// • `2`            → 20 %
  /// • …
  /// • `10`           → 100 %
  ///
  /// Any value outside 1–10 is clamped to the nearest valid bound.
  static int brightnessPercent(int? brightnessId) {
    if (brightnessId == null || brightnessId <= 0) return 0;
    if (brightnessId > 10) return 100;
    return brightnessId * 10;
  }

  /// Same as [brightnessPercent] but returns a 0.0–1.0 fraction,
  /// useful for opacity / slider values.
  static double brightnessFraction(int? brightnessId) {
    return brightnessPercent(brightnessId) / 100.0;
  }

  /// Convenience: returns the brightness as a display string, e.g. "80%".
  static String brightnessLabel(int? brightnessId) {
    final pct = brightnessPercent(brightnessId);
    return '$pct%';
  }

  // ───────────────── On / Off Status ─────────────────

  /// The API `lightingStatus` string when a light is off.
  static const String statusOff = 'OFF';

  /// A light is considered **on** when its `lightingStatus` string is
  /// anything other than `"OFF"` (e.g. `"SOLID_COLOR"`).
  ///
  /// If `lightingStatus` is null (missing from the response), falls back
  /// to checking whether `brightnessId > 0`.
  ///
  /// ```dart
  /// final isOn = LightingStatus.isOn(
  ///   lightingStatus: item.lightingStatus,
  ///   brightnessId: item.lightBrightnessId,
  /// );
  /// ```
  static bool isOn({
    required String? lightingStatus,
    int? brightnessId,
  }) {
    // Primary: use the explicit lightingStatus string from the API
    if (lightingStatus != null && lightingStatus.isNotEmpty) {
      return lightingStatus.toUpperCase() != statusOff;
    }
    // Fallback: infer from brightness when status isn't present
    return brightnessId != null && brightnessId > 0;
  }

  /// Inverse of [isOn] for readability.
  static bool isOff({
    required String? lightingStatus,
    int? brightnessId,
  }) {
    return !isOn(lightingStatus: lightingStatus, brightnessId: brightnessId);
  }
}

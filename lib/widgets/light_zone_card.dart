import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/location_data_service.dart';
import '../core/services/command_service.dart';
import '../core/utils/ui_effects.dart';
import '../screens/light_control_wrapper.dart';
import 'light_card_body.dart';
import 'rename_popup.dart';

/// A card displaying a single light/zone.
///
/// All display data (name, color, brightness, on/off, capability, type) is
/// read directly from the [LightZoneItem] model — no manual mapping needed.
class LightZoneCard extends StatefulWidget {
  /// The API model for this light or zone.
  final LightZoneItem item;

  /// Location ID for API calls.
  final int? locationId;

  /// External on/off override (e.g. "turn all lights on/off").
  final bool? forceIsOn;

  const LightZoneCard({
    super.key,
    required this.item,
    this.locationId,
    this.forceIsOn,
  });

  @override
  State<LightZoneCard> createState() => _LightZoneCardState();
}

class _LightZoneCardState extends State<LightZoneCard>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  Color _selectedColor = Colors.orange;
  double _brightness = 100.0;
  Map<String, dynamic>? _playingEffectConfig;
  AnimationController? _effectAnimationController;

  /// Parsed effect from the API's lightingStateName (e.g. cascade).
  UIEffect _apiEffect = UIEffect.none;

  @override
  void initState() {
    super.initState();
    _isOn = widget.item.isCurrentlyOn;
    _brightness = widget.item.brightnessPercent.toDouble();
    _selectedColor = widget.item.initialColor;
    _effectAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Parse any server-side effect that is already playing
    _apiEffect = UIEffect.parse(
      lightingStatus: widget.item.lightingStatus,
      lightingStateName: widget.item.lightingStateName,
    );
    if (_apiEffect.isValid && _isOn) {
      _effectAnimationController?.repeat();
    }
  }

  @override
  void didUpdateWidget(LightZoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-sync local state when the underlying item data changes (e.g. after refresh)
    final newItem = widget.item;
    final oldItem = oldWidget.item;
    if (newItem.colorId != oldItem.colorId ||
        newItem.lightBrightnessId != oldItem.lightBrightnessId ||
        newItem.lightingStateId != oldItem.lightingStateId ||
        newItem.lightingStatus != oldItem.lightingStatus ||
        newItem.lightingStateName != oldItem.lightingStateName) {
      setState(() {
        _isOn = newItem.isCurrentlyOn;
        _brightness = newItem.brightnessPercent.toDouble();
        _selectedColor = newItem.initialColor;

        // Re-parse server-side effect
        _apiEffect = UIEffect.parse(
          lightingStatus: newItem.lightingStatus,
          lightingStateName: newItem.lightingStateName,
        );

        // If the API says there's an effect, start the animation;
        // if it cleared, stop it (unless a local effect is still active).
        if (_apiEffect.isValid && _isOn) {
          _effectAnimationController?.repeat();
        } else if (_playingEffectConfig == null) {
          _effectAnimationController?.stop();
          _effectAnimationController?.reset();
        }
      });
    }

    // Handle external force on/off state changes
    if (widget.forceIsOn != null && widget.forceIsOn != oldWidget.forceIsOn) {
      setState(() {
        _isOn = widget.forceIsOn!;
      });
    }
  }

  @override
  void dispose() {
    _effectAnimationController?.dispose();
    super.dispose();
  }

  void _onToggleTap() {
    HapticFeedback.mediumImpact();
    final newIsOn = !_isOn;
    setState(() {
      _isOn = newIsOn;

      // Start/stop API effect animation on toggle
      if (_apiEffect.isValid) {
        if (newIsOn) {
          _effectAnimationController?.repeat();
        } else {
          _effectAnimationController?.stop();
          _effectAnimationController?.reset();
        }
      }
    });
    debugPrint('Toggle tapped for ${widget.item.name}: $_isOn');

    // Fire the On/Off API command
    final id = widget.item.lightId;
    final type = widget.item.isLight ? 'Light' : 'Zone';

    if (id != null) {
      final command = newIsOn
          ? CommandService().turnOn(id: id, type: type)
          : CommandService().turnOff(id: id, type: type);

      command.catchError((e) {
        debugPrint('Toggle command failed: $e');
      });
    }
  }

  void _openColorPalette() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LightControlWrapper(
          lightName: widget.item.name,
          controllerTypeName: widget.item.displayType,
          lightId: widget.item.lightId,
          zoneId: null,
          locationId: widget.locationId,
          colorCapability: widget.item.colorCapability,
          lightType: widget.item.type,
          capability: widget.item.capability,
          initialTabIndex: 0,
          initialColor: _selectedColor,
          initialIsOn: _isOn,
          initialBrightness: _brightness,
          initialEffectConfig: _playingEffectConfig,
          initialApiEffect: _apiEffect,
          onColorSelected:
              (
                Color color,
                bool isOn,
                double brightness,
                Map<String, dynamic>? effectConfig,
              ) {
                // Update the UI with the new color, state, brightness, and effect
                setState(() {
                  _selectedColor = color;
                  _isOn = isOn;
                  _brightness = brightness;
                  _playingEffectConfig = effectConfig;

                  // If user set a new local effect or picked a solid color,
                  // clear the API effect so we don't double-render.
                  // (A new local effect replaces the server one; a solid color
                  // means the user moved away from the effect entirely.)
                  if (effectConfig != null) {
                    _apiEffect = UIEffect.none;
                  } else if (_apiEffect.isValid &&
                      color != _apiEffect.primaryColor) {
                    // User picked a different solid color — no longer on the API effect
                    _apiEffect = UIEffect.none;
                  }

                  // Start or stop animation based on effect config
                  if (effectConfig != null) {
                    _effectAnimationController?.repeat();
                  } else {
                    _effectAnimationController?.stop();
                    _effectAnimationController?.reset();
                  }
                });
                debugPrint(
                  'Light ${widget.item.name} updated: Color=$color, IsOn=$isOn, Brightness=$brightness, Effect=${effectConfig?['effectType']}',
                );
              },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: GestureDetector(
        onTap: _openColorPalette,
        child: LightCardBody(
          lightName: widget.item.name,
          controllerTypeName: widget.item.displayType,
          isOn: _isOn,
          selectedColor: _selectedColor,
          brightness: _brightness,
          cardHeight: 88,
          playingEffectConfig: _playingEffectConfig,
          apiEffect: _apiEffect,
          effectAnimationController: _effectAnimationController,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          onToggleChanged: (_) => _onToggleTap(),
          onMenuTap: () async {
            HapticFeedback.mediumImpact();
            final type = widget.item.isLight ? 'Light' : 'Zone';
            final newName = await showRenamePopup(
              context,
              itemType: type,
              currentName: widget.item.name,
            );
            if (newName != null && widget.item.lightId != null) {
              debugPrint('Rename ${widget.item.name} → $newName');
              CommandService()
                  .renameLightOrZone(
                    lightId: widget.item.lightId!,
                    name: newName,
                  )
                  .catchError((e) {
                    debugPrint('Rename failed: $e');
                  });
            }
          },
        ),
      ),
    );
  }
}

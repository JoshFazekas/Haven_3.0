import 'package:flutter/material.dart';
import 'package:haven/core/config/error_messages.dart';

/// A modern, glass-style error message that pops up from the bottom
/// with a bouncy animation effect. Use this for form validation errors,
/// network errors, or any error messages across the app.
class GlassErrorMessage {
  /// Shows an error message by ID that pops up from the bottom with a bouncy effect.
  /// 
  /// [context] - The BuildContext to show the message in
  /// [errorId] - The error ID from ErrorMessages class
  /// [icon] - Optional custom icon (default: error_outline)
  static void showById(
    BuildContext context, {
    required int errorId,
    IconData icon = Icons.error_outline,
  }) {
    final message = ErrorMessages.getErrorMessage(errorId);
    show(context, message: message, icon: icon);
  }

  /// Shows an error message that pops up from the bottom with a bouncy effect.
  /// 
  /// [context] - The BuildContext to show the message in
  /// [message] - The error message to display
  /// [duration] - How long to show the message (default: from ErrorMessages config)
  /// [icon] - Optional custom icon (default: error_outline)
  static void show(
    BuildContext context, {
    required String message,
    Duration? duration,
    IconData icon = Icons.error_outline,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _GlassErrorOverlay(
        message: message,
        icon: icon,
        duration: duration ?? ErrorMessages.displayDuration,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _GlassErrorOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _GlassErrorOverlay({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_GlassErrorOverlay> createState() => _GlassErrorOverlayState();
}

class _GlassErrorOverlayState extends State<_GlassErrorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );

    // Bouncy slide from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    // Subtle scale for extra bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                // Dark glass background from config
                color: ErrorMessages.backgroundColor.withOpacity(ErrorMessages.backgroundOpacity),
                borderRadius: BorderRadius.circular(ErrorMessages.borderRadius),
                // Red glass stroke from config
                border: Border.all(
                  width: ErrorMessages.borderWidth,
                  color: ErrorMessages.borderColor.withOpacity(ErrorMessages.borderOpacity),
                ),
                // Subtle glow effect
                boxShadow: [
                  BoxShadow(
                    color: ErrorMessages.glowColor.withOpacity(ErrorMessages.glowOpacity),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Error icon with glow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ErrorMessages.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: ErrorMessages.iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Error message
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: ErrorMessages.textColor,
                        fontSize: ErrorMessages.textSize,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dismiss hint
                  Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

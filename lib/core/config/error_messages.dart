import 'package:flutter/material.dart';

/// Centralized error message configuration and display logic for the entire app.
/// Define styling at the top, error IDs in the middle, and display logic at the bottom.
class ErrorMessages {
  // ==================== STYLING CONFIGURATION ====================
  
  /// Background color for error messages
  static const Color backgroundColor = Colors.black;
  
  /// Background opacity
  static const double backgroundOpacity = 0.75;
  
  /// Border color (red glass stroke)
  static const Color borderColor = Colors.redAccent;
  
  /// Border opacity
  static const double borderOpacity = 0.6;
  
  /// Border width
  static const double borderWidth = 1.5;
  
  /// Border radius
  static const double borderRadius = 20.0;
  
  /// Icon color
  static const Color iconColor = Colors.redAccent;
  
  /// Text color
  static const Color textColor = Colors.white;
  
  /// Text size
  static const double textSize = 15.0;
  
  /// Duration to show the error message
  static const Duration displayDuration = Duration(seconds: 3);
  
  /// Glow effect color
  static const Color glowColor = Colors.redAccent;
  
  /// Glow opacity
  static const double glowOpacity = 0.2;
  
  /// Animation duration for bounce effect
  static const Duration animationDuration = Duration(milliseconds: 600);
  
  /// Reverse animation duration
  static const Duration reverseAnimationDuration = Duration(milliseconds: 400);
  
  // ==================== INPUT FIELD ERROR STYLING ====================
  
  /// Error style for TextFormField validators (hides inline error text completely)
  /// This ensures no yellow underline or error text appears below input fields
  static const TextStyle errorStyle = TextStyle(
    fontSize: 0,
    height: 0,
    color: Colors.transparent,
  );
  
  /// Error border style for TextFormField (no border change on error)
  static const InputBorder errorBorder = InputBorder.none;
  
  /// Focused error border style for TextFormField (no border change on error)
  static const InputBorder focusedErrorBorder = InputBorder.none;
  
  /// Complete InputDecoration configuration to hide all error UI elements
  /// Apply this to any TextFormField to ensure errors only show via popup
  static InputDecoration getErrorFreeDecoration({
    String? hintText,
    TextStyle? hintStyle,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
    InputBorder? border,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    bool? filled,
    Color? fillColor,
    bool? isDense,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      border: border ?? InputBorder.none,
      enabledBorder: enabledBorder ?? InputBorder.none,
      focusedBorder: focusedBorder ?? InputBorder.none,
      errorBorder: errorBorder,
      focusedErrorBorder: focusedErrorBorder,
      errorStyle: errorStyle,
      filled: filled,
      fillColor: fillColor,
      isDense: isDense,
    );
  }
  
  // ==================== ERROR MESSAGE DEFINITIONS ====================
  
  /// Error ID 1: User did not enter email
  static const String errorId1 = 'Please enter your email';
  
  /// Error ID 2: User did not enter password
  static const String errorId2 = 'Please enter your password';
  
  /// Error ID 3: Invalid email format
  static const String errorId3 = 'Please enter a valid email';
  
  /// Error ID 4: Both email and password are empty
  static const String errorId4 = 'Please enter your email and password';
  
  /// Error ID 5: Incorrect email or password
  static const String errorId5 = 'Incorrect email or password';
  
  /// Error ID 6: Network error
  static const String errorId6 = 'Network error. Please check your connection';
  
  /// Error ID 7: Server error
  static const String errorId7 = 'Server error. Please try again later';
  
  /// Error ID 8: Session expired
  static const String errorId8 = 'Your session has expired. Please sign in again';
  
  /// Error ID 9: Account not found
  static const String errorId9 = 'Account not found. Please check your email';
  
  /// Error ID 10: Account locked
  static const String errorId10 = 'Account temporarily locked. Please try again later';
  
  // Add more error IDs as needed...
  
  // ==================== HELPER METHODS ====================
  
  /// Get error message by ID
  static String getErrorMessage(int errorId) {
    switch (errorId) {
      case 1:
        return errorId1;
      case 2:
        return errorId2;
      case 3:
        return errorId3;
      case 4:
        return errorId4;
      case 5:
        return errorId5;
      case 6:
        return errorId6;
      case 7:
        return errorId7;
      case 8:
        return errorId8;
      case 9:
        return errorId9;
      case 10:
        return errorId10;
      default:
        return 'An error occurred. Please try again';
    }
  }

  // ==================== DISPLAY LOGIC ====================

  /// Shows an error message by ID that pops up from the bottom with a bouncy effect.
  /// 
  /// [context] - The BuildContext to show the message in
  /// [errorId] - The error ID to display
  /// [icon] - Optional custom icon (default: error_outline)
  static void showById(
    BuildContext context, {
    required int errorId,
    IconData icon = Icons.error_outline,
  }) {
    final message = getErrorMessage(errorId);
    show(context, message: message, icon: icon);
  }

  /// Shows an error message that pops up from the bottom with a bouncy effect.
  /// 
  /// [context] - The BuildContext to show the message in
  /// [message] - The error message to display
  /// [duration] - How long to show the message (default: from config)
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
      builder: (context) => _ErrorMessageOverlay(
        message: message,
        icon: icon,
        duration: duration ?? displayDuration,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

// ==================== PRIVATE OVERLAY WIDGET ====================

class _ErrorMessageOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ErrorMessageOverlay({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ErrorMessageOverlay> createState() => _ErrorMessageOverlayState();
}

class _ErrorMessageOverlayState extends State<_ErrorMessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: ErrorMessages.animationDuration,
      reverseDuration: ErrorMessages.reverseAnimationDuration,
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
                        decoration: TextDecoration.none,
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

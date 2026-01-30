import 'package:flutter/material.dart';

/// A modern, reusable input field with a dark glass-like appearance.
/// Use this for email, password, or any text input in forms.
class GlassInputField extends StatelessWidget {
  // Required
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;

  // Optional input behavior
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  // Optional styling overrides
  final Color backgroundColor;
  final double backgroundOpacity;
  final double borderRadius;
  final Color borderColor;
  final double borderOpacity;
  final double borderWidth;
  final Color textColor;
  final double textSize;
  final Color hintColor;
  final double hintOpacity;
  final Color iconColor;
  final double iconSize;

  const GlassInputField({
    super.key,
    // Required
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    // Input behavior defaults
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.onChanged,
    this.suffixIcon,
    // Styling defaults
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.5,
    this.borderRadius = 16.0,
    this.borderColor = Colors.white,
    this.borderOpacity = 0.3,
    this.borderWidth = 1.0,
    this.textColor = Colors.white,
    this.textSize = 18.0,
    this.hintColor = Colors.white70,
    this.hintOpacity = 0.6,
    this.iconColor = Colors.white70,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          width: borderWidth,
          color: borderColor.withOpacity(borderOpacity),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(prefixIcon, color: iconColor, size: iconSize),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              autocorrect: autocorrect,
              onChanged: onChanged,
              style: TextStyle(
                color: textColor,
                fontSize: textSize,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: labelText,
                hintStyle: TextStyle(
                  color: hintColor.withOpacity(hintOpacity),
                  fontSize: textSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}

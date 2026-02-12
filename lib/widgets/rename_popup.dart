import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern frosted-glass popup for renaming a light or zone.
///
/// Returns the new name as a [String] via [Navigator.pop], or `null`
/// if dismissed without saving.
///
/// [itemType] should be `'Light'` or `'Zone'` — controls the label shown.
/// [currentName] pre-fills the text field.
///
/// Usage:
/// ```dart
/// final newName = await showRenamePopup(
///   context,
///   itemType: 'Light',
///   currentName: 'B4D0 CHANNEL-1',
/// );
/// ```
Future<String?> showRenamePopup(
  BuildContext context, {
  required String itemType,
  required String currentName,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss rename',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => _RenamePopupContent(
      itemType: itemType,
      currentName: currentName,
    ),
  );
}

class _RenamePopupContent extends StatefulWidget {
  final String itemType;
  final String currentName;

  const _RenamePopupContent({
    required this.itemType,
    required this.currentName,
  });

  @override
  State<_RenamePopupContent> createState() => _RenamePopupContentState();
}

class _RenamePopupContentState extends State<_RenamePopupContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _focusNode = FocusNode();
    // Auto-focus and select all text after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && text != widget.currentName) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, text);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.itemType == 'Zone' ? 'Rename Zone' : 'Rename Light';

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white.withOpacity(0.85),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Text field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        cursorColor: const Color(0xFFF58220),
                        decoration: InputDecoration(
                          hintText: 'Enter new name',
                          hintStyle: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save button
                        Expanded(
                          child: GestureDetector(
                            onTap: _submit,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF58220).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFF58220).withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF58220),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Model class for a channel pin placed on the image
class ChannelPin {
  final String channelName;
  final String lightName;
  double xPercent; // Position as percentage of image width (0.0 - 1.0)
  double yPercent; // Position as percentage of image height (0.0 - 1.0)

  ChannelPin({
    required this.channelName,
    required this.lightName,
    this.xPercent = 0.5,
    this.yPercent = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'channelName': channelName,
    'lightName': lightName,
    'xPercent': xPercent,
    'yPercent': yPercent,
  };

  factory ChannelPin.fromJson(Map<String, dynamic> json) => ChannelPin(
    channelName: json['channelName'] ?? '',
    lightName: json['lightName'] ?? '',
    xPercent: (json['xPercent'] ?? 0.5).toDouble(),
    yPercent: (json['yPercent'] ?? 0.5).toDouble(),
  );
}

class ImageViewContent extends StatefulWidget {
  final List<String> channels; // List of channel names from the location
  final bool isChannelPlacementMode;
  final int selectedChannelIndex;
  final ValueChanged<int>? onChannelSelected;
  final VoidCallback? onEnterPlacementMode;
  final VoidCallback? onExitPlacementMode;

  const ImageViewContent({
    super.key,
    this.channels = const [],
    this.isChannelPlacementMode = false,
    this.selectedChannelIndex = 0,
    this.onChannelSelected,
    this.onEnterPlacementMode,
    this.onExitPlacementMode,
  });

  @override
  State<ImageViewContent> createState() => _ImageViewContentState();
}

class _ImageViewContentState extends State<ImageViewContent> {
  static const String _imagePathKey = 'saved_house_image_path';
  static const String _channelPinsKey = 'saved_channel_pins';

  String? _savedImagePath;
  String? _tempImagePath;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  double _imageOffsetX = 0.0;
  bool _showEditToolbar = false;

  // Channel placement mode
  List<ChannelPin> _placedPins = [];
  String? _draggingPinChannel; // Track which pin is being dragged

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
    _loadSavedPins();
  }

  @override
  void didUpdateWidget(ImageViewContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Save pins when exiting placement mode
    if (oldWidget.isChannelPlacementMode && !widget.isChannelPlacementMode) {
      _savePins();
    }
  }

  Future<void> _loadSavedImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_imagePathKey);

      if (savedPath != null && await File(savedPath).exists()) {
        setState(() {
          _savedImagePath = savedPath;
          _isLoading = false;
        });
      } else {
        setState(() {
          _savedImagePath = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinsJson = prefs.getString(_channelPinsKey);
      if (pinsJson != null) {
        final List<dynamic> decoded = jsonDecode(pinsJson);
        setState(() {
          _placedPins = decoded.map((e) => ChannelPin.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading saved pins: $e');
    }
  }

  Future<void> _savePins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinsJson = jsonEncode(_placedPins.map((e) => e.toJson()).toList());
      await prefs.setString(_channelPinsKey, pinsJson);
    } catch (e) {
      debugPrint('Error saving pins: $e');
    }
  }

  void _enterChannelPlacementMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showEditToolbar = false;
    });
    widget.onEnterPlacementMode?.call();
  }

  void _placeSelectedChannel(double xPercent, double yPercent) {
    if (widget.channels.isEmpty) return;

    final channelName = widget.channels[widget.selectedChannelIndex];

    // Check if channel is already placed
    final existingIndex = _placedPins.indexWhere(
      (pin) => pin.channelName == channelName,
    );

    if (existingIndex >= 0) {
      // Update existing pin position
      setState(() {
        _placedPins[existingIndex].xPercent = xPercent;
        _placedPins[existingIndex].yPercent = yPercent;
      });
    } else {
      // Add new pin
      setState(() {
        _placedPins.add(
          ChannelPin(
            channelName: channelName,
            lightName: channelName,
            xPercent: xPercent,
            yPercent: yPercent,
          ),
        );
      });
    }

    HapticFeedback.lightImpact();
    _savePins();
  }

  void _showPhotoOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Photo',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an image of your house',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A7BD5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF3A7BD5)),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Use camera to capture image',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4842A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFFD4842A),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _tempImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to pick image',
              style: TextStyle(fontFamily: 'SpaceMono'),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_tempImagePath == null) return;

    try {
      // Copy image to app's documents directory for permanent storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'house_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(directory.path, fileName);

      await File(_tempImagePath!).copy(savedPath);

      // Save the path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Delete old image if it exists
      final oldPath = prefs.getString(_imagePathKey);
      if (oldPath != null && await File(oldPath).exists()) {
        await File(oldPath).delete();
      }

      await prefs.setString(_imagePathKey, savedPath);

      setState(() {
        _savedImagePath = savedPath;
        _tempImagePath = null;
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo saved successfully!',
              style: TextStyle(fontFamily: 'SpaceMono'),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to save image',
              style: TextStyle(fontFamily: 'SpaceMono'),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _cancelTempImage() {
    HapticFeedback.mediumImpact();
    setState(() {
      _tempImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
        ),
      );
    }

    // Show temp image preview with save/cancel options
    if (_tempImagePath != null) {
      return _buildTempImagePreview();
    }

    // Show saved image
    if (_savedImagePath != null) {
      return _buildSavedImageView();
    }

    // Show attach photo button
    return _buildAttachPhotoView();
  }

  Widget _buildAttachPhotoView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Image',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attach a photo of your house to view your lights',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _showPhotoOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3A7BD5).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Attach Photo',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(_tempImagePath!), fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _cancelTempImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF484848),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3D3D3D),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _saveImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Save Photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelPlacementView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;

        return Stack(
          children: [
            // Grey background container
            Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Image with pins
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTapUp: (details) {
                        // Calculate tap position as percentage
                        final xPercent =
                            details.localPosition.dx / (viewportWidth - 16);
                        final yPercent =
                            details.localPosition.dy / (viewportHeight - 16);
                        _placeSelectedChannel(
                          xPercent.clamp(0.0, 1.0),
                          yPercent.clamp(0.0, 1.0),
                        );
                      },
                      child: Stack(
                        children: [
                          // The house image (dimmed)
                          Opacity(
                            opacity: 0.6,
                            child: Image.file(
                              File(_savedImagePath!),
                              fit: BoxFit.cover,
                              width: viewportWidth - 16,
                              height: viewportHeight - 16,
                            ),
                          ),
                          // Placed pins
                          ..._placedPins.map((pin) {
                            final pinX = pin.xPercent * (viewportWidth - 16);
                            final pinY = pin.yPercent * (viewportHeight - 16);
                            final isSelected =
                                widget.channels.isNotEmpty &&
                                widget.selectedChannelIndex <
                                    widget.channels.length &&
                                widget.channels[widget.selectedChannelIndex] ==
                                    pin.channelName;

                            return Positioned(
                              left: pinX - 20,
                              top: pinY - 20,
                              child: GestureDetector(
                                onPanStart: (_) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _draggingPinChannel = pin.channelName;
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    // Calculate new position based on current pin position + delta
                                    final currentX = pin.xPercent * (viewportWidth - 16);
                                    final currentY = pin.yPercent * (viewportHeight - 16);
                                    final newX = currentX + details.delta.dx;
                                    final newY = currentY + details.delta.dy;
                                    pin.xPercent = (newX / (viewportWidth - 16)).clamp(0.0, 1.0);
                                    pin.yPercent = (newY / (viewportHeight - 16)).clamp(0.0, 1.0);
                                  });
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _draggingPinChannel = null;
                                  });
                                  _savePins();
                                  HapticFeedback.lightImpact();
                                },
                                child: AnimatedScale(
                                  scale: _draggingPinChannel == pin.channelName ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFFD4842A,
                                            ).withOpacity(0.9)
                                          : Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFD4842A),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: _draggingPinChannel == pin.channelName ? 16 : 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Instructions at top
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap on the image to place the selected channel. Drag pins to reposition.',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Done button at bottom
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _savePins();
                    widget.onExitPlacementMode?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4842A),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4842A).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavedImageView() {
    // If in channel placement mode, show that view instead
    if (widget.isChannelPlacementMode) {
      return _buildChannelPlacementView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<ImageInfo>(
          future: _getImageInfo(File(_savedImagePath!)),
          builder: (context, snapshot) {
            double minOffset = 0.0;
            double maxOffset = 0.0;

            if (snapshot.hasData) {
              final imageInfo = snapshot.data!;
              final imageWidth = imageInfo.image.width.toDouble();
              final imageHeight = imageInfo.image.height.toDouble();

              // Calculate the actual rendered width when fitting to height
              final aspectRatio = imageWidth / imageHeight;
              final renderedHeight = constraints.maxHeight - 16;
              final renderedWidth = renderedHeight * aspectRatio;

              // Calculate how much we can pan (only if image is wider than viewport)
              final viewportWidth = constraints.maxWidth - 16;
              final overflowWidth = renderedWidth - viewportWidth;

              if (overflowWidth > 0) {
                // Image is wider than viewport, allow panning
                minOffset = -overflowWidth / 2;
                maxOffset = overflowWidth / 2;
              }
            }

            return Stack(
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _imageOffsetX += details.delta.dx;
                      // Stop at the edges of the photo
                      _imageOffsetX = _imageOffsetX.clamp(minOffset, maxOffset);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        child: Transform.translate(
                          offset: Offset(_imageOffsetX, 0),
                          child: Stack(
                            children: [
                              Image.file(
                                File(_savedImagePath!),
                                fit: BoxFit.fitHeight,
                                height: constraints.maxHeight - 16,
                              ),
                              // Placed pins (move with image)
                              if (snapshot.hasData)
                                ..._placedPins.map((pin) {
                                  final imageInfo = snapshot.data!;
                                  final imageWidth = imageInfo.image.width
                                      .toDouble();
                                  final imageHeight = imageInfo.image.height
                                      .toDouble();
                                  final aspectRatio = imageWidth / imageHeight;
                                  final renderedHeight =
                                      constraints.maxHeight - 16;
                                  final renderedWidth =
                                      renderedHeight * aspectRatio;

                                  final pinX = pin.xPercent * renderedWidth;
                                  final pinY = pin.yPercent * renderedHeight;

                                  return Positioned(
                                    left: pinX - 16,
                                    top: pinY - 16,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFD4842A,
                                        ).withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.lightbulb,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Edit button (top left)
                Positioned(
                  top: 24,
                  left: 24,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _showEditToolbar = !_showEditToolbar;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4842A),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // Edit toolbar (appears when edit button is clicked)
                if (_showEditToolbar)
                  Positioned(
                    top: 24,
                    left: 84,
                    child: Row(
                      children: [
                        // Plus icon button - enters channel placement mode
                        GestureDetector(
                          onTap: _enterChannelPlacementMode,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4842A),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Bubble/circle button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            // TODO: Implement bubble functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Bubble feature coming soon!',
                                  style: TextStyle(fontFamily: 'SpaceMono'),
                                ),
                                backgroundColor: const Color(0xFF3A7BD5),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4842A),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.circle_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Three dot menu button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            // TODO: Implement menu functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Menu feature coming soon!',
                                  style: TextStyle(fontFamily: 'SpaceMono'),
                                ),
                                backgroundColor: const Color(0xFF3A7BD5),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4842A),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Save as scene button (bottom)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        // TODO: Implement save as scene functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Save as scene coming soon!',
                              style: TextStyle(fontFamily: 'SpaceMono'),
                            ),
                            backgroundColor: const Color(0xFF3A7BD5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          border: Border.all(
                            color: const Color(0xFFD4842A),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Save as scene',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ImageInfo> _getImageInfo(File file) async {
    final completer = Completer<ImageInfo>();
    final image = FileImage(file);
    final stream = image.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener((info, _) {
        if (!completer.isCompleted) {
          completer.complete(info);
        }
      }),
    );

    return completer.future;
  }
}

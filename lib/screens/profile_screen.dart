import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isProfilePicSelected = false;
  final ImagePicker _picker = ImagePicker();

  void _onProfilePicTap() {
    if (_isProfilePicSelected) {
      // Already selected, show photo picker
      _showPhotoOptions();
    } else {
      // First tap, show edit overlay
      setState(() {
        _isProfilePicSelected = true;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Handle the selected image (upload, save, etc.)
      debugPrint('Selected image: ${image.path}');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Choose from Library',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement remove photo
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Deselect profile pic when tapping elsewhere
            if (_isProfilePicSelected) {
              setState(() {
                _isProfilePicSelected = false;
              });
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Centered profile picture
                GestureDetector(
                  onTap: _onProfilePicTap,
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isProfilePicSelected
                              ? const Color(0xFFF57F20).withOpacity(0.1)
                              : const Color(0xFFF57F20).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFFF57F20),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isProfilePicSelected ? 0.4 : 1.0,
                            child: Text(
                              widget.userName.isNotEmpty
                                  ? widget.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Edit overlay
                      if (_isProfilePicSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Profile options
                _buildOptionItem(
                  imagePath: 'assets/images/userinfo.png',
                  title: 'Personal Information',
                  onTap: () {
                    // TODO: Navigate to personal information
                  },
                ),
                _buildOptionItem(
                  imagePath: 'assets/images/changepassword.png',
                  title: 'Change Account Password',
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                const Spacer(),
                // Sign out button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Handle sign out
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    String? imagePath,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: imagePath != null
          ? Image.asset(
              imagePath,
              width: 24,
              height: 24,
              color: isDestructive ? Colors.red : const Color(0xFF686868),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? Colors.red : Colors.white,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

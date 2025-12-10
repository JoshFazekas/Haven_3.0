import 'package:flutter/material.dart';
import 'package:haven/screens/profile_screen.dart';
import 'package:haven/screens/gameday_screen.dart';
import 'package:haven/screens/add_device_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // TODO: Replace with actual user data
  final String userName = 'Josh Fazekas';
  final String userEmail = 'josh@example.com';

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
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile section
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userName: userName,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Profile picture with initial
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57F20).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFF57F20),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),

              // Menu items
              _buildMenuItem(
                imagePath: 'assets/images/locationsetting.png',
                title: 'Location Settings',
                onTap: () {
                  // TODO: Navigate to location settings
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/viewalllocations.png',
                title: 'View All Locations',
                onTap: () {
                  // TODO: Navigate to view all locations
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/datasharing.png',
                title: 'Data sharing',
                onTap: () {
                  // TODO: Navigate to data sharing
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/addcontroller.png',
                title: 'Add Controller',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddDeviceScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/addlight.png',
                title: 'Add light',
                onTap: () {
                  // TODO: Navigate to add light
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/sports.png',
                title: 'Sports',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GamedayScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/configuredevice.png',
                title: 'Configure Device',
                onTap: () {
                  // TODO: Navigate to configure device
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/description.png',
                title: 'Description',
                onTap: () {
                  // TODO: Navigate to description
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/shopstore.png',
                title: 'Shop store',
                onTap: () {
                  // TODO: Navigate to shop store
                },
              ),
              _buildMenuItem(
                imagePath: 'assets/images/learnmore.png',
                title: 'Learn more',
                onTap: () {
                  // TODO: Navigate to learn more
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Image.asset(
        imagePath,
        width: 24,
        height: 24,
        color: isDestructive ? Colors.red : const Color(0xFF686868),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? Colors.red : Colors.white,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

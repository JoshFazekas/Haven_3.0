import 'package:flutter/material.dart';
import 'select_team_screen.dart';

class SelectLeagueScreen extends StatelessWidget {
  final List<Map<String, String>> existingTeams;

  const SelectLeagueScreen({super.key, this.existingTeams = const []});

  /// League data with name, colors, and image
  static const List<Map<String, dynamic>> _leagues = [
    {
      'name': 'NFL',
      'fullName': 'National Football League',
      'color1': Color(0xFF013369), // NFL Blue
      'image': 'nfl.png',
    },
    {
      'name': 'MLB',
      'fullName': 'Major League Baseball',
      'color1': Color(0xFF002D72), // MLB Blue
      'image': 'mlb.png',
    },
    {
      'name': 'NBA',
      'fullName': 'National Basketball Association',
      'color1': Color(0xFF1D428A), // NBA Blue
      'image': 'nba.png',
    },
    {
      'name': 'NHL',
      'fullName': 'National Hockey League',
      'color1': Color(0xFFFFFFFF), // NHL White
      'image': 'nhl.png',
    },
    {
      'name': 'MLS',
      'fullName': 'Major League Soccer',
      'color1': Color(0xFF0C2340), // MLS Blue
      'image': 'mls.png',
    },
    {
      'name': 'NCAAFB',
      'fullName': 'College Football',
      'color1': Color(0xFF003087), // Blue
      'image': 'collegefb.png',
    },
    {
      'name': 'NCAABB',
      'fullName': 'College Basketball',
      'color1': Color(0xFF4B2E83), // Purple
      'image': 'collegebb.png',
    },
  ];

  Widget _buildLeagueContainer(BuildContext context, Map<String, dynamic> league) {
    final name = league['name'] as String;
    final image = league['image'] as String;
    final isEnabled = name == 'NFL'; // Only NFL is enabled for now

    return GestureDetector(
      onTap: isEnabled
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SelectTeamScreen(
                    league: name,
                    existingTeams: existingTeams,
                  ),
                ),
              );
            }
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(
                  'assets/images/$image',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: const Color(0xFF2E2E2E));
                  },
                ),
                // Dark overlay for better text readability
                Container(
                  color: Colors.black.withOpacity(0.6),
                ),
                // League name in the center
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // "Coming Soon" overlay for disabled leagues
                if (!isEnabled)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Arrow for enabled leagues
                if (isEnabled)
                  const Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'GAME',
              style: TextStyle(
                fontFamily: 'ZCOOLKuaiLe',
                fontSize: 24,
                color: Color(0xFFF57F20),
              ),
            ),
            SizedBox(width: 4),
            Text(
              'DAY',
              style: TextStyle(
                fontFamily: 'ZCOOLKuaiLe',
                fontSize: 24,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: 24.0,
          ),
          itemCount: _leagues.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildLeagueContainer(context, _leagues[index]),
            );
          },
        ),
      ),
    );
  }
}

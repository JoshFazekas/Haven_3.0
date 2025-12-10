import 'package:flutter/material.dart';
import 'package:haven/core/services/team_storage_service.dart';
import 'select_league_screen.dart';
import 'my_teams_screen.dart';

class GamedayScreen extends StatefulWidget {
  const GamedayScreen({super.key});

  @override
  State<GamedayScreen> createState() => _GamedayScreenState();
}

class _GamedayScreenState extends State<GamedayScreen> {
  bool _isLoading = true;
  bool _hasTeams = false;
  List<Map<String, String>> _savedTeams = [];
  List<Map<String, String>> _savedDisabledTeams = [];

  @override
  void initState() {
    super.initState();
    _loadSavedTeams();
  }

  Future<void> _loadSavedTeams() async {
    debugPrint('GamedayScreen: Loading saved teams...');
    final teams = await TeamStorageService.loadTeams();
    final disabledTeams = await TeamStorageService.loadDisabledTeams();
    
    debugPrint('GamedayScreen: Loaded ${teams.length} teams and ${disabledTeams.length} disabled teams');
    debugPrint('GamedayScreen: Teams = $teams');
    
    setState(() {
      _savedTeams = teams;
      _savedDisabledTeams = disabledTeams;
      _hasTeams = teams.isNotEmpty || disabledTeams.isNotEmpty;
      _isLoading = false;
    });
    
    debugPrint('GamedayScreen: _hasTeams = $_hasTeams');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF242424),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFF57F20)),
        ),
      );
    }

    // If user has saved teams, show MyTeamsScreen directly
    if (_hasTeams) {
      return MyTeamsScreen(
        selectedTeams: _savedTeams,
        disabledTeams: _savedDisabledTeams,
      );
    }

    // Otherwise show the initial "Add Team" screen
    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/gamedaylogo.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Haven Game Day text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Haven',
                    style: TextStyle(
                      fontFamily: 'ZCOOLKuaiLe',
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Game',
                    style: TextStyle(
                      fontFamily: 'ZCOOLKuaiLe',
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Day',
                    style: TextStyle(
                      fontFamily: 'ZCOOLKuaiLe',
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Bullet points
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletPoint(
                    text: 'Connect your lighting system to your favorite professional and college teams!',
                  ),
                  SizedBox(height: 16),
                  _BulletPoint(
                    text: 'Automatically change your lights to team colors when a game starts!',
                  ),
                  SizedBox(height: 16),
                  _BulletPoint(
                    text: 'Celebrate wins!',
                  ),
                ],
              ),
              const Spacer(flex: 1),
              // Add Team button with tiger image behind
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tiger image positioned behind the right side of the button
                    Positioned(
                      right: 20,
                      top: -140,
                      child: Image.asset(
                        'assets/images/tiger102.png',
                        height: 140,
                      ),
                    ),
                    // The button on top
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SelectLeagueScreen(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF57F20),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Add Team',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•  ',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF828282),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF828282),
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'select_team_screen.dart';

class SelectLeagueScreen extends StatelessWidget {
  final List<Map<String, String>> existingTeams;

  const SelectLeagueScreen({super.key, this.existingTeams = const []});

  @override
  Widget build(BuildContext context) {
    final leagues = [
      'mlb.png',
      'nfl.png',
      'nba.png',
      'nhl.png',
      'mls.png',
      'ncaafb.png',
      'ncaabb.png',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset('assets/images/gamedaylogo.png', height: 32),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: 8.0,
          ),
          itemCount: leagues.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                  if (leagues[index] == 'nfl.png') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SelectTeamScreen(
                          league: 'NFL',
                          existingTeams: existingTeams,
                        ),
                      ),
                    );
                  } else {
                    // TODO: Navigate to team selection for other leagues
                    debugPrint('Selected league: ${leagues[index]}');
                  }
                },
                child: Image.asset(
                  'assets/images/${leagues[index]}',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'team_selection_animation_screen.dart';

class SelectTeamScreen extends StatefulWidget {
  final String league;
  final List<Map<String, String>> existingTeams;

  const SelectTeamScreen({
    super.key,
    required this.league,
    this.existingTeams = const [],
  });

  @override
  State<SelectTeamScreen> createState() => _SelectTeamScreenState();
}

class _SelectTeamScreenState extends State<SelectTeamScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _nflTeams = [
    {'name': 'Bears', 'image': 'bears.png'},
    {'name': 'Bengals', 'image': 'bengals.png'},
    {'name': 'Bills', 'image': 'bills.png'},
    {'name': 'Browns', 'image': 'browns.png'},
    {'name': 'Cardinals', 'image': 'cardinal.png'},
    {'name': 'Cowboys', 'image': 'cowboys.png'},
    {'name': 'Falcons', 'image': 'falcon.png'},
    {'name': 'Panthers', 'image': 'panthers.png'},
    {'name': 'Ravens', 'image': 'ravens.png'},
  ];

  List<Map<String, String>> get _filteredTeams {
    if (_searchQuery.isEmpty) {
      return _nflTeams;
    }
    final query = _searchQuery.toLowerCase();
    return _nflTeams
        .where(
          (team) {
            final teamName = team['name']!.toLowerCase();
            final fullName = _getFullTeamName(team['name']!).toLowerCase();
            return teamName.contains(query) || fullName.contains(query);
          },
        )
        .toList();
  }

  /// Check if a team is already added
  bool _isTeamAlreadyAdded(String teamName) {
    return widget.existingTeams.any(
      (team) => team['name']?.toLowerCase() == teamName.toLowerCase(),
    );
  }

  /// Returns the team logo path
  String _getTeamLogo(String teamName) {
    switch (teamName.toLowerCase()) {
      case 'bengals':
        return 'assets/images/bengalslogo.png';
      case 'bills':
        return 'assets/images/billslogo.png';
      case 'bears':
        return 'assets/images/bearslogo.png';
      case 'browns':
        return 'assets/images/brownslogo.png';
      case 'cardinals':
        return 'assets/images/cardinallogo.png';
      case 'cowboys':
        return 'assets/images/cowboyslogo.png';
      case 'falcons':
        return 'assets/images/falconlogo.png';
      case 'panthers':
        return 'assets/images/pantherslogo.png';
      case 'ravens':
        return 'assets/images/ravenslogo.png';
      default:
        return 'assets/images/havenlogo.png';
    }
  }

  /// Returns the full team name with city
  String _getFullTeamName(String teamName) {
    switch (teamName.toLowerCase()) {
      case 'bengals':
        return 'Cincinnati Bengals';
      case 'bills':
        return 'Buffalo Bills';
      case 'bears':
        return 'Chicago Bears';
      case 'browns':
        return 'Cleveland Browns';
      case 'cardinals':
        return 'Arizona Cardinals';
      case 'cowboys':
        return 'Dallas Cowboys';
      case 'falcons':
        return 'Atlanta Falcons';
      case 'panthers':
        return 'Carolina Panthers';
      case 'ravens':
        return 'Baltimore Ravens';
      default:
        return teamName;
    }
  }

  /// Returns the team's primary and secondary colors
  (Color, Color) _getTeamColors(String teamName) {
    switch (teamName.toLowerCase()) {
      case 'bengals':
        return (const Color(0xFFEF5704), const Color(0xFF000000));
      case 'bills':
        return (const Color(0xFF00338D), const Color(0xFFFFFFFF));
      case 'bears':
        return (const Color(0xFF0B162A), const Color(0xFFC83803));
      case 'browns':
        return (const Color(0xFF311D00), const Color(0xFFFF3C00));
      case 'cardinals':
        return (const Color(0xFF97233F), const Color(0xFFFFFFFF));
      case 'cowboys':
        return (const Color(0xFF003594), const Color(0xFFB0B7BC));
      case 'falcons':
        return (const Color(0xFFA71930), const Color(0xFF000000));
      case 'panthers':
        return (const Color(0xFF0085CA), const Color(0xFF000000));
      case 'ravens':
        return (const Color(0xFF241773), const Color(0xFF9E7C0C));
      default:
        return (const Color(0xFFF57F20), const Color(0xFFFFFFFF));
    }
  }

  /// Builds the team container widget
  Widget _buildTeamContainer(String teamName, {bool isAlreadyAdded = false}) {
    final teamColors = _getTeamColors(teamName);
    final teamLogo = _getTeamLogo(teamName);
    final fullTeamName = _getFullTeamName(teamName);

    return Container(
      width: double.infinity,
      height: 67,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teamColors.$1.withOpacity(isAlreadyAdded ? 0.3 : 0.6),
            teamColors.$2.withOpacity(isAlreadyAdded ? 0.3 : 0.6),
            teamColors.$1.withOpacity(isAlreadyAdded ? 0.3 : 0.6),
            teamColors.$2.withOpacity(isAlreadyAdded ? 0.3 : 0.6),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Opacity(
              opacity: isAlreadyAdded ? 0.5 : 1.0,
              child: Image.asset(
                teamLogo,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 36,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fullTeamName,
                style: TextStyle(
                  color: isAlreadyAdded ? Colors.grey : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
              color: isAlreadyAdded ? Colors.green : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search teams...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            // Teams list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 6.0,
                  right: 6.0,
                  bottom: 8.0,
                ),
                itemCount: _filteredTeams.length,
                itemBuilder: (context, index) {
                  final team = _filteredTeams[index];
                  final isAlreadyAdded = _isTeamAlreadyAdded(team['name'] ?? '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: isAlreadyAdded
                          ? null
                          : () {
                              // Add team to selected teams and navigate to animation
                              final updatedTeams = [...widget.existingTeams, team];
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => TeamSelectionAnimationScreen(
                                    selectedTeam: team,
                                    allSelectedTeams: updatedTeams,
                                  ),
                                ),
                              );
                            },
                      child: _buildTeamContainer(team['name'] ?? '', isAlreadyAdded: isAlreadyAdded),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

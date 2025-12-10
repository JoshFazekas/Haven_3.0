import 'package:flutter/material.dart';
import 'package:haven/core/services/team_storage_service.dart';
import 'select_league_screen.dart';

class MyTeamsScreen extends StatefulWidget {
  final List<Map<String, String>> selectedTeams;
  final List<Map<String, String>> disabledTeams;

  const MyTeamsScreen({
    super.key,
    required this.selectedTeams,
    this.disabledTeams = const [],
  });

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  List<Map<String, String>> _teams = [];
  List<Map<String, String>> _disabledTeams = [];

  @override
  void initState() {
    super.initState();
    _teams = List.from(widget.selectedTeams);
    _disabledTeams = List.from(widget.disabledTeams);
    // Save teams when screen is initialized with new teams
    _saveTeamsOnInit();
  }

  void _saveTeamsOnInit() {
    // Only save if there are teams (to avoid clearing on empty init)
    if (_teams.isNotEmpty || _disabledTeams.isNotEmpty) {
      debugPrint('MyTeamsScreen: Saving teams on init - ${_teams.length} active, ${_disabledTeams.length} disabled');
      TeamStorageService.saveTeams(_teams);
      TeamStorageService.saveDisabledTeams(_disabledTeams);
    }
  }

  void _saveTeams() {
    TeamStorageService.saveTeams(_teams);
    TeamStorageService.saveDisabledTeams(_disabledTeams);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _teams.removeAt(oldIndex);
      _teams.insert(newIndex, item);
    });
    _saveTeams();
  }

  void _onReorderDisabled(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _disabledTeams.removeAt(oldIndex);
      _disabledTeams.insert(newIndex, item);
    });
    _saveTeams();
  }

  void _disableTeam(Map<String, String> team) {
    setState(() {
      _teams.remove(team);
      _disabledTeams.add(team);
    });
    _saveTeams();
  }

  void _enableTeam(Map<String, String> team) {
    setState(() {
      _disabledTeams.remove(team);
      _teams.add(team);
    });
    _saveTeams();
  }

  void _showTeamOptions(Map<String, String> team, bool isDisabled) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isDisabled ? Icons.check_circle : Icons.block,
                  color: isDisabled ? Colors.green : Colors.grey,
                ),
                title: Text(
                  isDisabled ? 'Enable' : 'Disable',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isDisabled) {
                    _enableTeam(team);
                  } else {
                    _disableTeam(team);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int get _totalTeams => _teams.length + _disabledTeams.length;
  static const int _maxTeams = 8;

  /// Builds the team container widget
  Widget _buildTeamContainer(String teamName, Map<String, String> team, {bool isDisabled = false}) {
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
            teamColors.$1.withOpacity(isDisabled ? 0.3 : 0.6),
            teamColors.$2.withOpacity(isDisabled ? 0.3 : 0.6),
            teamColors.$1.withOpacity(isDisabled ? 0.3 : 0.6),
            teamColors.$2.withOpacity(isDisabled ? 0.3 : 0.6),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3), // Stroke width
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            // Large draggable area on the left
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.drag_handle, color: Colors.grey, size: 24),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
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
                        color: isDisabled ? Colors.grey : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot menu - not part of drag area
            GestureDetector(
              onTap: () => _showTeamOptions(team, isDisabled),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.more_vert, color: Colors.grey, size: 36),
              ),
            ),
          ],
        ),
      ),
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
        return (
          const Color(0xFFEF5704),
          const Color(0xFF000000),
        ); // Orange and Black
      case 'bills':
        return (
          const Color(0xFF00338D),
          const Color(0xFFFFFFFF),
        ); // Blue and White
      case 'bears':
        return (
          const Color(0xFF0B162A),
          const Color(0xFFC83803),
        ); // Navy and Orange
      case 'browns':
        return (
          const Color(0xFF311D00),
          const Color(0xFFFF3C00),
        ); // Brown and Orange
      case 'cardinals':
        return (
          const Color(0xFF97233F),
          const Color(0xFFFFFFFF),
        ); // Cardinal Red and White
      case 'cowboys':
        return (
          const Color(0xFF003594),
          const Color(0xFFB0B7BC),
        ); // Navy and Silver
      case 'falcons':
        return (
          const Color(0xFFA71930),
          const Color(0xFF000000),
        ); // Red and Black
      case 'panthers':
        return (
          const Color(0xFF0085CA),
          const Color(0xFF000000),
        ); // Blue and Black
      case 'ravens':
        return (
          const Color(0xFF241773),
          const Color(0xFF9E7C0C),
        ); // Purple and Gold
      default:
        return (
          const Color(0xFFF57F20),
          const Color(0xFFFFFFFF),
        ); // Default orange and white
    }
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Header
          const Padding(
            padding: EdgeInsets.only(left: 40.0, top: 16.0, bottom: 16.0),
            child: Text(
              'Active',
              style: TextStyle(
                color: Color(0xFFF57F20),
                fontSize: 18,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          // Active Teams list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active teams
                  if (_teams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'No active teams',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemCount: _teams.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        return Padding(
                          key: ValueKey('active_${index}_${team['name']}'),
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildTeamContainer(team['name'] ?? '', team),
                        );
                      },
                    ),
                  // Disabled section
                  if (_disabledTeams.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 40.0, top: 16.0, bottom: 16.0),
                      child: Text(
                        'Disabled',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      itemCount: _disabledTeams.length,
                      onReorder: _onReorderDisabled,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final team = _disabledTeams[index];
                        return Padding(
                          key: ValueKey('disabled_${index}_${team['name']}'),
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildTeamContainer(team['name'] ?? '', team, isDisabled: true),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Add Another Team button - fixed at bottom
          if (_totalTeams < _maxTeams)
            Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).padding.bottom + 16.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectLeagueScreen(existingTeams: [..._teams, ..._disabledTeams]),
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
                    'Add Another Team',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
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
    return _nflTeams
        .where(
          (team) =>
              team['name']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
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
        title: Image.asset('assets/images/gamedaylogo.png', height: 32),
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
                    borderRadius: BorderRadius.circular(12),
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
                  left: 12.0,
                  right: 12.0,
                  bottom: 8.0,
                ),
                itemCount: _filteredTeams.length,
                itemBuilder: (context, index) {
                  final team = _filteredTeams[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onTap: () {
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
                      child: Image.asset(
                        'assets/images/${team['image']}',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
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

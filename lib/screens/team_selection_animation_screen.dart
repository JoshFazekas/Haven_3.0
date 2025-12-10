import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haven/core/services/team_storage_service.dart';
import 'my_teams_screen.dart';

class TeamSelectionAnimationScreen extends StatefulWidget {
  final Map<String, String> selectedTeam;
  final List<Map<String, String>> allSelectedTeams;

  const TeamSelectionAnimationScreen({
    super.key,
    required this.selectedTeam,
    required this.allSelectedTeams,
  });

  @override
  State<TeamSelectionAnimationScreen> createState() =>
      _TeamSelectionAnimationScreenState();
}

class _TeamSelectionAnimationScreenState
    extends State<TeamSelectionAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _hasNavigated = false;
  bool _teamsSaved = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCompleted = true;
        _tryNavigate();
      }
    });
    
    // Save teams immediately when this screen loads
    _saveTeams();
    
    // Fallback timeout in case animation fails to load
    Future.delayed(const Duration(seconds: 3), () {
      if (!_hasNavigated && mounted) {
        _animationCompleted = true;
        _tryNavigate();
      }
    });
  }

  Future<void> _saveTeams() async {
    debugPrint('AnimationScreen: Saving teams...');
    await TeamStorageService.saveTeams(widget.allSelectedTeams);
    debugPrint('AnimationScreen: Teams saved!');
    _teamsSaved = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    debugPrint('AnimationScreen: _tryNavigate called - saved: $_teamsSaved, animCompleted: $_animationCompleted, hasNavigated: $_hasNavigated');
    if (_teamsSaved && _animationCompleted && !_hasNavigated && mounted) {
      _hasNavigated = true;
      debugPrint('AnimationScreen: Navigating to GamedayScreen...');
      _onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    // Navigate directly to MyTeamsScreen with the teams we just saved
    // Pop all intermediate screens (select_team, select_league, gameday) and push MyTeamsScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MyTeamsScreen(
          selectedTeams: widget.allSelectedTeams,
        ),
      ),
      (route) => route.isFirst, // Keep only the menu screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242424),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/football.json',
              controller: _animationController,
              onLoaded: (composition) {
                _animationController
                  ..duration = composition.duration
                  ..forward();
              },
              errorBuilder: (context, error, stackTrace) {
                // If animation fails to load, navigate after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!_hasNavigated && mounted) {
                    _hasNavigated = true;
                    _onAnimationComplete();
                  }
                });
                return const Icon(
                  Icons.sports_football,
                  color: Color(0xFFF57F20),
                  size: 120,
                );
              },
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.selectedTeam['name']} Added!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNavigated) {
        _hasNavigated = true;
        _onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    // Navigate to My Teams screen after animation completes
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            MyTeamsScreen(selectedTeams: widget.allSelectedTeams),
      ),
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

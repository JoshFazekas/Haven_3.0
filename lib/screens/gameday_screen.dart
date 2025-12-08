import 'package:flutter/material.dart';
import 'select_league_screen.dart';

class GamedayScreen extends StatelessWidget {
  const GamedayScreen({super.key});

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
              // Haven Game Day logo
              Transform.scale(
                scale: 0.85,
                child: Image.asset(
                  'assets/images/havengameday1.png',
                ),
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

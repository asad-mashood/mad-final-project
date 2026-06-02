// screens/animation_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'game_screen.dart';

class AnimationScreen extends StatefulWidget {
  final Color courtColor;
  final String courtName;
  final String playerName;
  final int age;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;

  const AnimationScreen({
    super.key,
    required this.courtColor,
    required this.courtName,
    required this.playerName,
    required this.age,
    required this.difficulty,
    this.racket,
    this.shoes,
    this.shirtStyle,
  });

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-navigate to game after animation (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => GameScreen(
                  courtColor: widget.courtColor,
                  courtName: widget.courtName,
                  playerName: widget.playerName,
                  age: widget.age,
                  difficulty: widget.difficulty,
                  racket: widget.racket,
                  shoes: widget.shoes,
                  shirtStyle: widget.shirtStyle,
                ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.courtColor.withValues(alpha: 0.8),
              widget.courtColor,
              widget.courtColor.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/animations/tennisracket.json', // Change to your filename
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 40),

              // Court name text
              Text(
                widget.courtName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(2, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),

              const SizedBox(height: 20),

              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

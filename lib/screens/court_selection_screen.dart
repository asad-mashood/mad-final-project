// screens/court_selection_screen.dart
import 'package:flutter/material.dart';
import 'animation_screen.dart';

class CourtSelectionScreen extends StatelessWidget {
  final String playerName;
  final int age;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;

  const CourtSelectionScreen({
    super.key,
    required this.playerName,
    required this.age,
    required this.difficulty,
    this.racket,
    this.shoes,
    this.shirtStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SELECT YOUR COURT',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Court Options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CourtCard(
                        courtName: 'Wimbledon',
                        location: 'London, England',
                        courtType: 'Grass Court',
                        courtColor: const Color(0xFF2E7D32), // Green
                        icon: Icons.grass,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AnimationScreen(
                                    courtColor: const Color(0xFF2E7D32),
                                    courtName: 'Wimbledon',
                                    playerName: playerName,
                                    age: age,
                                    difficulty: difficulty,
                                    racket: racket,
                                    shoes: shoes,
                                    shirtStyle: shirtStyle,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CourtCard(
                        courtName: 'French Open',
                        location: 'Paris, France',
                        courtType: 'Clay Court',
                        courtColor: const Color(0xFFD84315), // Red clay
                        icon: Icons.sports_tennis,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AnimationScreen(
                                    courtColor: const Color(0xFFD84315),
                                    courtName: 'French Open',
                                    playerName: playerName,
                                    age: age,
                                    difficulty: difficulty,
                                    racket: racket,
                                    shoes: shoes,
                                    shirtStyle: shirtStyle,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CourtCard(
                        courtName: 'Arthur Ashe',
                        location: 'New York, USA',
                        courtType: 'Hard Court',
                        courtColor: const Color(0xFF0D47A1), // Dark blue
                        icon: Icons.stadium,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AnimationScreen(
                                    courtColor: const Color(0xFF0D47A1),
                                    courtName: 'Arthur Ashe',
                                    playerName: playerName,
                                    age: age,
                                    difficulty: difficulty,
                                    racket: racket,
                                    shoes: shoes,
                                    shirtStyle: shirtStyle,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CourtCard(
                        courtName: 'Roland Garros',
                        location: 'Paris, France',
                        courtType: 'Red Clay Court',
                        courtColor: const Color(0xFFBF360C), // Dark red clay
                        icon: Icons.sports,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AnimationScreen(
                                    courtColor: const Color(0xFFBF360C),
                                    courtName: 'Roland Garros',
                                    playerName: playerName,
                                    age: age,
                                    difficulty: difficulty,
                                    racket: racket,
                                    shoes: shoes,
                                    shirtStyle: shirtStyle,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      CourtCard(
                        courtName: 'Australian Open',
                        location: 'Melbourne, Australia',
                        courtType: 'Hard Court',
                        courtColor: const Color(0xFF039BE5), // Light blue
                        icon: Icons.stadium,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AnimationScreen(
                                    courtColor: const Color(0xFF039BE5),
                                    courtName: 'Australian Open',
                                    playerName: playerName,
                                    age: age,
                                    difficulty: difficulty,
                                    racket: racket,
                                    shoes: shoes,
                                    shirtStyle: shirtStyle,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourtCard extends StatelessWidget {
  final String courtName;
  final String location;
  final String courtType;
  final Color courtColor;
  final IconData icon;
  final VoidCallback onTap;

  const CourtCard({
    super.key,
    required this.courtName,
    required this.location,
    required this.courtType,
    required this.courtColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: courtColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Court color indicator (left side)
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: courtColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      courtType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Court information (right side)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      courtName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: courtColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'PLAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

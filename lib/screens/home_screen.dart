// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player_profile.dart';
import '../utils/profile_manager.dart';
import 'court_selection_screen.dart';
import 'player_setup_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlayerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await ProfileManager.instance.loadProfile();
    setState(() {
      _profile = ProfileManager.instance.profile;
      _isLoading = false;
    });
  }

  void _openProfileEditor() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const PlayerSetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    ).then((_) => _loadProfile());
  }

  void _startMatch() {
    final profile =
        _profile ??
        PlayerProfile(
          playerName: 'Guest',
          age: 18,
          difficulty: 'Medium',
          racket: 'Beginner Racket',
          shoes: 'Basic Shoes',
          shirtStyle: 'Classic White',
        );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => CourtSelectionScreen(
              playerName: profile.playerName,
              age: profile.age,
              difficulty: profile.difficulty,
              racket: profile.racket,
              shoes: profile.shoes,
              shirtStyle: profile.shirtStyle,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFF2E7D32),
              const Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: TennisCourtPainter()),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellow.shade600,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'WIMBLEDON',
                      style: TextStyle(
                        fontSize: 48,
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
                    const Text(
                      '2026',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFFFEB3B),
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    else if (_profile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36.0,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Profile: ${_profile!.playerName}, ${_profile!.age} yrs, ${_profile!.difficulty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Racket: ${_profile!.racket}, Shoes: ${_profile!.shoes}, Shirt: ${_profile!.shirtStyle}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 36.0,
                          vertical: 12,
                        ),
                        child: Text(
                          'No saved profile yet. Set up your name, age, equipment and difficulty once, then start matches directly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 30),
                    _MenuButton(
                      label: _profile != null ? 'START MATCH' : 'PLAY GUEST',
                      icon: Icons.play_arrow,
                      onPressed: _startMatch,
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'PROFILE',
                      icon: Icons.person,
                      onPressed: _openProfileEditor,
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'PREVIOUS RESULTS',
                      icon: Icons.emoji_events,
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ResultsScreen(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 800,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _MenuButton(
                      label: 'EXIT',
                      icon: Icons.exit_to_app,
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'reserved right by Muhammad Asad FA23-BAI-039',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFFFFEB3B), width: 3),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TennisCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;

    for (var x = 0.0; x < size.width; x += 60) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 20, size.height), paint);
    }

    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.9,
        height: size.height * 0.9,
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

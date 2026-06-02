// screens/game_screen.dart
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../components/court.dart';
import '../components/ball.dart';
import '../components/net.dart';
import '../components/player.dart';
import '../components/referee_seat.dart';
import '../components/score_display.dart';
import '../components/pause_menu.dart';
import '../components/game_over_screen.dart';
import '../utils/database_helper.dart';
import '../models/game_result.dart';
import 'package:flame_audio/flame_audio.dart';

class GameScreen extends StatefulWidget {
  final Color courtColor;
  final String courtName;
  final String playerName;
  final int age;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;

  const GameScreen({
    super.key,
    this.courtColor = const Color(0xFF2E7D32), // Default green (Wimbledon)
    this.courtName = 'Wimbledon',
    required this.playerName,
    required this.age,
    required this.difficulty,
    this.racket,
    this.shoes,
    this.shirtStyle,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TennisGame game;
  final ValueNotifier<String> _loadStatus = ValueNotifier(
    'Initializing game...',
  );
  Offset? _swipeStart;
  Offset? _swipeCurrent;

  @override
  void initState() {
    super.initState();
    game = TennisGame(
      courtColor: widget.courtColor,
      courtName: widget.courtName,
      onExit: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      playerName: widget.playerName,
      age: widget.age,
      difficulty: widget.difficulty,
      racket: widget.racket,
      shoes: widget.shoes,
      shirtStyle: widget.shirtStyle,
      statusNotifier: _loadStatus,
    );
  }

  @override
  void dispose() {
    game.showShotControls.dispose();
    game.shotPowerLabel.dispose();
    game.selectedShotLabel.dispose();
    _loadStatus.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    game.movePlayerTo(
      Vector2(details.localPosition.dx, details.localPosition.dy),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _swipeStart = details.localPosition;
    _swipeCurrent = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _swipeCurrent = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_swipeStart != null && _swipeCurrent != null) {
      final distance = (_swipeCurrent! - _swipeStart!).distance;
      game.setSwipePower(distance);
    }
    _swipeStart = null;
    _swipeCurrent = null;
  }

  void _handlePanCancel() {
    _swipeStart = null;
    _swipeCurrent = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _handleTapUp,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onPanCancel: _handlePanCancel,
              child: Container(
                color: widget.courtColor.withValues(alpha: 0.4),
                child: SizedBox.expand(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GameWidget(
                          game: game,
                          loadingBuilder:
                              (context) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: ValueListenableBuilder<String>(
                          valueListenable: _loadStatus,
                          builder: (context, status, child) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Shot controls
          Positioned(
            bottom: 40,
            left: 20,
            child: ValueListenableBuilder<bool>(
              valueListenable: game.showShotControls,
              builder: (context, showShotControls, child) {
                if (!showShotControls) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildShotButton(
                          'Normal',
                          Colors.blue,
                          () => game.selectShot('Flat'),
                        ),
                        const SizedBox(width: 8),
                        _buildShotButton(
                          'Slice',
                          Colors.orange,
                          () => game.selectShot('Slice'),
                        ),
                        const SizedBox(width: 8),
                        _buildShotButton(
                          'Lob',
                          Colors.lightBlue,
                          () => game.selectShot('Lob'),
                        ),
                        const SizedBox(width: 8),
                        _buildShotButton(
                          'Power',
                          Colors.redAccent,
                          () => game.selectShot('Power'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: game.shotPowerLabel,
                      builder: (context, powerLabel, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Power: $powerLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Sprint Button (Bottom Right)
          Positioned(
            bottom: 40,
            right: 30,
            child: GestureDetector(
              onPanDown: (_) => game.setSprinting(true),
              onPanCancel: () => game.setSprinting(false),
              onPanEnd: (_) => game.setSprinting(false),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          // Pause button in top-right corner
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => game.togglePause(),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShotButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class TennisGame extends FlameGame with HasCollisionDetection {
  final Color courtColor;
  final String courtName;
  final VoidCallback onExit;
  final String playerName;
  final int age;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;
  final ValueNotifier<String>? statusNotifier;

  // Shot mechanics
  String nextShotType = 'Flat'; // 'Flat', 'Lob', 'Slice', 'Power'
  final ValueNotifier<bool> showShotControls = ValueNotifier(false);
  final ValueNotifier<String> shotPowerLabel = ValueNotifier('Normal');
  final ValueNotifier<String> selectedShotLabel = ValueNotifier('Flat');
  double shotPower = 1.0;

  bool isSprinting = false;

  // Score tracking
  int bottomPlayerScore = 0;
  int topPlayerScore = 0;

  // Game state
  bool isPaused = false;
  bool isGameOver = false;

  // Component references
  late Ball ball;
  late Player topPlayer;
  late Player bottomPlayer;
  late ScoreDisplay scoreDisplay;
  PauseMenu? pauseMenu;
  GameOverScreen? gameOverScreen;

  TennisGame({
    required this.courtColor,
    required this.courtName,
    required this.onExit,
    required this.playerName,
    required this.age,
    required this.difficulty,
    this.racket,
    this.shoes,
    this.shirtStyle,
    this.statusNotifier,
  });

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    statusNotifier?.value = 'Loading game...';
    await super.onLoad();

    // Add court background (bottom layer)
    add(Court(color: courtColor));

    // Add referee seat
    add(RefereeSeat());

    // Add net in the middle
    add(Net());

    // Add players
    bottomPlayer = Player(
      isBottom: true,
      difficulty: difficulty,
      racket: racket,
      shoes: shoes,
    );
    topPlayer = Player(
      isBottom: false,
      difficulty: difficulty,
      racket: racket,
      shoes: shoes,
    );
    add(bottomPlayer);
    add(topPlayer);

    // Add score display
    scoreDisplay = ScoreDisplay();
    add(scoreDisplay);

    // Add ball LAST (top layer - most visible)
    ball = Ball();
    add(ball);

    statusNotifier?.value = 'Game loaded';
    debugPrint('$courtName court loaded!');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Skip AI logic if paused or game over
    if (isPaused || isGameOver) return;

    // AI logic - make top player follow the ball with smooth movement
    topPlayer.moveTowardsBall(ball.position, dt);

    final shouldShowShots =
        ball.position.y > size.y * 0.35 && ball.velocity.y > 0;
    if (showShotControls.value != shouldShowShots) {
      showShotControls.value = shouldShowShots;
    }
  }

  // KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  //   if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
  //     if (!isGameOver) {
  //       togglePause();
  //     }
  //     return KeyEventResult.handled;
  //   }
  //   return KeyEventResult.ignored;
  // }
  // Toggle pause state
  void togglePause() {
    if (isGameOver) return; // Can't pause when game over

    isPaused = !isPaused;

    if (isPaused) {
      pauseMenu = PauseMenu();
      add(pauseMenu!);
    } else {
      if (pauseMenu != null) {
        remove(pauseMenu!);
        pauseMenu = null;
      }
    }
    //
    // debugPrint('Game ${isPaused ? 'paused' : 'resumed'}');
  }

  void setSprinting(bool sprinting) {
    isSprinting = sprinting;
  }

  void selectShot(String shot) {
    nextShotType = shot;
    selectedShotLabel.value = shot;
  }

  void setSwipePower(double distance) {
    if (distance < 80) {
      shotPower = 0.9;
      shotPowerLabel.value = 'Weak';
    } else if (distance < 180) {
      shotPower = 1.0;
      shotPowerLabel.value = 'Normal';
    } else if (distance < 280) {
      shotPower = 1.2;
      shotPowerLabel.value = 'Strong';
    } else {
      shotPower = 1.4;
      shotPowerLabel.value = 'Power';
    }
  }

  void movePlayerTo(Vector2 rawPosition) {
    if (size.x > 80 && size.y > 80) {
      final targetX = rawPosition.x.clamp(40.0, size.x - 40.0);
      final targetY = rawPosition.y.clamp(size.y / 2 + 20.0, size.y - 20.0);
      bottomPlayer.setTarget(Vector2(targetX, targetY));
    }
  }

  // Check if game is over (someone won)
  void checkGameOver() {
    bool playerWon = false;
    bool aiWon = false;

    // Win condition: 4+ points with 2+ point lead
    if (bottomPlayerScore >= 4 && bottomPlayerScore - topPlayerScore >= 2) {
      playerWon = true;
    }
    if (topPlayerScore >= 4 && topPlayerScore - bottomPlayerScore >= 2) {
      aiWon = true;
    }

    if (playerWon || aiWon) {
      showGameOverScreen(playerWon);
    }
  }

  // Show game over screen and save to database
  void showGameOverScreen(bool playerWon) {
    isGameOver = true;
    isPaused = true; // Stop the game

    // Save result to database
    _saveGameResult(playerWon);

    // Show game over overlay
    gameOverScreen = GameOverScreen(
      playerWon: playerWon,
      playerScore: bottomPlayerScore,
      aiScore: topPlayerScore,
      playerName: playerName,
    );
    add(gameOverScreen!);
    //
    // debugPrint('Game Over! ${playerWon ? 'Player' : 'AI'} wins!');
  }

  // Save game result to SQLite database
  Future<void> _saveGameResult(bool playerWon) async {
    final result = GameResult(
      playerScore: bottomPlayerScore,
      aiScore: topPlayerScore,
      result: playerWon ? 'WIN' : 'LOSS',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      courtName: courtName,
      playerName: playerName,
      difficulty: difficulty,
    );

    await DatabaseHelper.instance.insertGameResult(result);
    debugPrint('Game result saved to database');
  }

  // Play again - reset everything
  void playAgain() {
    bottomPlayerScore = 0;
    topPlayerScore = 0;
    isGameOver = false;
    isPaused = false;
    ball.resetBall();

    // Remove game over screen
    if (gameOverScreen != null) {
      remove(gameOverScreen!);
      gameOverScreen = null;
    }

    debugPrint('Starting new game!');
  }

  // Restart the game (from pause menu)
  void restartGame() {
    bottomPlayerScore = 0;
    topPlayerScore = 0;
    ball.resetBall();

    // Unpause and remove menu
    if (isPaused) {
      isPaused = false;
      if (pauseMenu != null) {
        remove(pauseMenu!);
        pauseMenu = null;
      }
    }

    debugPrint('Game restarted!');
  }

  // Exit to home screen
  void exitGame() {
    onExit();
  }

  // Helper methods to play sound safely
  void playSound(String filename) {
    try {
      FlameAudio.play(filename);
    } catch (e) {
      // Ignore missing audio files since user needs to add them
    }
  }

  // Announce score when point is scored
  void announceScore(bool playerScored) {
    playSound('score.mp3');
    scoreDisplay.announceScore();
  }
}

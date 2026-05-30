// screens/game_screen.dart
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

class GameScreen extends StatelessWidget {
  final Color courtColor;
  final String courtName;

  const GameScreen({
    super.key,
    this.courtColor = const Color(0xFF2E7D32), // Default green (Wimbledon)
    this.courtName = 'Wimbledon',
  });

  @override
  Widget build(BuildContext context) {
    final game = TennisGame(
      courtColor: courtColor,
      courtName: courtName,
      context: context,
    );
    
    return Scaffold(
      body: Stack(
        children: [
          // Wrap in GestureDetector for paddle control
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              game.bottomPlayer.handleDrag(details.delta.dx);
            },
            child: GameWidget(
              game: game,
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TennisGame extends FlameGame with HasCollisionDetection {
  final Color courtColor;
  final String courtName;
  final BuildContext context;

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
    required this.context,
  });

  @override
  Future<void> onLoad() async {
    // Add court background (bottom layer)
    add(Court(color: courtColor));

    // Add referee seat
    add(RefereeSeat());

    // Add net in the middle
    add(Net());

    // Add players
    bottomPlayer = Player(isBottom: true);
    topPlayer = Player(isBottom: false);
    add(bottomPlayer);
    add(topPlayer);

    // Add score display
    scoreDisplay = ScoreDisplay();
    add(scoreDisplay);

    // Add ball LAST (top layer - most visible)
    ball = Ball();
    add(ball);

    debugPrint('$courtName court loaded!');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Skip AI logic if paused or game over
    if (isPaused || isGameOver) return;

    // AI logic - make top player follow the ball with smooth movement
    topPlayer.moveTowardsBall(ball.position, dt);
  }

  @override
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
    Navigator.of(context).pop();
  }

  // Announce score when point is scored
  void announceScore(bool playerScored) {
    scoreDisplay.announceScore();
  }
}


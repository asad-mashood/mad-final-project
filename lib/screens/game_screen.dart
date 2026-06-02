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
    this.courtColor = const Color(0xFF2E7D32),
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
  Offset? _swipeStart;
  Offset? _swipeCurrent;

  @override
  void initState() {
    super.initState();
    game = TennisGame(
      courtColor: widget.courtColor,
      courtName: widget.courtName,
      playerName: widget.playerName,
      age: widget.age,
      difficulty: widget.difficulty,
      racket: widget.racket,
      shoes: widget.shoes,
      shirtStyle: widget.shirtStyle,
      onExit: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    game.showShotControls.dispose();
    game.shotPowerLabel.dispose();
    game.selectedShotLabel.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // INPUT  –  KEY FIX:
  //
  // The old code had BOTH onTapUp AND onPanStart.
  // Flutter's gesture arena forces them to compete —
  // it picks one and drops the other, so taps
  // randomly fail to move the player.
  //
  // Fix: remove onTapUp entirely.
  // A tap IS a pan with zero distance.
  // onPanStart fires on every finger-down, even a tap.
  // We call directMovePlayer on BOTH start and update
  // so the player follows your finger in real-time.
  // ─────────────────────────────────────────────────

  void _handleTapDown(TapDownDetails d) {
    game.directMovePlayer(d.localPosition.dx, d.localPosition.dy);
  }

  void _handlePanStart(DragStartDetails d) {
    _swipeStart = d.localPosition;
    _swipeCurrent = d.localPosition;
    // Immediate response on finger-down (works for taps too)
    game.directMovePlayer(d.localPosition.dx, d.localPosition.dy);
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    _swipeCurrent = d.localPosition;
    // Real-time finger tracking while dragging
    game.directMovePlayer(d.localPosition.dx, d.localPosition.dy);
  }

  void _handlePanEnd(DragEndDetails _) {
    if (_swipeStart != null && _swipeCurrent != null) {
      final dist = (_swipeCurrent! - _swipeStart!).distance;
      // Only set shot power if it was a real swipe (not just a tap)
      if (dist > 35) game.setSwipePower(dist);
    }
    _swipeStart = _swipeCurrent = null;
  }

  void _handlePanCancel() => _swipeStart = _swipeCurrent = null;

  Widget _shotBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
        child: Stack(
          children: [
            // 1. Game canvas fills screen
            Positioned.fill(
              child: GameWidget(
                game: game,
                loadingBuilder: (ctx) => Container(
                  color: widget.courtColor,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading court...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Shot-type buttons — bottom-left
            Positioned(
              bottom: 44,
              left: 16,
              child: ValueListenableBuilder<bool>(
                valueListenable: game.showShotControls,
                builder: (ctx, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _shotBtn('Flat', Colors.blue,
                              () => game.selectShot('Flat')),
                          const SizedBox(width: 8),
                          _shotBtn('Slice', Colors.orange,
                              () => game.selectShot('Slice')),
                          const SizedBox(width: 8),
                          _shotBtn('Lob', Colors.lightBlue,
                              () => game.selectShot('Lob')),
                          const SizedBox(width: 8),
                          _shotBtn('Power', Colors.redAccent,
                              () => game.selectShot('Power')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<String>(
                        valueListenable: game.shotPowerLabel,
                        builder: (ctx2, pwr, _) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt,
                                  color: Colors.yellowAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Power: $pwr',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Sprint button — bottom-right
            Positioned(
              bottom: 44,
              right: 24,
              child: GestureDetector(
                onPanDown: (_) => game.setSprinting(true),
                onPanCancel: () => game.setSprinting(false),
                onPanEnd: (_) => game.setSprinting(false),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 28),
                      Text(
                        'SPRINT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Pause button — top-right
            Positioned(
              top: 44,
              right: 16,
              child: GestureDetector(
                onTap: () => game.togglePause(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.pause,
                      color: Colors.white, size: 28),
                ),
              ),
            ),

            // 5. Current shot indicator — top-left
            Positioned(
              top: 44,
              left: 16,
              child: ValueListenableBuilder<String>(
                valueListenable: game.selectedShotLabel,
                builder: (ctx, shot, _) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_tennis,
                          color: Colors.yellowAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        shot,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Flame Game
// ─────────────────────────────────────────────────────────
class TennisGame extends FlameGame with HasCollisionDetection {
  final Color courtColor;
  final String courtName;
  final String playerName;
  final int age;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;
  final VoidCallback? onExit;

  String nextShotType = 'Flat';
  final ValueNotifier<bool> showShotControls = ValueNotifier(false);
  final ValueNotifier<String> shotPowerLabel = ValueNotifier('Normal');
  final ValueNotifier<String> selectedShotLabel = ValueNotifier('Flat');
  double shotPower = 1.0;

  bool isSprinting = false;

  int bottomPlayerScore = 0;
  int topPlayerScore = 0;

  bool isPaused = false;
  bool isGameOver = false;

  Ball? _ball;
  Player? _topPlayer;
  Player? _bottomPlayer;
  ScoreDisplay? _scoreDisplay;
  PauseMenu? _pauseMenu;
  GameOverScreen? _gameOverScreen;

  Ball get ball => _ball!;
  Player get topPlayer => _topPlayer!;
  Player get bottomPlayer => _bottomPlayer!;
  ScoreDisplay get scoreDisplay => _scoreDisplay!;

  bool _loaded = false;

  TennisGame({
    required this.courtColor,
    required this.courtName,
    required this.playerName,
    required this.age,
    required this.difficulty,
    this.racket,
    this.shoes,
    this.shirtStyle,
    this.onExit,
  });

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Court(color: courtColor));
    add(RefereeSeat());
    add(Net());
    _bottomPlayer = Player(
      isBottom: true,
      difficulty: difficulty,
      racket: racket,
      shoes: shoes,
      shirtStyle: shirtStyle,
      age: age,
    );
    _topPlayer = Player(
      isBottom: false,
      difficulty: difficulty,
      racket: racket,
      shoes: shoes,
      shirtStyle: shirtStyle,
      age: age,
    );
    add(_bottomPlayer!);
    add(_topPlayer!);
    _scoreDisplay = ScoreDisplay();
    add(_scoreDisplay!);
    _ball = Ball();
    add(_ball!);
    _loaded = true;
    debugPrint('$courtName TennisGame loaded ✓');
  }

  @override
  void update(double dt) {
    if (!_loaded) return;
    super.update(dt);
    if (isPaused || isGameOver) return;
    _topPlayer?.moveTowardsBall(_ball!.position, dt);
    final shouldShow = _ball != null &&
        _ball!.position.y > size.y * 0.4 &&
        _ball!.velocity.y > 0;
    if (showShotControls.value != shouldShow) {
      showShotControls.value = shouldShow;
    }
  }

  // Direct finger-tracking movement — called on every pan event
  void directMovePlayer(double fingerX, double fingerY) {
    if (isPaused || isGameOver) return;
    if (_bottomPlayer == null || size.x <= 80 || size.y <= 80) return;
    _bottomPlayer!.setDirectTarget(fingerX, fingerY, size);
  }

  void movePlayerTo(Vector2 rawPos) =>
      directMovePlayer(rawPos.x, rawPos.y);

  void togglePause() {
    if (isGameOver) return;
    isPaused = !isPaused;
    if (isPaused) {
      _pauseMenu = PauseMenu();
      add(_pauseMenu!);
    } else {
      if (_pauseMenu != null) {
        remove(_pauseMenu!);
        _pauseMenu = null;
      }
    }
  }

  void setSprinting(bool s) => isSprinting = s;

  void selectShot(String shot) {
    nextShotType = shot;
    selectedShotLabel.value = shot;
  }

  void setSwipePower(double distance) {
    if (distance < 60) {
      shotPower = 0.85;
      shotPowerLabel.value = 'Weak';
    } else if (distance < 150) {
      shotPower = 1.0;
      shotPowerLabel.value = 'Normal';
    } else if (distance < 260) {
      shotPower = 1.2;
      shotPowerLabel.value = 'Strong';
    } else {
      shotPower = 1.5;
      shotPowerLabel.value = 'Power!';
    }
  }

  void checkGameOver() {
    bool playerWon = false;
    bool aiWon = false;
    if (bottomPlayerScore >= 4 && bottomPlayerScore - topPlayerScore >= 2) {
      playerWon = true;
    }
    if (topPlayerScore >= 4 && topPlayerScore - bottomPlayerScore >= 2) {
      aiWon = true;
    }
    if (playerWon || aiWon) showGameOverScreen(playerWon);
  }

  void showGameOverScreen(bool playerWon) {
    isGameOver = true;
    isPaused = true;
    _saveGameResult(playerWon);
    _gameOverScreen = GameOverScreen(
      playerWon: playerWon,
      playerScore: bottomPlayerScore,
      aiScore: topPlayerScore,
      playerName: playerName,
    );
    add(_gameOverScreen!);
  }

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
  }

  void playAgain() {
    bottomPlayerScore = 0;
    topPlayerScore = 0;
    isGameOver = false;
    isPaused = false;
    _bottomPlayer?.resetPlayer();
    _topPlayer?.resetPlayer();
    _ball?.resetBall();
    if (_gameOverScreen != null) {
      remove(_gameOverScreen!);
      _gameOverScreen = null;
    }
  }

  void restartGame() {
    bottomPlayerScore = 0;
    topPlayerScore = 0;
    _bottomPlayer?.resetPlayer();
    _topPlayer?.resetPlayer();
    _ball?.resetBall();
    if (isPaused) {
      isPaused = false;
      if (_pauseMenu != null) {
        remove(_pauseMenu!);
        _pauseMenu = null;
      }
    }
  }

  void exitGame() => onExit?.call();

  void playSound(String filename) {
    try {
      FlameAudio.play(filename);
    } catch (_) {}
  }

  void announceScore(bool playerScored) {
    playSound('score.mp3');
    _scoreDisplay?.announceScore();
  }
}

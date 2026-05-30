// components/ball.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';
import 'player.dart';

class Ball extends CircleComponent with HasGameRef<TennisGame>, CollisionCallbacks {
  Vector2 velocity = Vector2(150, -300);

  Ball()
      : super(
    radius: 15,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set ball color
    paint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;

    // Position ball in center
    position = gameRef.size / 2;

    // Add collision detection
    add(CircleHitbox());

    debugPrint('Ball loaded at: $position with radius: $radius');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't move if game is paused or game over
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Store previous position for collision detection
    final previousY = position.y;
    
    // Move ball
    position += velocity * dt;

    // Bounce off left and right walls
    if (position.x - radius <= 0 || position.x + radius >= gameRef.size.x) {
      velocity.x = -velocity.x;
      position.x = position.x.clamp(radius, gameRef.size.x - radius);
    }

    // Continuous collision detection for paddles (prevents tunneling)
    // Check bottom player paddle
    final bottomPaddle = gameRef.bottomPlayer;
    final bottomPaddleTop = bottomPaddle.position.y - bottomPaddle.size.y / 2;
    final bottomPaddleLeft = bottomPaddle.position.x - bottomPaddle.size.x / 2;
    final bottomPaddleRight = bottomPaddle.position.x + bottomPaddle.size.x / 2;
    
    // If ball crossed the paddle's y-line this frame (moving down)
    if (velocity.y > 0 && previousY + radius < bottomPaddleTop && position.y + radius >= bottomPaddleTop) {
      // Check if ball is within paddle's x range
      if (position.x >= bottomPaddleLeft - radius && position.x <= bottomPaddleRight + radius) {
        // Collision detected - bounce!
        velocity.y = -velocity.y.abs(); // Ensure it goes up
        position.y = bottomPaddleTop - radius - 2;
        
        // Add spin based on hit position
        final hitPosition = position.x - bottomPaddle.position.x;
        velocity.x += hitPosition * 3;
        velocity.x = velocity.x.clamp(-400.0, 400.0);
      }
    }

    // Check top player paddle
    final topPaddle = gameRef.topPlayer;
    final topPaddleBottom = topPaddle.position.y + topPaddle.size.y / 2;
    final topPaddleLeft = topPaddle.position.x - topPaddle.size.x / 2;
    final topPaddleRight = topPaddle.position.x + topPaddle.size.x / 2;
    
    // If ball crossed the paddle's y-line this frame (moving up)
    if (velocity.y < 0 && previousY - radius > topPaddleBottom && position.y - radius <= topPaddleBottom) {
      // Check if ball is within paddle's x range
      if (position.x >= topPaddleLeft - radius && position.x <= topPaddleRight + radius) {
        // Collision detected - bounce!
        velocity.y = velocity.y.abs(); // Ensure it goes down
        position.y = topPaddleBottom + radius + 2;
        
        // Add spin based on hit position
        final hitPosition = position.x - topPaddle.position.x;
        velocity.x += hitPosition * 3;
        velocity.x = velocity.x.clamp(-400.0, 400.0);
      }
    }

    // Check if ball went out of bounds (scoring)
    if (position.y - radius <= 0) {
      gameRef.bottomPlayerScore++;
      gameRef.announceScore(true); // Player scored
      debugPrint('Player scored! Score: ${gameRef.bottomPlayerScore} - ${gameRef.topPlayerScore}');
      gameRef.checkGameOver(); // Check if game is over
      if (!gameRef.isGameOver) {
        resetBall();
      }
    }

    if (position.y + radius >= gameRef.size.y) {
      gameRef.topPlayerScore++;
      gameRef.announceScore(false); // AI scored
      debugPrint('AI scored! Score: ${gameRef.topPlayerScore} - ${gameRef.bottomPlayerScore}');
      gameRef.checkGameOver(); // Check if game is over
      if (!gameRef.isGameOver) {
        resetBall();
      }
    }
  }

  void resetBall() {
    position = gameRef.size / 2;
    velocity = Vector2(
      (velocity.x > 0 ? 1 : -1) * 150,
      (velocity.y > 0 ? 1 : -1) * 300,
    );
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      velocity.y = -velocity.y;

      final paddleCenter = other.position.x;
      final hitPosition = position.x - paddleCenter;
      velocity.x += hitPosition * 3;

      velocity.x = velocity.x.clamp(-400, 400);

      if (other.isBottom) {
        position.y = other.position.y - other.size.y / 2 - radius - 2;
      } else {
        position.y = other.position.y + other.size.y / 2 + radius + 2;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Add tennis ball white curves on top
    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
  }
}
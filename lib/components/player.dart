// components/player.dart
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../screens/game_screen.dart';

class Player extends PositionComponent with HasGameRef<TennisGame>, CollisionCallbacks {
  final bool isBottom; // true = bottom player (you), false = top player (AI)

  Player({required this.isBottom});

  @override
  Future<void> onLoad() async {
    size = Vector2(80, 20); // Paddle size (racket)
    anchor = Anchor.center;

    // Add collision detection hitbox
    add(RectangleHitbox());

    // Position players
    if (isBottom) {
      position = Vector2(gameRef.size.x / 2, gameRef.size.y - 60);
    } else {
      position = Vector2(gameRef.size.x / 2, 60);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw paddle/racket
    final paint = Paint()
      ..color = isBottom ? const Color(0xFF2196F3) : const Color(0xFFF44336) // Blue vs Red
      ..style = PaintingStyle.fill;

    // Draw rounded rectangle for paddle
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);

    // Draw grip/handle
    final handlePaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, isBottom ? size.y / 2 + 5 : -size.y / 2 - 5),
        width: 15,
        height: 10,
      ),
      handlePaint,
    );
  }

  // Called from game screen when user drags on screen
  void handleDrag(double deltaX) {
    if (!isBottom) return;
    if (gameRef.isPaused || gameRef.isGameOver) return;

    position.x += deltaX;

    // Keep paddle within bounds - paddle center can go from half-width to screen-width minus half-width
    // This ensures the paddle stays fully visible on screen
    final halfWidth = size.x / 2;
    final screenWidth = gameRef.size.x;
    position.x = position.x.clamp(halfWidth, screenWidth - halfWidth);
  }

  // Improved AI for top player
  void moveTowardsBall(Vector2 ballPosition, double dt) {
    if (!isBottom) {
      final distanceToBall = ballPosition.x - position.x;
      final aiSpeed = 200.0; // AI movement speed

      // Only move if ball is in top half of court (coming towards AI)
      if (ballPosition.y < gameRef.size.y / 2) {
        // Move towards ball's x position with smooth movement
        if (distanceToBall.abs() > 5) {
          if (distanceToBall > 0) {
            position.x += aiSpeed * dt;
          } else {
            position.x -= aiSpeed * dt;
          }
        }
      } else {
        // When ball is in bottom half, return to center
        final centerX = gameRef.size.x / 2;
        final distanceToCenter = centerX - position.x;

        if (distanceToCenter.abs() > 5) {
          if (distanceToCenter > 0) {
            position.x += aiSpeed * 0.5 * dt; // Slower return to center
          } else {
            position.x -= aiSpeed * 0.5 * dt;
          }
        }
      }

      // Keep within bounds (same as player)
      final halfWidth = size.x / 2;
      final screenWidth = gameRef.size.x;
      position.x = position.x.clamp(halfWidth, screenWidth - halfWidth);
    }
  }
}

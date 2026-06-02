// components/player.dart
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../screens/game_screen.dart';

class PlayerStats {
  double agility = 250.0;
  double maxStamina = 100.0;
  double power = 1.0;
}

class Player extends PositionComponent
    with HasGameReference<TennisGame>, CollisionCallbacks {
  final bool isBottom; // true = bottom player (you), false = top player (AI)
  final String difficulty;
  final String? racket;
  final String? shoes;

  late final PlayerStats stats;
  late double stamina;
  Vector2? targetPosition;

  Player({
    required this.isBottom,
    this.difficulty = 'Medium',
    this.racket,
    this.shoes,
  }) {
    stats = PlayerStats();

    // Apply equipment modifiers
    if (racket == 'Power Racket') {
      stats.power = 1.3;
    } else if (racket == 'Control Racket') {
      stats.power = 0.9;
    }

    if (shoes == 'Sprint Shoes') {
      stats.agility = 320.0;
      stats.maxStamina = 80.0;
    } else if (shoes == 'Endurance Shoes') {
      stats.agility = 220.0;
      stats.maxStamina = 130.0;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(80, 20); // Paddle size (racket)
    anchor = Anchor.center;

    // Add collision detection hitbox
    add(RectangleHitbox());

    stamina = stats.maxStamina;

    // Position players if the game already has size available
    if (game.size.x > 0 && game.size.y > 0) {
      _reposition(game.size);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _reposition(size);
  }

  void _reposition(Vector2 size) {
    if (isBottom) {
      position = Vector2(size.x / 2, size.y - 60);
    } else {
      position = Vector2(size.x / 2, 60);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw character holding the paddle/racket
    final mainColor =
        isBottom
            ? const Color(0xFF2196F3)
            : const Color(0xFFF44336); // Blue vs Red
    final skinColor = const Color(0xFFFFCCAA);
    final shoeColor = const Color(0xFFECEFF1);
    final racketFrameColor = const Color(0xFF424242);
    final racketStringsColor = const Color(0x80FFFFFF);

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Head
    paint.color = skinColor;
    canvas.drawCircle(Offset(0, isBottom ? 10 : -10), 12, paint);

    // Body (Shirt)
    paint.color = mainColor;
    final bodyRect = Rect.fromCenter(
      center: Offset(0, isBottom ? 25 : -25),
      width: 24,
      height: 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      paint,
    );

    // Arms
    paint.color = skinColor;
    // Left arm
    canvas.drawCircle(Offset(-16, isBottom ? 25 : -25), 5, paint);
    // Right arm holding racket
    canvas.drawCircle(Offset(16, isBottom ? 25 : -25), 5, paint);

    // Legs & Shoes
    paint.color = shoeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-8, isBottom ? 40 : -40),
          width: 10,
          height: 12,
        ),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(8, isBottom ? 40 : -40),
          width: 10,
          height: 12,
        ),
        const Radius.circular(3),
      ),
      paint,
    );

    // Racket Handle
    paint.color = racketFrameColor;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(20, isBottom ? 15 : -15),
        width: 6,
        height: 20,
      ),
      paint,
    );

    // Racket Head
    final racketHeadCenter = Offset(20, isBottom ? -5 : 5);
    strokePaint.color = racketFrameColor;
    strokePaint.strokeWidth = 3.0;
    canvas.drawOval(
      Rect.fromCenter(center: racketHeadCenter, width: 20, height: 26),
      strokePaint,
    );

    // Racket Strings
    paint.color = racketStringsColor;
    canvas.drawOval(
      Rect.fromCenter(center: racketHeadCenter, width: 18, height: 24),
      paint,
    );

    // Timing zone around bottom player
    if (isBottom) {
      final ballPos = _safeBallPosition();
      if (ballPos != null) {
        final distanceToBall = ballPos.distanceTo(position);
        if (distanceToBall < 140) {
          final zoneColor =
              distanceToBall < 60
                  ? Colors.green
                  : distanceToBall < 100
                  ? Colors.yellow
                  : Colors.red;
          final ringPaint =
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..color = zoneColor.withValues(alpha: 0.65);
          canvas.drawCircle(Offset.zero, 70, ringPaint);
        }
      }
    }

    // Draw Stamina Bar (Only for bottom player)
    if (isBottom) {
      final barWidth = 40.0;
      final barHeight = 4.0;
      final barY = 55.0; // Below shoes

      // Background (Empty stamina)
      paint.color = Colors.red.withValues(alpha: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, barY),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      // Foreground (Current stamina)
      final currentStaminaWidth = (stamina / stats.maxStamina) * barWidth;
      paint.color = Colors.greenAccent;
      // Draw left-aligned
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            -barWidth / 2,
            barY - barHeight / 2,
            currentStaminaWidth,
            barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver) return;
    if (game.size.x <= 100 || game.size.y <= 100) return;

    if (isBottom) {
      // Tap-to-move target movement
      if (targetPosition != null) {
        final direction = targetPosition! - position;
        final distance = direction.length;
        if (distance < 8.0) {
          position = targetPosition!;
          targetPosition = null;
        } else {
          double currentSpeed = stats.agility;
          if (game.isSprinting && stamina > 0) {
            currentSpeed *= 1.5;
            stamina -= 20 * dt; // Drain stamina
          } else if (stamina < stats.maxStamina) {
            stamina += 10 * dt; // Recover stamina slowly
          }

          if (stamina <= 0) {
            currentSpeed *= 0.6;
            stamina = 0;
          }

          position += direction.normalized() * currentSpeed * dt;
        }
      } else {
        // Recover stamina when standing still
        if (stamina < stats.maxStamina) {
          stamina += 15 * dt;
        }
      }

      stamina = stamina.clamp(0.0, stats.maxStamina);

      // Keep paddle within bounds (X and Y)
      final halfWidth = size.x / 2;
      final halfHeight = size.y / 2;
      final screenWidth = game.size.x;
      final screenHeight = game.size.y;

      if (screenWidth > size.x && screenHeight > size.y) {
        position.x = position.x.clamp(halfWidth, screenWidth - halfWidth);
        // Limit Y movement to the bottom half of the court
        position.y = position.y.clamp(
          screenHeight / 2 + halfHeight,
          screenHeight - halfHeight,
        );
      }
    }
  }

  void setTarget(Vector2 target) {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;
    if (game.size.x > size.x && game.size.y > size.y) {
      targetPosition = Vector2(
        target.x.clamp(halfWidth, game.size.x - halfWidth),
        target.y.clamp(game.size.y / 2 + halfHeight, game.size.y - halfHeight),
      );
    } else {
      targetPosition = target;
    }
  }

  // Improved AI for top player
  void moveTowardsBall(Vector2 ballPosition, double dt) {
    if (!isBottom) {
      final distanceToBall = ballPosition.x - position.x;

      double aiSpeed = 200.0;
      double reactionThreshold = 5.0;

      if (difficulty == 'Easy') {
        aiSpeed = 120.0;
        reactionThreshold = 20.0; // Slower reaction
      } else if (difficulty == 'Hard') {
        aiSpeed = 450.0; // Very fast
        reactionThreshold = 2.0; // Precise
      }

      // Only move if ball is in top half of court (coming towards AI)
      if (ballPosition.y < game.size.y / 2) {
        // Move towards ball's x position with smooth movement
        if (distanceToBall.abs() > reactionThreshold) {
          if (distanceToBall > 0) {
            position.x += aiSpeed * dt;
          } else {
            position.x -= aiSpeed * dt;
          }
        }
      } else {
        // When ball is in bottom half, return to center
        final centerX = game.size.x / 2;
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
      final screenWidth = game.size.x;
      position.x = position.x.clamp(halfWidth, screenWidth - halfWidth);
    }
  }

  Vector2? _safeBallPosition() {
    try {
      return game.ball.position;
    } catch (_) {
      return null;
    }
  }
}

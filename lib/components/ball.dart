// components/ball.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';
import 'player.dart';

class Ball extends CircleComponent
    with HasGameReference<TennisGame>, CollisionCallbacks {
  Vector2 velocity = Vector2(120, -240);

  // 3D physics simulation
  double z = 50.0; // Height from ground
  double zVelocity = 0.0;
  final double gravity = -800.0;

  // Court modifiers
  double bounceFactor = 0.7;
  double speedModifier = 1.0;

  Ball() : super(radius: 10, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set court modifiers
    if (game.courtName == 'Grass Court' || game.courtName == 'Wimbledon') {
      bounceFactor = 0.5; // Low bounce
      speedModifier = 1.0; // Moderate speed
    } else if (game.courtName == 'Clay Court' ||
        game.courtName == 'Roland Garros' ||
        game.courtName == 'French Open') {
      bounceFactor = 0.85; // High bounce
      speedModifier = 0.8; // Slower speed
    } else {
      // Hard court
      bounceFactor = 0.7;
      speedModifier = 0.95; // Slightly slower hard court speed
    }

    paint =
        Paint()
          ..color = const Color(0xFFFFEB3B)
          ..style = PaintingStyle.fill;
    position = game.size / 2;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver) return;

    // XY Movement
    position += velocity * speedModifier * dt;

    // Z Movement (Gravity and Bounce)
    zVelocity += gravity * dt;
    z += zVelocity * dt;

    if (z <= 0) {
      z = 0;
      zVelocity = -zVelocity * bounceFactor;
    }

    // Visual Scaling based on Z height (higher = bigger)
    scale = Vector2.all(1.0 + (z / 200.0));

    // Bounce off left and right walls
    if (position.x - radius <= 0 || position.x + radius >= game.size.x) {
      velocity.x = -velocity.x;
      position.x = position.x.clamp(radius, game.size.x - radius);
    }

    // Scoring
    if (position.y - radius <= 0) {
      game.bottomPlayerScore++;
      game.announceScore(true);
      game.checkGameOver();
      if (!game.isGameOver) resetBall();
    }
    if (position.y + radius >= game.size.y) {
      game.topPlayerScore++;
      game.announceScore(false);
      game.checkGameOver();
      if (!game.isGameOver) resetBall();
    }
  }

  void resetBall() {
    position = game.size / 2;
    z = 100.0; // Start high for a "serve" drop
    zVelocity = 200.0;
    velocity = Vector2(
      (velocity.x > 0 ? 1 : -1) * 120,
      (velocity.y > 0 ? 1 : -1) * 240,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      // If ball is too high, player misses it
      if (z > 100) return; // Too high to hit

      final hitDirection = other.isBottom ? -1 : 1;

      // Play hit sound safely
      try {
        game.playSound('hit.mp3');
      } catch (e) {
        // Ignore missing or playback errors.
      }

      // Calculate power based on player stamina/sprint/stats and swipe power
      double powerMultiplier = other.stats.power * game.shotPower;
      if (other.stamina > 20 && other.game.isSprinting && other.isBottom) {
        powerMultiplier *= 1.2; // Extra power when sprinting
      } else if (other.stamina < 10) {
        powerMultiplier *= 0.8; // Weak shot when exhausted
      }

      // Timing assist from player zone
      final hitDistance = game.ball.position.distanceTo(other.position);
      if (other.isBottom) {
        if (hitDistance < 60) {
          powerMultiplier *= 1.15;
        } else if (hitDistance < 100) {
          powerMultiplier *= 1.05;
        }
      }

      // Add spin based on hit position
      final hitPosition = position.x - other.position.x;
      velocity.x += hitPosition * 2.0;
      velocity.x += (game.size.x / 2 - position.x) * 0.01; // small aim assist
      velocity.x = velocity.x.clamp(-350.0, 350.0);

      // Shot Types (Only bottom player selects shots manually)
      String shotType = 'Flat';
      if (other.isBottom) {
        shotType = game.nextShotType;
        game.nextShotType = 'Flat'; // Reset after hit
        game.shotPower = 1.0;
        game.shotPowerLabel.value = 'Normal';
      }

      switch (shotType) {
        case 'Lob':
          velocity.y = hitDirection * 220.0 * powerMultiplier;
          zVelocity = 600.0; // High arc
          bounceFactor = 0.75;
          break;
        case 'Slice':
          velocity.y = hitDirection * 260.0 * powerMultiplier;
          zVelocity = 140.0; // Low arc
          bounceFactor = 0.35; // Barely bounces
          break;
        case 'Power':
          velocity.y = hitDirection * 460.0 * powerMultiplier;
          zVelocity = 280.0; // hard drive
          bounceFactor = 0.9;
          break;
        case 'Flat':
        default:
          velocity.y = hitDirection * 320.0 * powerMultiplier;
          zVelocity = 330.0; // Normal arc
          bounceFactor = 0.7;
          break;
      }

      velocity.y = velocity.y.clamp(-600.0, 600.0);

      if (other.isBottom) {
        position.y = other.position.y - other.size.y / 2 - radius - 2;
      } else {
        position.y = other.position.y + other.size.y / 2 + radius + 2;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw shadow
    if (z > 0) {
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
      final shadowOffset = Offset(
        z * 0.2,
        z * 0.5,
      ); // Offset shadow based on height
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowOffset,
          width: radius * 2,
          height: radius * 1.5,
        ),
        shadowPaint,
      );
    }

    super.render(canvas);

    final linePaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Simple tennis ball curves
    canvas.drawArc(
      Rect.fromLTWH(-radius, -radius / 2, radius * 1.5, radius * 1.5),
      0,
      1.5,
      false,
      linePaint,
    );
  }
}

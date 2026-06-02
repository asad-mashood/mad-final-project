// components/player.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../screens/game_screen.dart';

class PlayerStats {
  double maxStamina = 100.0;
  double power = 1.0;
}

class Player extends PositionComponent
    with HasGameReference<TennisGame>, CollisionCallbacks {
  final bool isBottom;
  final String difficulty;
  final String? racket;
  final String? shoes;

  late final PlayerStats stats;
  late double stamina;

  // ── Movement state ──────────────────────────────────
  //
  // _directX / _directY: the exact finger position the player
  // must move to. Updated every frame from pan events.
  // We use a separate "direct" system instead of the old
  // "targetPosition at 250px/s" which felt sluggish.
  double? _directX;
  double? _directY;

  // Whether we have a pending target at all
  bool get _hasTarget => _directX != null;

  Player({
    required this.isBottom,
    this.difficulty = 'Medium',
    this.racket,
    this.shoes,
  }) {
    stats = PlayerStats();

    // Equipment modifiers
    if (racket == 'Power Racket') {
      stats.power = 1.3;
    } else if (racket == 'Control Racket') {
      stats.power = 0.9;
    }

    if (shoes == 'Sprint Shoes') {
      stats.maxStamina = 80.0;
    } else if (shoes == 'Endurance Shoes') {
      stats.maxStamina = 130.0;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(80, 20);
    anchor = Anchor.center;
    add(RectangleHitbox());
    stamina = stats.maxStamina;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _snapToDefaultRow(size);
  }

  void _snapToDefaultRow(Vector2 s) {
    if (s.x > 0 && s.y > 0) {
      if (isBottom) {
        position = Vector2(s.x / 2, s.y - 75.0);
      } else {
        position = Vector2(s.x / 2, 75.0);
      }
    }
  }

  // ── Called by TennisGame every pan-start / pan-update ──
  //
  // This is the ONLY way the bottom player gets a target.
  // x and y come straight from the Flutter finger position.
  void setDirectTarget(double fingerX, double fingerY, Vector2 gameSize) {
    final hw = size.x / 2;

    // Clamp X to court width
    _directX = fingerX.clamp(hw, gameSize.x - hw);

    // Y: only accept taps in the bottom half of the court.
    // If the player taps the top half (AI territory) we keep
    // the current Y so they don't accidentally rush the net.
    if (fingerY > gameSize.y * 0.50) {
      _directY = fingerY.clamp(
        gameSize.y * 0.52,
        gameSize.y - 30.0,
      );
    } else {
      // Keep current Y but allow horizontal movement
      _directY = position.y;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver) return;
    if (game.size.x <= 100 || game.size.y <= 100) return;

    if (isBottom) {
      _updateBottomPlayer(dt);
    } else {
      _updateAI(dt);
    }
  }

  // ── BOTTOM PLAYER (human) ───────────────────────────
  void _updateBottomPlayer(double dt) {
    final sw = game.size.x;
    final sh = game.size.y;

    // ── 1. Move toward finger target ──────────────────
    if (_hasTarget) {
      final tx = _directX!;
      final ty = _directY!;

      // Speed: high base speed (feels snappy), boosted when sprinting
      // Sprint costs stamina; exhaustion slows you down
      double baseSpeed = 1200.0;
      if (game.isSprinting && stamina > 0) {
        baseSpeed = 2000.0;
        stamina -= 32.0 * dt;
      } else if (stamina < stats.maxStamina) {
        stamina += 20.0 * dt;
      }
      if (stamina <= 0) {
        baseSpeed *= 0.50; // Tired — slower
        stamina = 0;
      }

      final dx = tx - position.x;
      final dy = ty - position.y;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < 6.0) {
        // Close enough — snap and clear target
        position.x = tx;
        position.y = ty;
        _directX = null;
        _directY = null;
      } else {
        // Move toward target at baseSpeed
        final step = min(dist, baseSpeed * dt);
        position.x += (dx / dist) * step;
        position.y += (dy / dist) * step;
      }
    } else {
      // No active target — recover stamina while standing still
      if (stamina < stats.maxStamina) {
        stamina += 22.0 * dt;
      }

      // ── 2. Soft auto-assist toward ball ──────────────
      // When the ball is active, the player automatically tracks its X position
      // so they stay centered and ready.
      _applyBallTracking(dt);
    }

    stamina = stamina.clamp(0.0, stats.maxStamina);

    // ── 3. Keep player inside bottom half ─────────────
    final hw = size.x / 2;
    final hh = size.y / 2;
    position.x = position.x.clamp(hw, sw - hw);
    position.y = position.y.clamp(sh * 0.50 + hh, sh - hh - 4);
  }

  // Auto-positioning toward ball to keep player in front of the ball
  void _applyBallTracking(double dt) {
    try {
      final ball = game.ball;
      final ballX = ball.position.x;
      final dx = ballX - position.x;
      final ballY = ball.position.y;
      final sh = game.size.y;

      double trackSpeed;
      if (ball.velocity.y > 0) {
        // Ball is coming towards us — track it dynamically.
        // As the ball gets closer, speed up to ensure alignment.
        final closeness = (ballY / sh).clamp(0.0, 1.0);
        trackSpeed = 400.0 + closeness * 450.0; // 400 to 850 px/s
      } else {
        // Ball is heading away — gently drift to match its X position
        trackSpeed = 250.0;
      }

      if (dx.abs() > 4) {
        final step = min(dx.abs(), trackSpeed * dt);
        position.x += (dx > 0 ? 1 : -1) * step;
      }
    } catch (_) {
      // ball not initialised yet — skip
    }
  }

  // ── TOP PLAYER (AI) ────────────────────────────────
  void _updateAI(double dt) {
    final sw = game.size.x;
    final sh = game.size.y;

    // AI difficulty settings
    double aiSpeed;
    double reactionZone; // How close ball must be before AI moves
    switch (difficulty) {
      case 'Easy':
        aiSpeed = 140.0;
        reactionZone = 0.45; // Reacts late
        break;
      case 'Hard':
        aiSpeed = 480.0;
        reactionZone = 0.70; // Reacts very early
        break;
      default: // Medium
        aiSpeed = 260.0;
        reactionZone = 0.55;
    }

    try {
      final ball = game.ball;
      if (ball.position.y < sh * reactionZone) {
        // Ball in AI half or approaching — track it
        final dx = ball.position.x - position.x;
        if (dx.abs() > 4) {
          position.x += (dx > 0 ? 1 : -1) * aiSpeed * dt;
        }
      } else {
        // Ball in player half — drift back to center
        final cx = sw / 2;
        final dc = cx - position.x;
        if (dc.abs() > 6) {
          position.x += (dc > 0 ? 1 : -1) * aiSpeed * 0.45 * dt;
        }
      }
    } catch (_) {}

    // Keep AI inside top half
    final hw = size.x / 2;
    final hh = size.y / 2;
    position.x = position.x.clamp(hw, sw - hw);
    position.y = position.y.clamp(hh + 4, sh * 0.48);
  }

  // Not used externally anymore but kept for compatibility
  void setTarget(Vector2 t) {
    setDirectTarget(t.x, t.y, game.size);
  }

  // Called by TennisGame.update for AI only (kept for compat)
  void moveTowardsBall(Vector2 ballPos, double dt) {
    // AI movement is handled inside _updateAI; this is a no-op
    // (the method is still called from TennisGame so we keep it)
  }

  // ── RENDER ──────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final mainColor =
        isBottom ? const Color(0xFF2196F3) : const Color(0xFFF44336);
    const skinColor = Color(0xFFFFCCAA);
    const shoeColor = Color(0xFFECEFF1);
    const racketFrameColor = Color(0xFF424242);
    const racketStringsColor = Color(0x80FFFFFF);

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Head
    paint.color = skinColor;
    canvas.drawCircle(Offset(0, isBottom ? 10 : -10), 12, paint);

    // Body (shirt)
    paint.color = mainColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, isBottom ? 25 : -25), width: 24, height: 20),
        const Radius.circular(5),
      ),
      paint,
    );

    // Arms
    paint.color = skinColor;
    canvas.drawCircle(Offset(-16, isBottom ? 25 : -25), 5, paint);
    canvas.drawCircle(Offset(16, isBottom ? 25 : -25), 5, paint);

    // Shoes
    paint.color = shoeColor;
    for (final dx in [-8.0, 8.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(dx, isBottom ? 40 : -40), width: 10, height: 12),
          const Radius.circular(3),
        ),
        paint,
      );
    }

    // Racket handle
    paint.color = racketFrameColor;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(20, isBottom ? 15 : -15), width: 6, height: 20),
      paint,
    );

    // Racket head
    final racketCenter = Offset(20, isBottom ? -5 : 5);
    strokePaint.color = racketFrameColor;
    strokePaint.strokeWidth = 3.0;
    canvas.drawOval(
        Rect.fromCenter(center: racketCenter, width: 20, height: 26),
        strokePaint);

    // Strings
    paint.color = racketStringsColor;
    canvas.drawOval(
        Rect.fromCenter(center: racketCenter, width: 18, height: 24), paint);

    if (isBottom) {
      // Timing ring — shows how close the ball is
      final ballPos = _safeBallPos();
      if (ballPos != null) {
        final dist = ballPos.distanceTo(position);
        if (dist < 140) {
          final zoneColor = dist < 55
              ? Colors.green
              : dist < 95
                  ? Colors.yellow
                  : Colors.red;
          canvas.drawCircle(
            Offset.zero,
            68,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = zoneColor.withValues(alpha: 0.70),
          );
        }
      }

      // Stamina bar
      const bw = 44.0, bh = 5.0, by = 56.0;
      paint.color = Colors.red.withValues(alpha: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, by), width: bw, height: bh),
          const Radius.circular(3),
        ),
        paint,
      );
      paint.color = stamina > 30 ? Colors.greenAccent : Colors.orangeAccent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-bw / 2, by - bh / 2,
              (stamina / stats.maxStamina) * bw, bh),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void resetPlayer() {
    _directX = null;
    _directY = null;
    stamina = stats.maxStamina;
    if (game.size.x > 0 && game.size.y > 0) {
      _snapToDefaultRow(game.size);
    }
  }

  Vector2? _safeBallPos() {
    try {
      return game.ball.position;
    } catch (_) {
      return null;
    }
  }
}

// components/player.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../screens/game_screen.dart';

class PlayerStats {
  double speed;
  double sprintSpeed;
  double power;
  double maxStamina;
  double staminaDrain;
  double staminaRegen;

  PlayerStats({
    this.speed = 1200.0,
    this.sprintSpeed = 2000.0,
    this.power = 1.0,
    this.maxStamina = 100.0,
    this.staminaDrain = 28.0,
    this.staminaRegen = 20.0,
  });
}

class Player extends PositionComponent
    with HasGameReference<TennisGame>, CollisionCallbacks {
  final bool isBottom;
  final String difficulty;
  final String? racket;
  final String? shoes;
  final String? shirtStyle;
  final int age;

  late final PlayerStats stats;
  late double stamina;

  double? _directX;
  double? _directY;
  bool get _hasTarget => _directX != null;

  Player({
    required this.isBottom,
    this.difficulty = 'Medium',
    this.racket,
    this.shoes,
    this.shirtStyle,
    this.age = 24,
  }) {
    stats = _buildStats();
  }

  // ── Profile stats — every field from setup screen impacts gameplay ──
  PlayerStats _buildStats() {
    final s = PlayerStats();

    // AGE impact
    if (age <= 19) {
      // Teen: lightning fast, low power, high stamina
      s.speed *= 1.30;
      s.sprintSpeed *= 1.25;
      s.power *= 0.82;
      s.maxStamina *= 1.20;
      s.staminaRegen *= 1.30;
    } else if (age <= 27) {
      // Prime: balanced — no changes
    } else if (age <= 33) {
      // Experienced: more power, slightly slower
      s.speed *= 0.92;
      s.power *= 1.18;
      s.maxStamina *= 1.15;
      s.staminaRegen *= 1.25;
    } else {
      // Veteran: slower but powerful, excellent stamina management
      s.speed *= 0.76;
      s.sprintSpeed *= 0.80;
      s.power *= 1.12;
      s.maxStamina *= 1.40;
      s.staminaRegen *= 1.70;
      s.staminaDrain *= 0.75;
    }

    // RACKET impact
    switch (racket) {
      case 'Power Racket':
        s.power *= 1.40;           // Big shots
        s.sprintSpeed *= 0.96;     // Slightly heavy
        break;
      case 'Control Racket':
        s.power *= 0.87;           // Less pace
        s.speed *= 1.06;           // Lighter, move faster
        s.staminaDrain *= 0.90;
        break;
      default: // Beginner Racket — no change
        break;
    }

    // SHOES impact
    switch (shoes) {
      case 'Sprint Shoes':
        s.speed *= 1.14;
        s.sprintSpeed *= 1.42;     // Explosive bursts
        s.staminaDrain *= 1.70;    // Burns out faster
        break;
      case 'Endurance Shoes':
        s.maxStamina *= 1.50;
        s.staminaRegen *= 3.0;     // Recover very fast
        s.staminaDrain *= 0.60;    // Last much longer
        break;
      default: // Basic Shoes — no change
        break;
    }

    // AI difficulty (only applies to top/AI player)
    if (!isBottom) {
      switch (difficulty) {
        case 'Easy':
          s.speed = 150.0;
          s.sprintSpeed = 200.0;
          s.power = 0.80;
          break;
        case 'Hard':
          s.speed = 510.0;
          s.sprintSpeed = 740.0;
          s.power = 1.35;
          break;
        default: // Medium
          s.speed = 270.0;
          s.sprintSpeed = 400.0;
          s.power = 1.0;
      }
    }

    return s;
  }

  // ── Colors from profile ──────────────────────────────
  Color get _shirtColor {
    if (!isBottom) return const Color(0xFFC62828); // AI always red
    switch (shirtStyle) {
      case 'Navy Blue':   return const Color(0xFF1565C0);
      case 'Neon Blue':   return const Color(0xFF00E5FF);
      case 'Red Fury':    
      case 'Pro Red':     return const Color(0xFFD32F2F);
      case 'All Black':   return const Color(0xFF212121);
      case 'Forest Green':return const Color(0xFF2E7D32);
      default:            return const Color(0xFFECEFF1); // Classic White
    }
  }

  Color get _shortsColor {
    if (!isBottom) return const Color(0xFF880E4F);
    switch (shirtStyle) {
      case 'Red Fury':    
      case 'Pro Red':     return const Color(0xFF212121);
      case 'Navy Blue':   return const Color(0xFF0D47A1);
      case 'Neon Blue':   return const Color(0xFF006064);
      case 'All Black':   return const Color(0xFF212121);
      case 'Forest Green':return const Color(0xFF1B5E20);
      default:            return const Color(0xFF1A237E);
    }
  }

  Color get _shoeColor {
    if (!isBottom) return const Color(0xFFB0BEC5);
    switch (shoes) {
      case 'Sprint Shoes':    return const Color(0xFFE53935);
      case 'Endurance Shoes': return const Color(0xFF1976D2);
      default:                return const Color(0xFFF5F5F5);
    }
  }

  Color get _hairColor => isBottom
      ? const Color(0xFF3E2723)
      : const Color(0xFF1B1B1B);

  // ── Lifecycle ────────────────────────────────────────
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
    if (size.x > 0 && size.y > 0) {
      position = isBottom
          ? Vector2(size.x / 2, size.y - 75.0)
          : Vector2(size.x / 2, 75.0);
    }
  }

  void setDirectTarget(double fingerX, double fingerY, Vector2 gameSize) {
    final hw = size.x / 2;
    _directX = fingerX.clamp(hw, gameSize.x - hw);
    _directY = fingerY > gameSize.y * 0.50
        ? fingerY.clamp(gameSize.y * 0.52, gameSize.y - 30.0)
        : position.y;
  }

  void setTarget(Vector2 t) => setDirectTarget(t.x, t.y, game.size);
  void moveTowardsBall(Vector2 ballPos, double dt) {} // AI handled in update

  void resetPlayer() {
    _directX = null;
    _directY = null;
    stamina = stats.maxStamina;
    if (game.size.x > 0 && game.size.y > 0) {
      position = isBottom
          ? Vector2(game.size.x / 2, game.size.y - 75.0)
          : Vector2(game.size.x / 2, 75.0);
    }
  }

  // ── Update ───────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (game.isPaused || game.isGameOver) return;
    if (game.size.x <= 100 || game.size.y <= 100) return;
    isBottom ? _updateHuman(dt) : _updateAI(dt);
  }

  void _updateHuman(double dt) {
    if (_hasTarget) {
      double spd = stats.speed;
      if (game.isSprinting && stamina > 0) {
        spd = stats.sprintSpeed;
        stamina -= stats.staminaDrain * dt;
      } else {
        stamina += stats.staminaRegen * dt;
      }
      if (stamina <= 0) { spd *= 0.50; stamina = 0; }

      final dx = _directX! - position.x;
      final dy = _directY! - position.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < 6.0) {
        position.x = _directX!; position.y = _directY!;
        _directX = _directY = null;
      } else {
        final step = min(dist, spd * dt);
        position.x += (dx / dist) * step;
        position.y += (dy / dist) * step;
      }
    } else {
      stamina += stats.staminaRegen * dt;
      if (difficulty != 'Hard') {
        _softBallTracking(dt);
      }
    }
    stamina = stamina.clamp(0.0, stats.maxStamina);
    final hw = size.x / 2; final hh = size.y / 2;
    final sh = game.size.y; final sw = game.size.x;
    position.x = position.x.clamp(hw, sw - hw);
    position.y = position.y.clamp(sh * 0.50 + hh, sh - hh - 4);
  }

  void _softBallTracking(double dt) {
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
    } catch (_) {}
  }

  void _updateAI(double dt) {
    final sw = game.size.x; final sh = game.size.y;
    try {
      final ball = game.ball;
      final reactionY = sh * (difficulty == 'Easy' ? 0.40 :
                               difficulty == 'Hard' ? 0.72 : 0.55);
      if (ball.position.y < reactionY) {
        final dx = ball.position.x - position.x;
        if (dx.abs() > 4) position.x += (dx > 0 ? 1 : -1) * stats.speed * dt;
      } else {
        final dc = sw / 2 - position.x;
        if (dc.abs() > 6) position.x += (dc > 0 ? 1 : -1) * stats.speed * 0.4 * dt;
      }
    } catch (_) {}
    final hw = size.x / 2; final hh = size.y / 2;
    position.x = position.x.clamp(hw, sw - hw);
    position.y = position.y.clamp(hh + 4, sh * 0.48);
  }

  // ── Render helpers ───────────────────────────────────
  void _r(Canvas c, Offset center, double w, double h, Color color,
      {double radius = 3}) {
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: w, height: h),
          Radius.circular(radius)),
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  void _oval(Canvas c, Offset center, double w, double h, Color color) {
    c.drawOval(Rect.fromCenter(center: center, width: w, height: h),
        Paint()..color = color..style = PaintingStyle.fill);
  }

  void _dot(Canvas c, Offset center, double r, Color color) {
    c.drawCircle(center, r, Paint()..color = color..style = PaintingStyle.fill);
  }

  // ── Main render ──────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final ym = isBottom ? 1.0 : -1.0;
    final shirt  = _shirtColor;
    final shorts = _shortsColor;
    final shoe   = _shoeColor;
    final hair   = _hairColor;
    const skin   = Color(0xFFFFCCAA);
    const sock   = Color(0xFFF5F5F5);
    const white  = Colors.white;

    // ── Shadow ──────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(3, ym * 54), width: 54, height: 13),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // ── Shoes ───────────────────────────────────────────
    _r(canvas, Offset(-10, ym * 47), 20, 10, shoe, radius: 5);
    _r(canvas, Offset(10, ym * 47), 20, 10, shoe, radius: 5);
    // Sole line
    canvas.drawLine(Offset(-20, ym * 51), Offset(0, ym * 51),
        Paint()..color = Colors.black26..strokeWidth = 1.5);
    canvas.drawLine(Offset(0, ym * 51), Offset(20, ym * 51),
        Paint()..color = Colors.black26..strokeWidth = 1.5);
    // Lace detail
    final lacePaint = Paint()..color = white.withValues(alpha: 0.5)..strokeWidth = 1.2;
    canvas.drawLine(Offset(-16, ym * 46), Offset(-4, ym * 48), lacePaint);
    canvas.drawLine(Offset(4, ym * 46), Offset(16, ym * 48), lacePaint);

    // ── Socks ───────────────────────────────────────────
    _r(canvas, Offset(-10, ym * 40), 13, 10, sock, radius: 2);
    _r(canvas, Offset(10, ym * 40), 13, 10, sock, radius: 2);
    // Sock stripe matching shirt
    _r(canvas, Offset(-10, ym * 38), 13, 2.5,
        shirt.withValues(alpha: 0.75));
    _r(canvas, Offset(10, ym * 38), 13, 2.5,
        shirt.withValues(alpha: 0.75));

    // ── Lower legs ──────────────────────────────────────
    _r(canvas, Offset(-10, ym * 31), 11, 14, skin, radius: 5);
    _r(canvas, Offset(10, ym * 31), 11, 14, skin, radius: 5);

    // ── Shorts ──────────────────────────────────────────
    _r(canvas, Offset(0, ym * 22), 32, 17, shorts, radius: 6);
    // Shorts side stripe
    _r(canvas, Offset(-14, ym * 21), 4, 14,
        white.withValues(alpha: 0.22), radius: 2);
    _r(canvas, Offset(14, ym * 21), 4, 14,
        white.withValues(alpha: 0.22), radius: 2);

    // ── Torso / Shirt ───────────────────────────────────
    _r(canvas, Offset(0, ym * 10), 30, 24, shirt, radius: 6);
    // Collar
    _r(canvas, Offset(0, ym * 22), 11, 6,
        white.withValues(alpha: 0.40), radius: 4);
    // Chest logo square
    _r(canvas, Offset(-7, ym * 9), 8, 8,
        white.withValues(alpha: 0.18), radius: 2);
    // Shirt seam lines
    canvas.drawLine(
      Offset(-15, ym * 0), Offset(-15, ym * 20),
      Paint()..color = Colors.black.withValues(alpha: 0.10)..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(15, ym * 0), Offset(15, ym * 20),
      Paint()..color = Colors.black.withValues(alpha: 0.10)..strokeWidth = 1,
    );

    // ── Left arm ────────────────────────────────────────
    _r(canvas, Offset(-19, ym * 9), 10, 20, skin, radius: 5);
    _dot(canvas, Offset(-19, ym * 20), 5, skin); // left hand

    // ── Right arm (racket arm) ───────────────────────────
    _r(canvas, Offset(20, ym * 5), 10, 24, skin, radius: 5);
    _dot(canvas, Offset(20, ym * -5), 5.5, skin); // right hand

    // ── Neck ────────────────────────────────────────────
    _r(canvas, Offset(0, ym * 22), 10, 8, skin, radius: 3);

    // ── Head ────────────────────────────────────────────
    _oval(canvas, Offset(0, ym * 36), 26, 28, skin);

    // ── Ears ────────────────────────────────────────────
    _oval(canvas, Offset(-14, ym * 36), 7, 9, skin);
    _oval(canvas, Offset(14, ym * 36), 7, 9, skin);

    // ── Hair ────────────────────────────────────────────
    _oval(canvas, Offset(0, ym * 44), 26, 15, hair);
    _oval(canvas, Offset(-2, ym * 33), 20, 9, hair); // hairline

    // ── Eyes ────────────────────────────────────────────
    _oval(canvas, Offset(-5.5, ym * 35), 6, 6, white);
    _oval(canvas, Offset(5.5, ym * 35), 6, 6, white);
    _dot(canvas, Offset(-5.5, ym * 35.5), 2.2, const Color(0xFF2C1810));
    _dot(canvas, Offset(5.5, ym * 35.5), 2.2, const Color(0xFF2C1810));
    _dot(canvas, Offset(-4.5, ym * 34.5), 0.8, white.withValues(alpha: 0.9));
    _dot(canvas, Offset(6.5, ym * 34.5), 0.8, white.withValues(alpha: 0.9));

    // ── Eyebrows ────────────────────────────────────────
    final brow = Paint()
      ..color = hair
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-9, ym * 30.5), Offset(-2, ym * 30.0), brow);
    canvas.drawLine(Offset(2, ym * 30.0), Offset(9, ym * 30.5), brow);

    // ── Nose ────────────────────────────────────────────
    canvas.drawLine(
      Offset(0, ym * 35.5),
      Offset(-2.5, ym * 39.0),
      Paint()..color = skin.withValues(alpha: 0.55)..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(0, ym * 35.5),
      Offset(2.5, ym * 39.0),
      Paint()..color = skin.withValues(alpha: 0.55)..strokeWidth = 1.8,
    );

    // ── Mouth ───────────────────────────────────────────
    final mouthPath = Path()
      ..moveTo(-4, ym * 41.0)
      ..quadraticBezierTo(0, ym * 43.5, 4, ym * 41.0);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFFAA7755)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // ── Racket ──────────────────────────────────────────
    _drawRacket(canvas, ym);

    // ── Special effects ─────────────────────────────────
    if (isBottom && game.isSprinting && stamina > 5) {
      _drawSprintEffect(canvas, ym);
    }
    if (isBottom && stamina < stats.maxStamina * 0.18) {
      _drawExhaustionEffect(canvas, ym);
    }

    // ── Hit zone ring ────────────────────────────────────
    if (isBottom) _drawTimingRing(canvas);

    // ── Stamina bar ──────────────────────────────────────
    if (isBottom) _drawStaminaBar(canvas, ym);
  }

  void _drawRacket(Canvas canvas, double ym) {
    final isPower   = racket == 'Power Racket';
    final isControl = racket == 'Control Racket';
    final rw = isPower ? 28.0 : isControl ? 20.0 : 23.0;
    final rh = isPower ? 38.0 : isControl ? 28.0 : 32.0;

    final frameColor = isPower
        ? const Color(0xFF880E4F)
        : isControl
            ? const Color(0xFF1B5E20)
            : const Color(0xFF263238);

    // Handle grip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(22, ym * 10), width: 8, height: 24),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF795548),
    );
    // Grip tape wraps
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(22, ym * (3.0 + i * 4.0)), width: 9, height: 1.5),
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }

    // Throat
    final throatPath = Path()
      ..moveTo(18, ym * -2)
      ..lineTo(22 - rw / 2 + 4, ym * -6)
      ..lineTo(22 + rw / 2 - 4, ym * -6)
      ..lineTo(26, ym * -2)
      ..close();
    canvas.drawPath(throatPath,
        Paint()..color = frameColor.withValues(alpha: 0.6));

    // Head frame
    final center = Offset(22, ym * -8);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rw, height: rh),
      Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Strings — vertical
    final sp = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 0.9;
    for (double x = -rw / 2 + 5; x < rw / 2 - 4; x += 4.5) {
      canvas.drawLine(
        Offset(center.dx + x, center.dy - rh / 2 + 5),
        Offset(center.dx + x, center.dy + rh / 2 - 5),
        sp,
      );
    }
    // Strings — horizontal
    for (double y = -rh / 2 + 5; y < rh / 2 - 4; y += 4.5) {
      canvas.drawLine(
        Offset(center.dx - rw / 2 + 5, center.dy + y),
        Offset(center.dx + rw / 2 - 5, center.dy + y),
        sp,
      );
    }

    // Power racket glow
    if (isPower) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: rw + 6, height: rh + 6),
        Paint()
          ..color = const Color(0xFFE91E63).withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  void _drawSprintEffect(Canvas canvas, double ym) {
    // Foot glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, ym * 49), width: 52, height: 16),
      Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Speed streaks
    final streakPaint = Paint()..strokeWidth = 1.8;
    for (int i = 0; i < 6; i++) {
      final x = -24.0 + i * 10.0;
      final len = (i % 2 == 0) ? 14.0 : 9.0;
      streakPaint.color =
          Colors.orangeAccent.withValues(alpha: 0.65 - i * 0.08);
      canvas.drawLine(
        Offset(x, ym * 52),
        Offset(x - 3, ym * (52 + len)),
        streakPaint,
      );
    }
  }

  void _drawExhaustionEffect(Canvas canvas, double ym) {
    // Sweat drops
    final dropPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.70);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(-18, ym * 39), width: 5, height: 7),
        dropPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(4, ym * 37), width: 4, height: 6),
        dropPaint);
    // Red fatigue tint over head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, ym * 36), width: 30, height: 32),
      Paint()..color = Colors.red.withValues(alpha: 0.10),
    );
    // Wavy exhaustion lines (like heat shimmer)
    final linePaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final path = Path()..moveTo(-10.0 + i * 10, ym * 28);
      path.quadraticBezierTo(
          -7.0 + i * 10, ym * 26, -4.0 + i * 10, ym * 28);
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawTimingRing(Canvas canvas) {
    final ballPos = _safeBallPos();
    if (ballPos == null) return;
    final dist = ballPos.distanceTo(position);
    if (dist >= 145) return;

    final Color zoneColor;
    final double radius;
    if (dist < 50) {
      zoneColor = Colors.greenAccent;
      radius = 62.0;
    } else if (dist < 95) {
      zoneColor = Colors.yellowAccent;
      radius = 72.0;
    } else {
      zoneColor = Colors.redAccent;
      radius = 80.0;
    }

    // Glow fill
    canvas.drawCircle(
      Offset.zero, radius + 6,
      Paint()
        ..color = zoneColor.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Ring
    canvas.drawCircle(
      Offset.zero, radius,
      Paint()
        ..color = zoneColor.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Corner dashes
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawCircle(
        Offset(cos(angle) * radius, sin(angle) * radius),
        2.2,
        Paint()..color = zoneColor.withValues(alpha: 0.90),
      );
    }
  }

  void _drawStaminaBar(Canvas canvas, double ym) {
    const bw = 54.0, bh = 7.0;
    final by = ym * 65.0;

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, by), width: bw, height: bh),
          const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.50),
    );
    // Fill
    final pct = stamina / stats.maxStamina;
    final barColor = pct > 0.55
        ? const Color(0xFF69F0AE)
        : pct > 0.28
            ? const Color(0xFFFFFF00)
            : const Color(0xFFFF5252);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-bw / 2, by - bh / 2, pct * bw, bh),
          const Radius.circular(4)),
      Paint()..color = barColor,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, by), width: bw, height: bh),
          const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Lightning bolt icon
    final bolt = Path()
      ..moveTo(-bw / 2 - 10, by - 5)
      ..lineTo(-bw / 2 - 5, by - 0.5)
      ..lineTo(-bw / 2 - 8, by - 0.5)
      ..lineTo(-bw / 2 - 3, by + 5)
      ..lineTo(-bw / 2 - 8, by + 1)
      ..lineTo(-bw / 2 - 11, by + 1);
    canvas.drawPath(bolt,
        Paint()..color = Colors.yellowAccent..style = PaintingStyle.fill);
  }

  Vector2? _safeBallPos() {
    try { return game.ball.position; } catch (_) { return null; }
  }
}

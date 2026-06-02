// components/court.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';

class Court extends RectangleComponent with HasGameReference<TennisGame> {
  final Color color;
  final Random _rng = Random();

  // Camera flashes: list of (x, y, opacity) triples
  final List<_Flash> _flashes = [];
  double _flashTimer = 0.0;

  // Crowd cheer animation
  double _cheerAmount = 0.0; // 0..1 how much crowd is jumping

  Court({required this.color}) : super(paint: Paint()..color = color);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.size.x <= 100 || game.size.y <= 100) return;

    // Randomly spawn camera flashes
    _flashTimer -= dt;
    if (_flashTimer <= 0) {
      _flashTimer = _rng.nextDouble() * 0.4 + 0.05;
      final w = size.x;
      final h = size.y;

      // Flash can appear anywhere in the audience area
      double fx, fy;
      final zone = _rng.nextInt(4);
      if (zone == 0) {
        // top
        fx = _rng.nextDouble() * w;
        fy = _rng.nextDouble() * 45;
      } else if (zone == 1) {
        // bottom
        fx = _rng.nextDouble() * w;
        fy = h - _rng.nextDouble() * 45;
      } else if (zone == 2) {
        // left
        fx = _rng.nextDouble() * 32;
        fy = _rng.nextDouble() * h;
      } else {
        // right
        fx = w - _rng.nextDouble() * 32;
        fy = _rng.nextDouble() * h;
      }
      _flashes.add(_Flash(fx, fy, 1.0));
    }

    // Fade out flashes
    for (final f in _flashes) {
      f.opacity -= dt * 6.0;
    }
    _flashes.removeWhere((f) => f.opacity <= 0);

    // Decay cheer
    _cheerAmount = (_cheerAmount - dt * 2.0).clamp(0.0, 1.0);
  }

  void triggerCheer() {
    _cheerAmount = 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final courtName = game.courtName;

    if (w <= 0 || h <= 0) {
      // Fallback so the game surface is always visible during initialization.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, game.size.x, game.size.y),
        Paint()..color = color,
      );
      return;
    }

    // ── 1. Stadium outer dark area ───────────────────────────
    final stadiumPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF1A1A2E),
              const Color(0xFF0A0A1A),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), stadiumPaint);

    // ── 2. Stands tiers (3 gradient arcs at top and bottom) ──
    _drawStands(canvas, w, h);

    // ── 3. Playing surface ───────────────────────────────────
    const cMX = 35.0;
    const cMY = 52.0;
    final courtRect = Rect.fromLTWH(cMX, cMY, w - 2 * cMX, h - 2 * cMY);

    if (courtName.contains('Wimbledon') || courtName.contains('Grass')) {
      _drawGrassCourt(canvas, courtRect);
    } else if (courtName.contains('Roland') ||
        courtName.contains('French') ||
        courtName.contains('Clay')) {
      _drawClayCourt(canvas, courtRect);
    } else {
      _drawHardCourt(canvas, courtRect, courtName);
    }

    // ── 4. Court lines ───────────────────────────────────────
    _drawCourtLines(canvas, courtRect);

    // ── 5. Spectator dots ────────────────────────────────────
    _drawSpectators(canvas, w, h);

    // ── 6. Camera flashes ────────────────────────────────────
    _drawFlashes(canvas);
  }

  // ─── Stands: dark gradient rows ─────────────────────────────────────────────
  void _drawStands(Canvas canvas, double w, double h) {
    final tierColors = [
      const Color(0xFF252540),
      const Color(0xFF1E1E35),
      const Color(0xFF18182A),
    ];
    // Top stand
    for (int i = 0; i < tierColors.length; i++) {
      final p = Paint()..color = tierColors[i];
      canvas.drawRect(Rect.fromLTWH(0, (i * 16).toDouble(), w, 18), p);
    }
    // Bottom stand
    for (int i = 0; i < tierColors.length; i++) {
      final p = Paint()..color = tierColors[i];
      canvas.drawRect(Rect.fromLTWH(0, h - 18 - (i * 16).toDouble(), w, 18), p);
    }
    // Left stand
    for (int i = 0; i < 3; i++) {
      final p = Paint()..color = tierColors[i];
      canvas.drawRect(Rect.fromLTWH((i * 10).toDouble(), 52, 12, h - 104), p);
    }
    // Right stand
    for (int i = 0; i < 3; i++) {
      final p = Paint()..color = tierColors[i];
      canvas.drawRect(
        Rect.fromLTWH(w - 12 - (i * 10).toDouble(), 52, 12, h - 104),
        p,
      );
    }
  }

  // ─── Grass Court ─────────────────────────────────────────────────────────────
  void _drawGrassCourt(Canvas canvas, Rect r) {
    // Alternating mowing stripes (dark/light green)
    const stripeW = 18.0;
    final stripeCount = (r.width / stripeW).ceil();
    for (int i = 0; i < stripeCount; i++) {
      final isLight = i.isEven;
      final p =
          Paint()
            ..color =
                isLight ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20);
      final sx = r.left + i * stripeW;
      canvas.drawRect(Rect.fromLTWH(sx, r.top, stripeW, r.height), p);
    }
    // Slight sheen overlay
    final sheenPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
              Colors.white.withValues(alpha: 0.04),
            ],
          ).createShader(r);
    canvas.drawRect(r, sheenPaint);
  }

  // ─── Clay Court ──────────────────────────────────────────────────────────────
  void _drawClayCourt(Canvas canvas, Rect r) {
    // Base clay color radial gradient
    final p =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [const Color(0xFFBF360C), const Color(0xFF8D2305)],
          ).createShader(r);
    canvas.drawRect(r, p);

    // Clay texture: lots of tiny random dots/speckles
    final specklePaint = Paint()..color = const Color(0x30FF7043);
    final rng = Random(42);
    for (int i = 0; i < 400; i++) {
      final sx = r.left + rng.nextDouble() * r.width;
      final sy = r.top + rng.nextDouble() * r.height;
      canvas.drawCircle(
        Offset(sx, sy),
        rng.nextDouble() * 2 + 0.5,
        specklePaint,
      );
    }

    // Subtle stripe pattern (clay is dragged/brushed)
    final stripePaint =
        Paint()
          ..color = const Color(0x15FF5722)
          ..strokeWidth = 3;
    for (double sy = r.top; sy < r.bottom; sy += 8) {
      canvas.drawLine(Offset(r.left, sy), Offset(r.right, sy), stripePaint);
    }

    // Top highlight
    final highlightPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
            stops: const [0, 0.3],
          ).createShader(r);
    canvas.drawRect(r, highlightPaint);
  }

  // ─── Hard Court ──────────────────────────────────────────────────────────────
  void _drawHardCourt(Canvas canvas, Rect r, String courtName) {
    // Main colour based on court name
    Color mainColor;
    Color accentColor;
    if (courtName.contains('Australian')) {
      mainColor = const Color(0xFF0D47A1);
      accentColor = const Color(0xFF1565C0);
    } else if (courtName.contains('Arthur') || courtName.contains('US Open')) {
      mainColor = const Color(0xFF1565C0);
      accentColor = const Color(0xFF0D47A1);
    } else {
      mainColor = const Color(0xFF0277BD);
      accentColor = const Color(0xFF01579B);
    }

    // Two-tone design: service boxes are slightly different shade
    final basePaint = Paint()..color = mainColor;
    canvas.drawRect(r, basePaint);

    // Accent service areas (inner 50%)
    final serviceRect = Rect.fromLTWH(
      r.left + r.width * 0.1,
      r.top + r.height * 0.25,
      r.width * 0.8,
      r.height * 0.5,
    );
    final accentPaint = Paint()..color = accentColor;
    canvas.drawRect(serviceRect, accentPaint);

    // Subtle grain texture
    final grainPaint = Paint()..color = Colors.white.withValues(alpha: 0.02);
    final rng = Random(99);
    for (int i = 0; i < 300; i++) {
      final gx = r.left + rng.nextDouble() * r.width;
      final gy = r.top + rng.nextDouble() * r.height;
      canvas.drawCircle(Offset(gx, gy), rng.nextDouble() * 1.5, grainPaint);
    }

    // Sheen
    final sheenPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent],
            stops: const [0, 0.5],
          ).createShader(r);
    canvas.drawRect(r, sheenPaint);
  }

  // ─── Court Lines ─────────────────────────────────────────────────────────────
  void _drawCourtLines(Canvas canvas, Rect r) {
    final linePaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
    final thickLinePaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    const innerM = 14.0;
    final lx = r.left + innerM;
    final ly = r.top + innerM;
    final lw = r.width - 2 * innerM;
    final lh = r.height - 2 * innerM;

    // Outer boundary (thick)
    canvas.drawRect(Rect.fromLTWH(lx, ly, lw, lh), thickLinePaint);

    // Service lines (horizontal)
    canvas.drawLine(
      Offset(lx, ly + lh * 0.25),
      Offset(lx + lw, ly + lh * 0.25),
      linePaint,
    );
    canvas.drawLine(
      Offset(lx, ly + lh * 0.75),
      Offset(lx + lw, ly + lh * 0.75),
      linePaint,
    );

    // Baseline extension markers (short T marks at the net)
    canvas.drawLine(
      Offset(lx + lw / 2 - 10, ly + lh * 0.5),
      Offset(lx + lw / 2 + 10, ly + lh * 0.5),
      linePaint,
    );

    // Singles sidelines
    final singlesM = lw * 0.15;
    canvas.drawLine(
      Offset(lx + singlesM, ly),
      Offset(lx + singlesM, ly + lh),
      linePaint,
    );
    canvas.drawLine(
      Offset(lx + lw - singlesM, ly),
      Offset(lx + lw - singlesM, ly + lh),
      linePaint,
    );

    // Center service line
    canvas.drawLine(
      Offset(lx + lw / 2, ly + lh * 0.25),
      Offset(lx + lw / 2, ly + lh * 0.75),
      linePaint,
    );

    // Center marks at baselines
    final cmLen = 8.0;
    canvas.drawLine(
      Offset(lx + lw / 2, ly),
      Offset(lx + lw / 2, ly + cmLen),
      linePaint,
    );
    canvas.drawLine(
      Offset(lx + lw / 2, ly + lh - cmLen),
      Offset(lx + lw / 2, ly + lh),
      linePaint,
    );
  }

  // ─── Spectator dots ──────────────────────────────────────────────────────────
  void _drawSpectators(Canvas canvas, double w, double h) {
    final spectatorColors = [
      const Color(0xFFE57373),
      const Color(0xFF64B5F6),
      const Color(0xFF81C784),
      const Color(0xFFFFD54F),
      const Color(0xFFBA68C8),
      const Color(0xFFFFFFFF),
      const Color(0xFFFF8A65),
      const Color(0xFF4DB6AC),
    ];
    final paint = Paint();

    // Cheer bounce offset
    final bounce = (_cheerAmount * 3.0 * sin(_flashTimer * 20)).toDouble();

    // Top audience rows (3 rows)
    for (int row = 0; row < 4; row++) {
      final ry = 4.0 + row * 10.0 + (row == 0 ? bounce : 0);
      for (double x = 8; x < w; x += 11) {
        paint.color = spectatorColors[((x + row * 3).toInt()) %
                spectatorColors.length]
            .withValues(alpha: 0.7 + row * 0.08);
        canvas.drawCircle(Offset(x, ry), 3.0, paint);
      }
    }

    // Bottom audience rows
    for (int row = 0; row < 4; row++) {
      final ry = h - 4.0 - row * 10.0 + (row == 0 ? bounce : 0);
      for (double x = 8; x < w; x += 11) {
        paint.color = spectatorColors[((x + row * 5).toInt()) %
                spectatorColors.length]
            .withValues(alpha: 0.7 + row * 0.08);
        canvas.drawCircle(Offset(x, ry), 3.0, paint);
      }
    }

    // Left audience columns
    for (int col = 0; col < 3; col++) {
      final cx = 5.0 + col * 10.0;
      for (double y = 52; y < h - 52; y += 11) {
        paint.color = spectatorColors[((y + col * 4).toInt()) %
                spectatorColors.length]
            .withValues(alpha: 0.65 + col * 0.1);
        canvas.drawCircle(Offset(cx, y + (col == 0 ? bounce : 0)), 3.0, paint);
      }
    }

    // Right audience columns
    for (int col = 0; col < 3; col++) {
      final cx = w - 5.0 - col * 10.0;
      for (double y = 52; y < h - 52; y += 11) {
        paint.color = spectatorColors[((y + col * 6).toInt()) %
                spectatorColors.length]
            .withValues(alpha: 0.65 + col * 0.1);
        canvas.drawCircle(Offset(cx, y + (col == 0 ? bounce : 0)), 3.0, paint);
      }
    }
  }

  // ─── Camera Flashes ──────────────────────────────────────────────────────────
  void _drawFlashes(Canvas canvas) {
    for (final f in _flashes) {
      final flashPaint =
          Paint()
            ..color = const Color(
              0xFFFFFFFF,
            ).withValues(alpha: f.opacity.clamp(0.0, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(f.x, f.y), 5, flashPaint);
    }
  }
}

class _Flash {
  final double x;
  final double y;
  double opacity;
  _Flash(this.x, this.y, this.opacity);
}

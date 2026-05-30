// components/pause_menu.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';

class PauseMenu extends PositionComponent with HasGameRef<TennisGame>, TapCallbacks {
  late RRect resumeButton;
  late RRect restartButton;
  late RRect exitButton;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    priority = 100; // Render on top of everything
  }

  @override
  void render(Canvas canvas) {
    // Semi-transparent dark overlay
    final overlayPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.7);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Title: "PAUSED" - properly centered
    final titleStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 48,
      fontWeight: FontWeight.bold,
      letterSpacing: 8,
    );
    final titleSpan = TextSpan(text: 'PAUSED', style: titleStyle);
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(centerX - titlePainter.width / 2, centerY - 150),
    );

    // Button dimensions
    const buttonWidth = 200.0;
    const buttonHeight = 55.0;
    const buttonSpacing = 20.0;

    // Resume Button
    resumeButton = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - 30),
        width: buttonWidth,
        height: buttonHeight,
      ),
      const Radius.circular(15),
    );
    _drawButton(canvas, resumeButton, 'RESUME', const Color(0xFF4CAF50));

    // Restart Button
    restartButton = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + buttonHeight + buttonSpacing - 30),
        width: buttonWidth,
        height: buttonHeight,
      ),
      const Radius.circular(15),
    );
    _drawButton(canvas, restartButton, 'RESTART', const Color(0xFF2196F3));

    // Exit Button
    exitButton = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 2 * (buttonHeight + buttonSpacing) - 30),
        width: buttonWidth,
        height: buttonHeight,
      ),
      const Radius.circular(15),
    );
    _drawButton(canvas, exitButton, 'EXIT', const Color(0xFFF44336));
  }

  void _drawButton(Canvas canvas, RRect rect, String text, Color color) {
    // Button background with gradient effect
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.7),
        ],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, bgPaint);

    // Button border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rect, borderPaint);

    // Button text - properly centered
    final textStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    final tapPosition = event.localPosition;

    if (resumeButton.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.togglePause();
    } else if (restartButton.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.restartGame();
    } else if (exitButton.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.exitGame();
    }
  }
}

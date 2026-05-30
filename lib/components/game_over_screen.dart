// components/game_over_screen.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';

class GameOverScreen extends PositionComponent with HasGameRef<TennisGame>, TapCallbacks {
  final bool playerWon;
  final int playerScore;
  final int aiScore;

  late RRect playAgainButton;
  late RRect exitButton;

  GameOverScreen({
    required this.playerWon,
    required this.playerScore,
    required this.aiScore,
  });

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    priority = 100; // Render on top
  }

  @override
  void render(Canvas canvas) {
    // Semi-transparent dark overlay
    final overlayPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Trophy or result icon background
    final iconBgPaint = Paint()
      ..color = playerWon ? const Color(0xFFFFD700) : const Color(0xFF9E9E9E);
    canvas.drawCircle(Offset(centerX, centerY - 180), 50, iconBgPaint);

    // Result icon text (trophy emoji substitute) - centered
    final iconStyle = TextStyle(
      fontSize: 40,
      color: playerWon ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    );
    final iconSpan = TextSpan(text: playerWon ? '🏆' : '❌', style: iconStyle);
    final iconPainter = TextPainter(
      text: iconSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(centerX - iconPainter.width / 2, centerY - 200),
    );

    // "GAME OVER" title - properly centered
    final titleStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 42,
      fontWeight: FontWeight.bold,
      letterSpacing: 4,
    );
    final titleSpan = TextSpan(text: 'GAME OVER', style: titleStyle);
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(centerX - titlePainter.width / 2, centerY - 100),
    );

    // Winner announcement - properly centered
    final winnerStyle = TextStyle(
      color: playerWon ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );
    final winnerText = playerWon ? 'YOU WIN!' : 'AI WINS!';
    final winnerSpan = TextSpan(text: winnerText, style: winnerStyle);
    final winnerPainter = TextPainter(
      text: winnerSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    winnerPainter.paint(
      canvas,
      Offset(centerX - winnerPainter.width / 2, centerY - 40),
    );

    // Final score label - properly centered
    final scoreLabelStyle = const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 24,
    );
    final scoreLabelSpan = TextSpan(text: 'Final Score', style: scoreLabelStyle);
    final scoreLabelPainter = TextPainter(
      text: scoreLabelSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    scoreLabelPainter.paint(
      canvas,
      Offset(centerX - scoreLabelPainter.width / 2, centerY + 10),
    );

    // Score value - properly centered
    final scoreValueStyle = const TextStyle(
      color: Color(0xFFFFEB3B),
      fontSize: 36,
      fontWeight: FontWeight.bold,
    );
    final scoreValueSpan = TextSpan(text: '$playerScore - $aiScore', style: scoreValueStyle);
    final scoreValuePainter = TextPainter(
      text: scoreValueSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    scoreValuePainter.paint(
      canvas,
      Offset(centerX - scoreValuePainter.width / 2, centerY + 45),
    );

    // Button dimensions
    const buttonWidth = 200.0;
    const buttonHeight = 55.0;
    const buttonSpacing = 20.0;

    // Play Again Button
    playAgainButton = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 130),
        width: buttonWidth,
        height: buttonHeight,
      ),
      const Radius.circular(15),
    );
    _drawButton(canvas, playAgainButton, 'PLAY AGAIN', const Color(0xFF4CAF50));

    // Exit Button
    exitButton = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 130 + buttonHeight + buttonSpacing),
        width: buttonWidth,
        height: buttonHeight,
      ),
      const Radius.circular(15),
    );
    _drawButton(canvas, exitButton, 'EXIT', const Color(0xFFF44336));
  }

  void _drawButton(Canvas canvas, RRect rect, String text, Color color) {
    // Button background with gradient
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

    if (playAgainButton.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.playAgain();
    } else if (exitButton.contains(Offset(tapPosition.x, tapPosition.y))) {
      gameRef.exitGame();
    }
  }
}

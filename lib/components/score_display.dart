// components/score_display.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';

class ScoreDisplay extends PositionComponent with HasGameReference<TennisGame> {
  final TextComponent topScoreText = TextComponent(
    text: '0',
    anchor: Anchor.center,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
  
  final TextComponent bottomScoreText = TextComponent(
    text: '0',
    anchor: Anchor.center,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  final TextComponent announcementText = TextComponent(
    text: '',
    anchor: Anchor.centerLeft,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 18, // Reduced from 24
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  double announcementTimer = 0;
  String currentAnnouncement = '';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(topScoreText);
    add(bottomScoreText);
    add(announcementText);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    topScoreText.position = Vector2(30, size.y / 2 - 70);
    bottomScoreText.position = Vector2(30, size.y / 2 + 30);
    announcementText.position = Vector2(80, size.y / 2 - 20);
  }

  // Convert score to tennis terminology (words)
  String getPointName(int points) {
    switch (points) {
      case 0:
        return 'Love';
      case 1:
        return 'Fifteen';
      case 2:
        return 'Thirty';
      case 3:
        return 'Forty';
      default:
        return 'Forty';
    }
  }

  // Convert score to tennis numeric format
  String getTennisPoints(int points, int opponentPoints) {
    if (points >= 3 && opponentPoints >= 3) {
      if (points == opponentPoints) return '40'; // Deuce
      if (points > opponentPoints) return 'AD';
      return '40'; // the other has advantage
    }
    switch (points) {
      case 0:
        return '0';
      case 1:
        return '15';
      case 2:
        return '30';
      case 3:
        return '40';
      default:
        return '40';
    }
  }

  // Get tennis score announcement
  String getTennisScore(int playerScore, int aiScore) {
    // Handle Deuce and Advantage
    if (playerScore >= 3 && aiScore >= 3) {
      if (playerScore == aiScore) {
        return 'Deuce';
      } else if (playerScore > aiScore) {
        return 'Advantage Player';
      } else {
        return 'Advantage AI';
      }
    }

    // Handle Game won
    if (playerScore >= 4 && playerScore - aiScore >= 2) {
      return 'Game Player!';
    }
    if (aiScore >= 4 && aiScore - playerScore >= 2) {
      return 'Game AI!';
    }

    // Regular scoring
    final playerPoint = getPointName(playerScore);
    final aiPoint = getPointName(aiScore);

    // Equal scores (but not deuce)
    if (playerScore == aiScore && playerScore < 3) {
      return '$playerPoint All';
    }

    // Normal announcement: Player - AI
    return '$playerPoint - $aiPoint';
  }

  // Show score announcement from referee
  void announceScore() {
    currentAnnouncement = getTennisScore(
      game.bottomPlayerScore,
      game.topPlayerScore,
    );
    announcementTimer = 2.5; // Show for 2.5 seconds
    debugPrint('Announcing: $currentAnnouncement');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.size.x <= 100 || game.size.y <= 100) return;

    // Update scores in tennis format (0, 15, 30, 40, AD)
    topScoreText.text = getTennisPoints(
      game.topPlayerScore,
      game.bottomPlayerScore,
    );
    bottomScoreText.text = getTennisPoints(
      game.bottomPlayerScore,
      game.topPlayerScore,
    );

    // Handle announcement timer
    if (announcementTimer > 0) {
      announcementTimer -= dt;
      announcementText.text = currentAnnouncement;

      if (announcementTimer <= 0) {
        announcementText.text = '';
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw background boxes for numerical scores
    final bgPaint =
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    // Background for top score
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(30, game.size.y / 2 - 70),
          width: 45,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Background for bottom score
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(30, game.size.y / 2 + 30),
          width: 45,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Draw speech bubble for announcement
    if (announcementTimer > 0 && currentAnnouncement.isNotEmpty) {
      final bubblePaint =
          Paint()
            ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;

      final textWidth = currentAnnouncement.length * 14.0;
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(70, game.size.y / 2 - 40, textWidth + 20, 40),
        const Radius.circular(10),
      );

      canvas.drawRRect(bubbleRect, bubblePaint);

      // Border
      final borderPaint =
          Paint()
            ..color = const Color(0xFFFFEB3B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
      canvas.drawRRect(bubbleRect, borderPaint);

      // Pointer to referee
      final pointer =
          Path()
            ..moveTo(70, game.size.y / 2 - 30)
            ..lineTo(55, game.size.y / 2 - 25)
            ..lineTo(70, game.size.y / 2 - 20)
            ..close();

      canvas.drawPath(pointer, bubblePaint);
      canvas.drawPath(pointer, borderPaint);
    }

    super.render(canvas);
  }
}

// components/score_display.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../screens/game_screen.dart';

class ScoreDisplay extends PositionComponent with HasGameRef<TennisGame> {
  late TextComponent topScoreText;
  late TextComponent bottomScoreText;
  late TextComponent announcementText;

  double announcementTimer = 0;
  String currentAnnouncement = '';

  @override
  Future<void> onLoad() async {
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    // Top player score (AI) - Above referee chair
    topScoreText = TextComponent(
      text: '0',
      anchor: Anchor.center,
      position: Vector2(30, gameRef.size.y / 2 - 70),
      textRenderer: textPaint,
    );
    add(topScoreText);

    // Bottom player score (You) - Below referee chair
    bottomScoreText = TextComponent(
      text: '0',
      anchor: Anchor.center,
      position: Vector2(30, gameRef.size.y / 2 + 30),
      textRenderer: textPaint,
    );
    add(bottomScoreText);

    // Score announcement (pops from referee)
    final announcementPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 18,  // Reduced from 24
        fontWeight: FontWeight.bold,
      ),
    );

    announcementText = TextComponent(
      text: '',
      anchor: Anchor.centerLeft,
      position: Vector2(80, gameRef.size.y / 2 - 20),
      textRenderer: announcementPaint,
    );
    add(announcementText);
  }

  // Convert score to tennis terminology (words)
  String getPointName(int points) {
    switch (points) {
      case 0: return 'Love';
      case 1: return 'Fifteen';
      case 2: return 'Thirty';
      case 3: return 'Forty';
      default: return 'Forty';
    }
  }

  // Convert score to tennis numeric format
  String getTennisPoints(int points) {
    switch (points) {
      case 0: return '0';
      case 1: return '15';
      case 2: return '30';
      case 3: return '40';
      default: return '40'; // For advantage situations
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
    currentAnnouncement = getTennisScore(gameRef.bottomPlayerScore, gameRef.topPlayerScore);
    announcementTimer = 2.5; // Show for 2.5 seconds
    debugPrint('Announcing: $currentAnnouncement');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update scores in tennis format (0, 15, 30, 40)
    topScoreText.text = getTennisPoints(gameRef.topPlayerScore);
    bottomScoreText.text = getTennisPoints(gameRef.bottomPlayerScore);

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
    final bgPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Background for top score
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(30, gameRef.size.y / 2 - 70),
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
          center: Offset(30, gameRef.size.y / 2 + 30),
          width: 45,
          height: 40,
        ),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // Draw labels
    final labelPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    // labelPaint.render(canvas, 'AI', Vector2(18, gameRef.size.y / 2 - 95));
    // labelPaint.render(canvas, 'YOU', Vector2(13, gameRef.size.y / 2 + 55));

    // Draw speech bubble for announcement
    if (announcementTimer > 0 && currentAnnouncement.isNotEmpty) {
      final bubblePaint = Paint()
        ..color = const Color(0xFF1A1A2E).withOpacity(0.9)
        ..style = PaintingStyle.fill;

      final textWidth = currentAnnouncement.length * 14.0;
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(70, gameRef.size.y / 2 - 40, textWidth + 20, 40),
        const Radius.circular(10),
      );

      canvas.drawRRect(bubbleRect, bubblePaint);

      // Border
      final borderPaint = Paint()
        ..color = const Color(0xFFFFEB3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(bubbleRect, borderPaint);

      // Pointer to referee
      final pointer = Path()
        ..moveTo(70, gameRef.size.y / 2 - 30)
        ..lineTo(55, gameRef.size.y / 2 - 25)
        ..lineTo(70, gameRef.size.y / 2 - 20)
        ..close();

      canvas.drawPath(pointer, bubblePaint);
      canvas.drawPath(pointer, borderPaint);
    }

    super.render(canvas);
  }
}
import 'dart:ui';
import 'package:flame/components.dart';
import '../screens/game_screen.dart';

class RefereeSeat extends PositionComponent with HasGameRef<TennisGame> {
  @override
  Future<void> onLoad() async {
    // Position on left side of net
    position = Vector2(15, gameRef.size.y / 2 - 40);
    size = Vector2(30, 60);
  }

  @override
  void render(Canvas canvas) {
    // Draw high chair structure
    final chairPaint = Paint()
      ..color = const Color(0xFF424242) // Dark gray
      ..style = PaintingStyle.fill;

    // Chair legs (thin lines)
    final legPaint = Paint()
      ..color = const Color(0xFF616161)
      ..strokeWidth = 3;

    // Left leg
    canvas.drawLine(
      const Offset(5, 60),
      const Offset(10, 30),
      legPaint,
    );

    // Right leg
    canvas.drawLine(
      const Offset(25, 60),
      const Offset(20, 30),
      legPaint,
    );

    // Seat platform
    canvas.drawRect(
      const Rect.fromLTWH(5, 25, 20, 8),
      chairPaint,
    );

    // Backrest
    canvas.drawRect(
      const Rect.fromLTWH(5, 10, 4, 20),
      chairPaint,
    );

    // Referee figure (simplified)
    final refPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      const Offset(15, 15),
      4,
      refPaint,
    );

    // Body
    canvas.drawRect(
      const Rect.fromLTWH(12, 19, 6, 10),
      refPaint,
    );

    // White shirt detail
    final shirtPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(13, 20, 4, 4),
      shirtPaint,
    );
  }
}
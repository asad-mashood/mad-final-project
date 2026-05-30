import 'dart:ui';
import 'package:flame/components.dart';
import '../screens/game_screen.dart';

class Net extends PositionComponent with HasGameRef<TennisGame> {
  @override
  Future<void> onLoad() async {
    position = Vector2(0, gameRef.size.y / 2);
    size = Vector2(gameRef.size.x, 30);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 4;

    // Draw main net line (center horizontal line)
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.x, 0),
      paint,
    );

    // Draw net mesh pattern (vertical lines)
    paint.strokeWidth = 1.5;
    for (double x = 0; x < size.x; x += 20) {
      canvas.drawLine(
        Offset(x, -10),
        Offset(x, 10),
        paint,
      );
    }

    // Draw net posts on sides
    final postPaint = Paint()
      ..color = const Color(0xFF424242) // Dark gray
      ..style = PaintingStyle.fill;

    // Left post
    canvas.drawRect(
      Rect.fromLTWH(0, -15, 8, 30),
      postPaint,
    );

    // Right post
    canvas.drawRect(
      Rect.fromLTWH(size.x - 8, -15, 8, 30),
      postPaint,
    );
  }
}
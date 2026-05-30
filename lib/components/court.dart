import 'dart:ui';
import 'package:flame/components.dart';
import '../screens/game_screen.dart';

class Court extends RectangleComponent with HasGameRef<TennisGame> {
  final Color color;

  Court({required this.color}) : super(
    paint: Paint()..color = color,
  );

  @override
  Future<void> onLoad() async {
    // Set court size to fill the screen
    size = gameRef.size;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0xFFFFFFFF) // White lines
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw outer boundary
    canvas.drawRect(
      Rect.fromLTWH(20, 20, size.x - 40, size.y - 40),
      paint,
    );

    // Draw service boxes (singles court lines)
    final courtWidth = size.x - 40;
    final courtHeight = size.y - 40;

    // Service line (horizontal line across middle section)
    canvas.drawLine(
      Offset(20, size.y / 2 - courtHeight / 4),
      Offset(size.x - 20, size.y / 2 - courtHeight / 4),
      paint,
    );

    canvas.drawLine(
      Offset(20, size.y / 2 + courtHeight / 4),
      Offset(size.x - 20, size.y / 2 + courtHeight / 4),
      paint,
    );

    // Singles sidelines (inner lines)
    final singlesWidth = courtWidth * 0.7;
    final sideMargin = (courtWidth - singlesWidth) / 2;

    canvas.drawLine(
      Offset(20 + sideMargin, 20),
      Offset(20 + sideMargin, size.y - 20),
      paint,
    );

    canvas.drawLine(
      Offset(size.x - 20 - sideMargin, 20),
      Offset(size.x - 20 - sideMargin, size.y - 20),
      paint,
    );
  }
}
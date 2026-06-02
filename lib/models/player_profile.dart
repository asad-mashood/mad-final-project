// models/player_profile.dart
class PlayerProfile {
  final String playerName;
  final int age;
  final String difficulty;
  final String racket;
  final String shoes;
  final String shirtStyle;

  PlayerProfile({
    required this.playerName,
    required this.age,
    required this.difficulty,
    required this.racket,
    required this.shoes,
    required this.shirtStyle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'playerName': playerName,
      'age': age,
      'difficulty': difficulty,
      'racket': racket,
      'shoes': shoes,
      'shirtStyle': shirtStyle,
    };
  }

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      playerName: map['playerName'] as String? ?? 'Player',
      age: map['age'] as int? ?? 18,
      difficulty: map['difficulty'] as String? ?? 'Medium',
      racket: map['racket'] as String? ?? 'Beginner Racket',
      shoes: map['shoes'] as String? ?? 'Basic Shoes',
      shirtStyle: map['shirtStyle'] as String? ?? 'Classic White',
    );
  }
}

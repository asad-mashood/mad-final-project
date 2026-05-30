class GameResult {
  final int? id;
  final int playerScore;
  final int aiScore;
  final String result; // "WIN" or "LOSS"
  final int createdAt; // Unix timestamp in milliseconds
  final String courtName;

  GameResult({
    this.id,
    required this.playerScore,
    required this.aiScore,
    required this.result,
    required this.createdAt,
    required this.courtName,
  });

  // Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerScore': playerScore,
      'aiScore': aiScore,
      'result': result,
      'createdAt': createdAt,
      'courtName': courtName,
    };
  }

  // Create from database Map
  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'] as int?,
      playerScore: map['playerScore'] as int,
      aiScore: map['aiScore'] as int,
      result: map['result'] as String,
      createdAt: map['createdAt'] as int,
      courtName: map['courtName'] as String,
    );
  }

  // Get relative time string (e.g., "5 min ago")
  String getTimeAgo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - createdAt;

    final seconds = difference ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    if (days > 0) {
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (hours > 0) {
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (minutes > 0) {
      return minutes == 1 ? '1 min ago' : '$minutes min ago';
    } else {
      return 'Just now';
    }
  }
}

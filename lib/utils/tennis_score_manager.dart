class TennisScoreManager {
  // Convert numerical score to tennis terminology
  static String getPointName(int points) {
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

  // Get the complete score announcement
  static String getScoreAnnouncement(int playerScore, int aiScore) {
    // Handle special cases first

    // Both at 40 or more (Deuce/Advantage situations)
    if (playerScore >= 3 && aiScore >= 3) {
      if (playerScore == aiScore) {
        return 'Deuce';
      } else if (playerScore > aiScore) {
        return 'Advantage Player';
      } else {
        return 'Advantage AI';
      }
    }

    // Game won
    if (playerScore >= 4 && playerScore - aiScore >= 2) {
      return 'Game Player';
    }
    if (aiScore >= 4 && aiScore - playerScore >= 2) {
      return 'Game AI';
    }

    // Regular scoring (0-3 points)
    final playerPointName = getPointName(playerScore);
    final aiPointName = getPointName(aiScore);

    // If scores are equal (but not 40-40)
    if (playerScore == aiScore && playerScore < 3) {
      return '$playerPointName All';
    }

    // Normal score announcement: Player score first, AI score second
    return '$playerPointName - $aiPointName';
  }

  // Shorter announcement for display
  static String getShortScore(int playerScore, int aiScore) {
    if (playerScore >= 3 && aiScore >= 3) {
      if (playerScore == aiScore) {
        return 'Deuce';
      } else if (playerScore > aiScore) {
        return 'Adv Player';
      } else {
        return 'Adv AI';
      }
    }

    if (playerScore >= 4 && playerScore - aiScore >= 2) {
      return 'Game Player!';
    }
    if (aiScore >= 4 && aiScore - playerScore >= 2) {
      return 'Game AI!';
    }

    return getScoreAnnouncement(playerScore, aiScore);
  }
}
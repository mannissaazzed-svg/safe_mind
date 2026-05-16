// score_manager.dart
// يحفظ سجل كامل لكل جلسة لعب (اسم اللعبة + سكور + تاريخ)

class GameScore {
  final String gameName;
  final int score;
  final DateTime playedAt;
  final String level; // optional: niveau joué

  GameScore({
    required this.gameName,
    required this.score,
    required this.playedAt,
    this.level = '',
  });
}

class ScoreManager {
  // قائمة كاملة بكل جلسات اللعب
  static final List<GameScore> history = [];

  /// أضف نتيجة جلسة لعب جديدة
  static void addScore({
    required String gameName,
    required int score,
    String level = '',
  }) {
    history.add(GameScore(
      gameName: gameName,
      score: score,
      playedAt: DateTime.now(),
      level: level,
    ));
  }

  /// احصل على آخر سكور للعبة معينة
  static int? lastScore(String gameName) {
    final games = history.where((g) => g.gameName == gameName).toList();
    if (games.isEmpty) return null;
    return games.last.score;
  }

  /// احصل على أعلى سكور للعبة معينة
  static int bestScore(String gameName) {
    final games = history.where((g) => g.gameName == gameName).toList();
    if (games.isEmpty) return 0;
    return games.map((g) => g.score).reduce((a, b) => a > b ? a : b);
  }

  /// مسح كل السجل
  static void reset() {
    history.clear();
  }
}
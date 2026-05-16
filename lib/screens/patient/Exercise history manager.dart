// exercise_history_manager.dart
// Suit les exercices physiques complétés par le patient

class ExerciceCompletion {
  final String nomExercice;
  final DateTime completedAt;

  ExerciceCompletion({
    required this.nomExercice,
    required this.completedAt,
  });
}

class ExerciseHistoryManager {
  // Liste complète de toutes les complétions (toutes dates confondues)
  static final List<ExerciceCompletion> history = [];

  /// Enregistre qu'un exercice a été complété maintenant
  static void addCompletion(String nomExercice) {
    history.add(ExerciceCompletion(
      nomExercice: nomExercice,
      completedAt: DateTime.now(),
    ));
  }

  /// Retourne la liste des exercices déjà faits AUJOURD'HUI
  static List<String> get doneTodayList {
    final today = DateTime.now();
    return history
        .where((c) =>
            c.completedAt.year == today.year &&
            c.completedAt.month == today.month &&
            c.completedAt.day == today.day)
        .map((c) => c.nomExercice)
        .toList();
  }

  /// Nombre total d'exercices complétés aujourd'hui
  static int get countToday => doneTodayList.length;

  /// Retourne toutes les complétions d'un jour précis
  static List<ExerciceCompletion> completionsForDate(DateTime date) {
    return history
        .where((c) =>
            c.completedAt.year == date.year &&
            c.completedAt.month == date.month &&
            c.completedAt.day == date.day)
        .toList();
  }

  /// Efface tout l'historique
  static void reset() => history.clear();
}
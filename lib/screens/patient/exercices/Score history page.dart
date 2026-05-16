// score_history_page.dart
// صفحة سجل النتائج — تُفتح في نهاية كل لعبة

import 'package:flutter/material.dart';
import 'package:safemind/screens/patient/score_manager.dart';

class ScoreHistoryPage extends StatelessWidget {
  /// إذا مررنا [highlightIndex]، يتم تمييز آخر نتيجة أضيفت للتو
  final int? highlightIndex;

  const ScoreHistoryPage({super.key, this.highlightIndex});

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}  $h:$mi';
  }

  IconData _gameIcon(String name) {
    switch (name) {
      case 'Math Game':   return Icons.calculate;
      case 'Intrus':      return Icons.search;
      case 'Puzzle':      return Icons.extension;
      case 'Mémoire':     return Icons.psychology;
      default:            return Icons.sports_esports;
    }
  }

  Color _gameColor(String name) {
    switch (name) {
      case 'Math Game':   return const Color(0xFF4ADE80);
      case 'Intrus':      return const Color(0xFF6C63FF);
      case 'Puzzle':      return const Color(0xFFF59E0B);
      case 'Mémoire':     return const Color(0xFF0EA5E9);
      default:            return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ScoreManager.history.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '🏆 Historique des scores',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (list.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Effacer le shistorique',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF16213E),
                    title: const Text('Confirmer',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('Effacer tout l\'historique ?',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () {
                          ScoreManager.reset();
                          Navigator.pop(context);
                          Navigator.pop(context); // retour
                        },
                        child: const Text('Effacer',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports_outlined,
                      size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Aucune partie jouée',
                      style: TextStyle(color: Colors.white38, fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                // ── Résumé global ──────────────────────────────
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBadge(
                          '${list.length}', 'Parties', Icons.videogame_asset),
                      _statBadge(
                          '${list.map((g) => g.score).fold(0, (a, b) => a + b)}',
                          'Score total',
                          Icons.star),
                      _statBadge(
                          '${list.map((g) => g.score).reduce((a, b) => a > b ? a : b)}',
                          'Meilleur',
                          Icons.emoji_events),
                    ],
                  ),
                ),

                // ── Liste ──────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final g = list[i];
                      // L'index 0 (premier en ordre inversé) = dernière entrée ajoutée
                      final isNew = (highlightIndex != null && i == 0);
                      final color = _gameColor(g.gameName);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isNew
                              ? color.withOpacity(0.15)
                              : const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isNew ? color : Colors.white10,
                            width: isNew ? 2 : 1,
                          ),
                          boxShadow: isNew
                              ? [
                                  BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 12)
                                ]
                              : [],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.4)),
                            ),
                            child: Icon(_gameIcon(g.gameName),
                                color: color, size: 24),
                          ),
                          title: Row(
                            children: [
                              Text(
                                g.gameName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (g.level.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(g.level,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                              if (isNew) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Nouveau !',
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ],
                          ),
                          subtitle: Text(
                            _formatDate(g.playedAt),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                          trailing: Text(
                            '⭐ ${g.score}',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ── Bouton Rejouer ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A6EA5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Retour aux jeux',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statBadge(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
// math_game.dart — avec sauvegarde du score et ouverture de l'historique
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:safemind/screens/patient/score_manager.dart';
import 'package:safemind/screens/patient/exercices/Score history page.dart';

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> with SingleTickerProviderStateMixin {
  final levels = [
    {"label": "Facile",   "color": Colors.green,  "max": 10,  "ops": ["+"]},
    {"label": "Moyen",    "color": Colors.orange, "max": 20,  "ops": ["+", "-"]},
    {"label": "Difficile","color": Colors.red,    "max": 50,  "ops": ["+", "-", "×"]},
    {"label": "Expert",   "color": Colors.purple, "max": 100, "ops": ["+", "-", "×", "÷"]},
  ];
  int levelIndex = 0;

  int a = 0, b = 0, correct = 0;
  String op = "+";
  List<int> options = [];
  int? selected;
  int score = 0;
  int streak = 0;
  int questionNum = 0;
  final int totalQuestions = 10;
  bool showResult = false;
  bool? isCorrect;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    generate();
  }

  void generate() {
    final level = levels[levelIndex];
    final max = level["max"] as int;
    final ops = level["ops"] as List<String>;
    final r = Random();

    op = ops[r.nextInt(ops.length)];
    a = r.nextInt(max) + 1;
    b = r.nextInt(max ~/ 2) + 1;

    if (op == "-" && b > a) { final tmp = a; a = b; b = tmp; }
    if (op == "÷") { b = r.nextInt(9) + 1; a = b * (r.nextInt(9) + 1); }

    correct = op == "+" ? a + b
            : op == "-" ? a - b
            : op == "×" ? a * b
            : a ~/ b;

    final Set<int> opts = {correct};
    while (opts.length < 4) { opts.add(correct + Random().nextInt(10) - 5); }
    options = opts.toList()..shuffle();
    selected = null; isCorrect = null;
    setState(() {});
  }

  void check(int val) {
    if (selected != null) return;
    setState(() {
      selected = val;
      isCorrect = val == correct;
      questionNum++;
      if (isCorrect!) {
        streak++;
        score += 10 + (streak > 2 ? 5 * streak : 0);
      } else {
        streak = 0;
        _shakeController.forward(from: 0);
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (questionNum >= totalQuestions) {
        // ── Sauvegarde du score ──────────────────────────────
        ScoreManager.addScore(
          gameName: 'Math Game',
          score: score,
          level: levels[levelIndex]["label"] as String,
        );
        setState(() => showResult = true);
      } else {
        generate();
      }
    });
  }

  Color cardColor(int val) {
    if (selected == null) return const Color(0xFF0F3460);
    if (val == correct) return Colors.green;
    if (val == selected) return Colors.red;
    return const Color(0xFF0F3460);
  }

  @override
  void dispose() { _shakeController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (showResult) return _resultScreen();
    final level = levels[levelIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text("➕ Jeu de Calcul", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text("⭐ $score",
                  style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF16213E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (level["color"] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: level["color"] as Color),
                    ),
                    child: Text(level["label"] as String,
                        style: TextStyle(color: level["color"] as Color, fontWeight: FontWeight.bold)),
                  ),
                  Text("$questionNum / $totalQuestions",
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  Row(children: [
                    const Text("🔥", style: TextStyle(fontSize: 18)),
                    Text(" $streak",
                        style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: questionNum / totalQuestions,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(level["color"] as Color),
              minHeight: 5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(levels.length, (i) {
                  final sel = i == levelIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() { levelIndex = i; score = 0; questionNum = 0; streak = 0; });
                      generate();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? (levels[i]["color"] as Color) : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(levels[i]["label"] as String,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.white54,
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value *
                    ((_shakeController.value * 10).round() % 2 == 0 ? 1 : -1), 0),
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Text("$a  $op  $b  = ?",
                      style: const TextStyle(
                          fontSize: 42, color: Colors.white,
                          fontWeight: FontWeight.bold, letterSpacing: 4)),
                ),
              ),
            ),
            if (streak >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  streak >= 5 ? "🔥 En feu ! +${5 * streak} bonus!" : "🔥 Série x$streak !",
                  style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.5,
                children: options.map((val) {
                  return GestureDetector(
                    onTap: () => check(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: cardColor(val),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected == null ? Colors.white12
                              : val == correct ? Colors.green
                              : val == selected ? Colors.red : Colors.white12,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (selected != null && val == correct)
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            if (selected != null && val == selected && val != correct)
                              const Icon(Icons.cancel, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text("$val",
                                style: const TextStyle(
                                    fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultScreen() {
    final percent = (score / (totalQuestions * 10) * 100).clamp(0, 100);
    final stars = percent >= 90 ? 3 : percent >= 60 ? 2 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${"★" * stars}${"☆" * (3 - stars)}",
                style: const TextStyle(fontSize: 40, color: Colors.amber)),
            const SizedBox(height: 16),
            const Text("Fin de partie !",
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Score : $score", style: const TextStyle(fontSize: 26, color: Colors.amber)),
            const SizedBox(height: 8),
            Text("Meilleure série : $streak 🔥",
                style: const TextStyle(fontSize: 18, color: Colors.orange)),
            const SizedBox(height: 40),
            // ── Bouton Voir l'historique ──────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A6EA5),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text("Voir l'historique",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScoreHistoryPage(highlightIndex: 0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (levelIndex < levels.length - 1)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                label: const Text("Niveau suivant",
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() { levelIndex++; score = 0; questionNum = 0; streak = 0; showResult = false; });
                  generate();
                },
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Rejouer", style: TextStyle(fontSize: 18, color: Colors.white)),
              onPressed: () {
                setState(() { score = 0; questionNum = 0; streak = 0; showResult = false; });
                generate();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("← Retour", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
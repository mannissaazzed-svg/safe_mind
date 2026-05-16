// intrus_game.dart — avec sauvegarde du score et ouverture de l'historique
import 'package:flutter/material.dart';
import 'score_manager.dart';
import 'package:safemind/screens/patient/exercices/Score history page.dart';

class IntrusGamePro extends StatefulWidget {
  const IntrusGamePro({super.key});

  @override
  State<IntrusGamePro> createState() => _IntrusGameProState();
}

class _IntrusGameProState extends State<IntrusGamePro> {
  final levels = [
    {"label": "Facile",   "color": Colors.green,  "questions": _facileQ},
    {"label": "Moyen",    "color": Colors.orange, "questions": _moyenQ},
    {"label": "Difficile","color": Colors.red,    "questions": _difficileQ},
    {"label": "Expert",   "color": Colors.purple, "questions": _expertQ},
  ];
  int levelIndex = 0;
  int questionIndex = 0;
  int? selected;
  int score = 0;
  int streak = 0;
  bool showResult = false;

  static const _facileQ = [
    {
      "question": "Lequel n'appartient pas ?",
      "items": [
        {"image": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=200", "label": "Pomme"},
        {"image": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=200", "label": "Banane"},
        {"image": "https://images.unsplash.com/photo-1596333522244-2db100a616bc?w=200", "label": "Raisin"},
        {"image": "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=200", "label": "Voiture 🚗"},
      ],
      "intruder": 3,
      "hint": "3 sont des fruits, 1 est un véhicule !",
    },
    {
      "question": "Lequel est l'intrus ?",
      "items": [
        {"image": "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200", "label": "Chat"},
        {"image": "https://images.unsplash.com/photo-1552053831-71594a27632d?w=200", "label": "Chien"},
        {"image": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=200", "label": "Lapin"},
        {"image": "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=200", "label": "Montagne ⛰️"},
      ],
      "intruder": 3,
      "hint": "3 sont des animaux domestiques !",
    },
  ];

  static const _moyenQ = [
    {
      "question": "Trouvez l'intrus !",
      "items": [
        {"image": "https://images.unsplash.com/photo-1509228627152-72ae9ae6848d?w=200", "label": "Maths"},
        {"image": "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=200", "label": "Livres"},
        {"image": "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=200", "label": "École"},
        {"image": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200", "label": "Nourriture 🍽️"},
      ],
      "intruder": 3,
      "hint": "3 concernent l'étude !",
    },
  ];

  static const _difficileQ = [
    {
      "question": "Lequel ne correspond pas ?",
      "items": [
        {"image": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200", "label": "Montagne"},
        {"image": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200", "label": "Plage"},
        {"image": "https://images.unsplash.com/photo-1448375240586-882707db888b?w=200", "label": "Forêt"},
        {"image": "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=200", "label": "Ski ❄️"},
      ],
      "intruder": 3,
      "hint": "Le ski est une activité, les autres sont des lieux !",
    },
  ];

  static const _expertQ = [
    {
      "question": "Trouvez l'intrus !",
      "items": [
        {"image": "https://images.unsplash.com/photo-1520522131217-068b02da8b07?w=200", "label": "Piano"},
        {"image": "https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=200", "label": "Guitare"},
        {"image": "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=200", "label": "Bâtiment"},
        {"image": "https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=200", "label": "Batterie"},
      ],
      "intruder": 2,
      "hint": "Le bâtiment n'est pas un instrument de musique !",
    },
  ];

  List get currentQuestions => levels[levelIndex]["questions"] as List;
  Map get currentQ => currentQuestions[questionIndex % currentQuestions.length] as Map;

  void answer(int index) {
    if (selected != null) return;
    setState(() {
      selected = index;
      if (index == currentQ["intruder"]) {
        streak++;
        score += 15 + (streak > 2 ? streak * 3 : 0);
      } else {
        streak = 0;
        score = (score - 5).clamp(0, 9999);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (questionIndex + 1 >= currentQuestions.length) {
        // ── Sauvegarde du score ──────────────────────────────
        ScoreManager.addScore(
          gameName: 'Intrus',
          score: score,
          level: levels[levelIndex]["label"] as String,
        );
        setState(() => showResult = true);
      } else {
        setState(() { questionIndex++; selected = null; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showResult) return _resultScreen();
    final level = levels[levelIndex];
    final items = currentQ["items"] as List;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text("🔍 Jeu de l'Intrus", style: TextStyle(color: Colors.white)),
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
                  Text("Q ${(questionIndex % currentQuestions.length) + 1}/${currentQuestions.length}",
                      style: const TextStyle(color: Colors.white70)),
                  Row(children: [
                    const Text("🔥"),
                    const SizedBox(width: 4),
                    Text("$streak",
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(levels.length, (i) {
                  final sel = i == levelIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        levelIndex = i; questionIndex = 0; selected = null;
                        score = 0; streak = 0; showResult = false;
                      });
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(currentQ["question"] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            if (selected != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text("💡 ${currentQ["hint"]}",
                    style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14),
                    textAlign: TextAlign.center),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i] as Map;
                final isIntruder = i == currentQ["intruder"];
                final isSelected = selected == i;

                Color borderColor = Colors.white12;
                if (selected != null) {
                  if (isIntruder) borderColor = Colors.green;
                  else if (isSelected) borderColor = Colors.red;
                }

                return GestureDetector(
                  onTap: () => answer(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(
                        children: [
                          Image.network(item["image"] as String,
                              fit: BoxFit.cover,
                              width: double.infinity, height: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF0F3460),
                                  child: const Icon(Icons.broken_image, color: Colors.white54, size: 40))),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.black54,
                              child: Text(item["label"] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (selected != null)
                            Container(
                              color: isIntruder ? Colors.green.withOpacity(0.2)
                                  : isSelected ? Colors.red.withOpacity(0.2) : Colors.transparent,
                              child: Center(
                                child: Icon(
                                  isIntruder ? Icons.check_circle : (isSelected ? Icons.cancel : null),
                                  color: isIntruder ? Colors.green : Colors.red,
                                  size: 45,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _resultScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const Text("Niveau terminé !",
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Score total : $score", style: const TextStyle(fontSize: 24, color: Colors.amber)),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                setState(() {
                  if (levelIndex < levels.length - 1) levelIndex++;
                  questionIndex = 0; selected = null; showResult = false;
                });
              },
              child: const Text("Suivant", style: TextStyle(color: Colors.black, fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Quitter", style: TextStyle(color: Colors.white54)),
            )
          ],
        ),
      ),
    );
  }
}
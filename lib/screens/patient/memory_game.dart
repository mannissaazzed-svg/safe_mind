import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with TickerProviderStateMixin {

  final levels = [
    {"label": "Facile",    "color": Colors.green,  "pairs": 4,  "cols": 2, "time": 60},
    {"label": "Moyen",     "color": Colors.orange, "pairs": 6,  "cols": 3, "time": 45},
    {"label": "Difficile", "color": Colors.red,    "pairs": 8,  "cols": 4, "time": 30},
    {"label": "Expert",    "color": Colors.purple, "pairs": 10, "cols": 4, "time": 20},
  ];
  int levelIndex = 0;

  final allImages = [
    "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200",
    "https://images.unsplash.com/photo-1550159930-40066082a4fc?w=200",
    "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=200",
    "https://images.unsplash.com/photo-1602491453631-e2a5ad90a131?w=200",
    "https://images.unsplash.com/photo-1504006833117-8886a355efbf?w=200",
    "https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?w=200",
    "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=200",
    "https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=200",
    "https://images.unsplash.com/photo-1559253664-ca249d4608c6?w=200",
  ];

  List<Map<String, dynamic>> cards = [];
  List<int> flipped = [];
  List<int> matched = [];
  int score = 0;
  int moves = 0;
  bool lock = false;
  int timeLeft = 60;
  Timer? timer;
  bool gameOver = false;
  bool won = false;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    final level = levels[levelIndex];
    final pairs = level["pairs"] as int;
    timeLeft = level["time"] as int;
    score = 0; moves = 0;
    flipped = []; matched = [];
    lock = false; gameOver = false; won = false;

    final selected = allImages.sublist(0, pairs);
    cards = [...selected, ...selected]
        .map((img) => {"image": img, "id": img}).toList();
    cards.shuffle(Random());

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) { t.cancel(); gameOver = true; }
      });
    });
    setState(() {});
  }

  void flip(int index) {
    if (lock || flipped.contains(index) || matched.contains(index)) return;
    setState(() => flipped.add(index));

    if (flipped.length == 2) {
      moves++;
      lock = true;
      if (cards[flipped[0]]["id"] == cards[flipped[1]]["id"]) {
        matched.addAll(flipped);
        score += 20;
        flipped = [];
        lock = false;
        if (matched.length == cards.length) {
          timer?.cancel();
          won = true;
          score += timeLeft * 2;
          setState(() {});
        }
      } else {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() { flipped = []; lock = false; score = (score - 2).clamp(0, 9999); });
        });
      }
    }
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final level = levels[levelIndex];
    final cols = level["cols"] as int;
    if (won || gameOver) return _resultScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text("🧠 Jeu de Mémoire", style: TextStyle(color: Colors.white)),
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
      body: Column(
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
                Row(children: [
                  Icon(Icons.timer, color: timeLeft <= 10 ? Colors.red : Colors.white70, size: 20),
                  const SizedBox(width: 4),
                  Text("$timeLeft s",
                      style: TextStyle(
                          color: timeLeft <= 10 ? Colors.red : Colors.white,
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                Text("🔄 $moves", style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(levels.length, (i) {
                final sel = i == levelIndex;
                return GestureDetector(
                  onTap: () { setState(() => levelIndex = i); startGame(); },
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final isFlipped = flipped.contains(i) || matched.contains(i);
                final isMatched = matched.contains(i);
                return GestureDetector(
                  onTap: () => flip(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isMatched ? Colors.green.withOpacity(0.3)
                          : isFlipped ? Colors.white10 : const Color(0xFF0F3460),
                      border: Border.all(
                        color: isMatched ? Colors.green
                            : isFlipped ? Colors.white30 : Colors.white10,
                        width: 2,
                      ),
                      boxShadow: isMatched
                          ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10)]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: isFlipped
                          ? Image.network(cards[i]["image"], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, color: Colors.white54))
                          : const Center(
                              child: Text("?",
                                  style: TextStyle(fontSize: 32, color: Colors.white54))),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            Text(won ? "🎉 Bravo !" : "⏰ Temps écoulé !",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                    color: won ? Colors.amber : Colors.red)),
            const SizedBox(height: 20),
            Text("Score : $score", style: const TextStyle(fontSize: 28, color: Colors.white)),
            const SizedBox(height: 8),
            Text("Mouvements : $moves", style: const TextStyle(fontSize: 18, color: Colors.white54)),
            const SizedBox(height: 40),
            if (won && levelIndex < levels.length - 1)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                label: const Text("Niveau suivant",
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                onPressed: () { setState(() => levelIndex++); startGame(); },
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Rejouer",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              onPressed: startGame,
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
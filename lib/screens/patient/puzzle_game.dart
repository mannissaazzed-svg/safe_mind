import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> {
  final levels = [
    {"label": "Facile", "color": Colors.green, "grid": 2, "time": 120},
    {"label": "Moyen", "color": Colors.orange, "grid": 3, "time": 90},
    {"label": "Difficile", "color": Colors.red, "grid": 4, "time": 60},
    {"label": "Expert", "color": Colors.purple, "grid": 5, "time": 45},
  ];
  int levelIndex = 0;

  final images = [
    "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600",
    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600",
    "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600",
    "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600",
  ];
  int imageIndex = 0;

  List<int> tiles = [];
  int? selectedTile;
  int moves = 0;
  int score = 0;
  int timeLeft = 120;
  bool gameOver = false;
  bool won = false;
  StreamSubscription? timerSub;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    final grid = levels[levelIndex]["grid"] as int;
    final total = grid * grid;
    timeLeft = levels[levelIndex]["time"] as int;
    moves = 0;
    score = 0;
    gameOver = false;
    won = false;
    selectedTile = null;

    tiles = List.generate(total, (i) => i)..shuffle(Random());

    timerSub?.cancel();
    timerSub = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted) return;
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          timerSub?.cancel();
          gameOver = true;
        }
      });
    });
    setState(() {});
  }

  void tapTile(int index) {
    if (gameOver || won) return;
    setState(() {
      if (selectedTile == null) {
        selectedTile = index;
      } else {
        final tmp = tiles[selectedTile!];
        tiles[selectedTile!] = tiles[index];
        tiles[index] = tmp;
        moves++;
        selectedTile = null;

        bool correct = true;
        for (int i = 0; i < tiles.length; i++) {
          if (tiles[i] != i) {
            correct = false;
            break;
          }
        }
        if (correct) {
          timerSub?.cancel();
          won = true;
          score = (timeLeft * 5) + (1000 - moves * 10).clamp(0, 1000);
        }
      }
    });
  }

  @override
  void dispose() {
    timerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (won || gameOver) return _resultScreen();

    final level = levels[levelIndex];
    final grid = level["grid"] as int;
    final size = MediaQuery.of(context).size.width - 40;
    final tileSize = size / grid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text("🧩 Puzzle", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text("⭐ $score",
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      // تم إضافة SingleChildScrollView لحل مشكلة التداخل (Overflow)
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
                        style: TextStyle(
                            color: level["color"] as Color,
                            fontWeight: FontWeight.bold)),
                  ),
                  Row(children: [
                    Icon(Icons.timer,
                        color: timeLeft <= 15 ? Colors.red : Colors.white70, size: 20),
                    const SizedBox(width: 4),
                    Text("$timeLeft s",
                        style: TextStyle(
                            color: timeLeft <= 15 ? Colors.red : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ]),
                  Text("🔄 $moves",
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                    onTap: () {
                      setState(() => levelIndex = i);
                      startGame();
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text("Aperçu :",
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(images[imageIndex],
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.white10,
                            child: const Icon(Icons.image, color: Colors.white54))),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => imageIndex = (imageIndex + 1) % images.length);
                      startGame();
                    },
                    icon: const Icon(Icons.shuffle, color: Colors.white54, size: 16),
                    label: const Text("Changer l'image",
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: List.generate(tiles.length, (index) {
                    final tileValue = tiles[index];
                    final row = tileValue ~/ grid;
                    final col = tileValue % grid;
                    final posRow = index ~/ grid;
                    final posCol = index % grid;
                    final isSelected = selectedTile == index;
                    final isCorrect = tileValue == index;

                    return Positioned(
                      left: posCol * tileSize,
                      top: posRow * tileSize,
                      child: GestureDetector(
                        onTap: () => tapTile(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: tileSize - 3,
                          height: tileSize - 3,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.amber
                                  : isCorrect
                                      ? Colors.green.withOpacity(0.6)
                                      : Colors.white12,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [const BoxShadow(color: Colors.amber, blurRadius: 10)]
                                : [],
                          ),
                          child: ClipRect(
                            child: OverflowBox(
                              maxWidth: tileSize * grid,
                              maxHeight: tileSize * grid,
                              alignment: Alignment(
                                -1 + (col * 2 / (grid - 1 == 0 ? 1 : grid - 1)),
                                -1 + (row * 2 / (grid - 1 == 0 ? 1 : grid - 1)),
                              ),
                              child: Image.network(
                                images[imageIndex],
                                width: tileSize * grid,
                                height: tileSize * grid,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.primaries[
                                          tileValue % Colors.primaries.length]
                                      .withOpacity(0.5),
                                  child: Center(
                                    child: Text("${tileValue + 1}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Appuyez sur une pièce, puis une autre pour les échanger !",
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
            Text(won ? "🎉 Puzzle résolu !" : "⏰ Temps écoulé !",
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: won ? Colors.amber : Colors.red)),
            const SizedBox(height: 20),
            if (won) ...[
              Text("Score : $score",
                  style: const TextStyle(fontSize: 28, color: Colors.white)),
              const SizedBox(height: 8),
              Text("Mouvements : $moves",
                  style: const TextStyle(fontSize: 18, color: Colors.white54)),
              const SizedBox(height: 8),
              Text("Temps restant : $timeLeft s ⏱️",
                  style: const TextStyle(fontSize: 16, color: Colors.white54)),
            ],
            const SizedBox(height: 40),
            if (won && levelIndex < levels.length - 1)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                label: const Text("Niveau suivant",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => levelIndex++);
                  startGame();
                },
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Rejouer",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              onPressed: startGame,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("← Retour",
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
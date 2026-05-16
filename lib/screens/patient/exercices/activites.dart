import 'package:flutter/material.dart';
import 'physique.dart';

// GAMES
import 'package:safemind/screens/patient/math_game.dart';
import 'package:safemind/screens/patient/intrus_game.dart';
import 'package:safemind/screens/patient/puzzle_game.dart';
import 'package:safemind/screens/patient/memory_game.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),

      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Activities",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff3A6EA5),
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // CATEGORY BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCard("Cognitive", Icons.psychology, 0),
              const SizedBox(width: 20),
              buildCard("Physical", Icons.directions_walk, 1),
            ],
          ),

          const SizedBox(height: 15),

          // CONTENT
          Expanded(
            child: selectedIndex == 0
                ? buildBrainGames()
                :  PhysicalPage(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // CATEGORY BUTTON
  Widget buildCard(String title, IconData icon, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff3A6EA5) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────
  // GAMES GRID
  Widget buildBrainGames() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [

            animatedGameCard(
              index: 0,
              title: "Jeu Intrus",
              imagePath: "assets/intrus.jpg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IntrusGamePro()),
                );
              },
            ),

            animatedGameCard(
              index: 1,
              title: "Memory Game",
              imagePath: "assets/memory.jpg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemoryGame()),
                );
              },
            ),

            animatedGameCard(
              index: 2,
              title: "Puzzle",
              imagePath: "assets/puzzle.jpg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PuzzleGame()),
                );
              },
            ),

            animatedGameCard(
              index: 3,
              title: "Math Game",
              imagePath: "assets/math.jpg",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MathGame()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────
  // ANIMATED CARD
  Widget animatedGameCard({
    required int index,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (0.1 * index),
        1.0,
        curve: Curves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 15,
                    left: 10,
                    right: 10,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
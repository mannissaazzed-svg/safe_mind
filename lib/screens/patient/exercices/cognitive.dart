import 'package:flutter/material.dart';
import 'package:safemind/screens/patient/intrus_game.dart';
import 'package:safemind/screens/patient/jeux.dart';
import 'package:safemind/screens/patient/puzzle_game.dart';
import 'package:safemind/screens/patient/math_game.dart';


class BrainGamesPage extends StatelessWidget {
  const BrainGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),
      appBar: AppBar(
        title: const Text('Exercices cérébraux'),
        backgroundColor: const Color(0xff6D8EA0),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildGameCard(
              context,
              'Math Game',
              'assets/math.png',
              const MathGame(),
            ),
            _buildGameCard(
              context,
              'Intrus',
              'assets/intrus.png',
              const IntrusGamePro(),
            ),
            _buildGameCard(
              context,
              'Puzzle',
              'assets/puzzle.png',
              const PuzzleGame(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, String title, String image, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            Container(
              alignment: Alignment.bottomCenter,
              color: Colors.black45,
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
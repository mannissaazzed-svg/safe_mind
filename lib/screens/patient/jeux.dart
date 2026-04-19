import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Stimulez votre esprit pour une meilleure mémoire !",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Il est recommandé de jouer à ces jeux pour activer le cerveau :",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildGameCard(
                      'Mots croisés',
                      'assets/crossword.png',
                      'https://play.google.com/store/apps/details?id=com.joyvendor.crosswordcode.android.en&utm_source=chatgpt.com',
                    ),
                    _buildGameCard(
                      'Ludo Classic',
                      'assets/ludo.png',
                      'https://play.google.com/store/apps/details?id=com.ludo.ludoclassic&utm_source=chatgpt.com',
                    ),
                    _buildGameCard(
                      'Échecs',
                      'assets/chess.png',
                      'https://lichess.org',
                    ),
                    _buildGameCard(
                      'Puzzle',
                      'assets/puzzle.png',
                      'https://apps.apple.com/pk/app/jigsaw-puzzles-epic/id796882776/?utm_source=chatgpt.com',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(String title, String imagePath, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Impossible d’ouvrir le lien : $url');
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(8),
              color: Colors.black45, 
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
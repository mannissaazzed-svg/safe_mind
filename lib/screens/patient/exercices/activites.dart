import 'package:flutter/material.dart';
import 'physique.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),
      appBar: AppBar(
        title: const Text("Activities"),
        backgroundColor: const Color(0xff3A6EA5),
      ),

      
      body: Column(
        children: [
          /// HEADER
          Container(
            height: 160,
            decoration: const BoxDecoration(
              
            ),
            child: const Center(
              child: Text(
                "Daily Activities Improve Health",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

         
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildCard(" Cognitive", Icons.psychology, 0),
                const SizedBox(width: 20),
                buildCard(" Physical", Icons.directions_walk, 1),
              ],
            ),
          ),

          const SizedBox(height: 10),

          
          Expanded(
            child: selectedIndex == 0
                ? buildBrainGames()
                : PhysicalPage(),
          ),
        ],
      ),
    );
  }

  
  Widget buildCard(String title, IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        width: 150,
        height: 80,
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color(0xff3A6EA5)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selectedIndex == index ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: selectedIndex == index ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget buildBrainGames() {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        gameCard(
          "Mots croisés",
          "assets/crossword.png",
          "https://play.google.com/store/apps/details?id=com.joyvendor.crosswordcode.android.en",
        ),
        gameCard(
          "Ludo Classic",
          "assets/ludo.png",
          "https://play.google.com/store/apps/details?id=com.ludo.ludoclassic",
        ),
        gameCard(
          "Échecs",
          "assets/chess.png",
          "https://lichess.org",
        ),
        gameCard(
          "Puzzle",
          "assets/puzzle.png",
          "https://apps.apple.com/pk/app/jigsaw-puzzles-epic/id796882776/",
        ),
      ],
    );
  }

  
  Widget gameCard(String title, String imagePath, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
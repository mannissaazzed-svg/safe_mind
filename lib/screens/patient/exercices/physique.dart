// physique.dart
import 'package:flutter/material.dart';
import 'detail_page.dart';

class Exercice {
  final String titre;
  final String image; // صورة واحدة فقط
  final List<String> etapes;
  final IconData icone;
  final Color couleur;

  const Exercice({
    required this.titre,
    required this.image,
    required this.etapes,
    required this.icone,
    required this.couleur,
  });
}

class PhysicalPage extends StatelessWidget {
  PhysicalPage({super.key});

  final List<Exercice> exercises = [
    Exercice(
      titre: 'Marche',
      icone: Icons.directions_walk,
      couleur: const Color(0xFF4ADE80),
      image: 'assets/marche.png',
      etapes: [
        'Mettez des chaussures confortables et antidérapantes.',
        'Commencez par marcher lentement pendant 2 minutes.',
        'Augmentez progressivement votre vitesse de marche.',
        'Marchez 10 à 20 minutes par jour.',
        'Terminez par une marche lente pour récupérer.',
      ],
    ),
    Exercice(
      titre: 'Équilibre',
      icone: Icons.self_improvement,
      couleur: const Color(0xFF6C63FF),
      image: 'assets/equilibre1.png',
      etapes: [
        'Tenez-vous debout près d\'un mur pour plus de sécurité.',
        'Levez un pied à quelques centimètres du sol.',
        'Maintenez la position pendant 10 secondes.',
        'Répétez 5 fois de chaque côté.',
        'Pratiquez chaque jour pour améliorer votre équilibre.',
      ],
    ),
    Exercice(
      titre: 'Étirements',
      icone: Icons.accessibility_new,
      couleur: const Color(0xFFF59E0B),
      image: 'assets/etirements.png',
      etapes: [
        'Asseyez-vous confortablement sur une chaise solide.',
        'Penchez doucement la tête vers l\'épaule droite.',
        'Maintenez 15 secondes, puis changez de côté.',
        'Étirez les bras vers le haut pendant 10 secondes.',
        'Répétez chaque étirement 3 fois.',
      ],
    ),
    Exercice(
      titre: 'Exercices des mains',
      icone: Icons.back_hand,
      couleur: const Color(0xFFEF4444),
      image: 'assets/mains.png',
      etapes: [
        'Posez les mains à plat sur une table.',
        'Fermez le poing doucement et maintenez 5 secondes.',
        'Ouvrez les doigts le plus possible.',
        'Faites des rotations du poignet 5 fois.',
        'Répétez l\'exercice 10 fois par main.',
      ],
    ),
    Exercice(
      titre: 'Respiration',
      icone: Icons.air,
      couleur: const Color(0xFF0EA5E9),
      image: 'assets/respiration.png',
      etapes: [
        'Asseyez-vous dans une position confortable.',
        'Inspirez lentement par le nez pendant 4 secondes.',
        'Retenez votre souffle pendant 2 secondes.',
        'Expirez doucement par la bouche pendant 6 secondes.',
        'Répétez cet exercice 5 à 10 fois.',
      ],
    ),
    Exercice(
      titre: 'Relaxation',
      icone: Icons.spa,
      couleur: const Color(0xFF8B5CF6),
      image: 'assets/relaxation.png',
      etapes: [
        'Allongez-vous ou asseyez-vous confortablement.',
        'Fermez les yeux et respirez profondément.',
        'Contractez puis relâchez chaque groupe musculaire.',
        'Commencez par les pieds, remontez jusqu\'à la tête.',
        'Restez 10 minutes dans cet état de détente totale.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailPage(exercice: ex)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ex.couleur.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: ex.couleur.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ex.icone, size: 30, color: ex.couleur),
                ),
                const SizedBox(height: 10),
                Text(
                  ex.titre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}
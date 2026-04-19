import 'package:flutter/material.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Adoptez une alimentation saine pour améliorer la mémoire et protéger le cerveau",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500
                  ),
                  ),
                  ),
                  Container(
                    height:220,
                    margin: const EdgeInsets.symmetric(horizontal:15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage("assets/healthy food.png"),
                        fit: BoxFit.cover,
                        ),
                        ),
                        ),
                        const SizedBox(height:15),
                        /// Two Cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            infoCard(
                              "assets/eau.png",
                              "Boire d'eau",
                              "6-8 Verres"),
                              infoCard(
                                "assets/marche.png",
                                "Marche",
                                "20 min / jour"
                                ),
                              ],
                            ),
                            const SizedBox(height:20),
                            const Padding(padding: EdgeInsets.all(10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Alimentation saine",
                                style: TextStyle(
                                  fontSize:20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                  ),
                                  ),
                                  ),
                                  ),
                                  GridView.count(
                                    crossAxisCount:2,
                                    shrinkWrap:true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      foodCard(
                                        "assets/legumes.png",
                                        "Légumes verts",
                                        "Améliore mémoire"
                                        ),
                                      foodCard(
                                          "assets/poissons.png",
                                          "Poisson",
                                          "Riche en Oméga 3"
                                          ),
                                      foodCard(
                                            "assets/noix.png",
                                            "Noix",
                                            "Protège cerveau"
                                            ),
                                      foodCard(
                                              "assets/fruits.png",
                                              "Fruits",
                                              "Améliore cognition"
                                              ),
                                      foodCard(
                                                "assets/huile olive.png",
                                                "Huile olive",
                                                "Anti inflammation"
                                                ),
                                      foodCard(
                                                  "assets/legumineuses.png",
                                                  "Légumineuses",
                                                  "Riches en fibres"
                                                  ),
                                        foodCard(
                                                    "assets/cereales.png",
                                                    "Céréales complètes",
                                                    "Énergie pour cerveau"
                                                    ),],),
                                                    const SizedBox(height:20),
                                                    const Padding(
                                                      padding: EdgeInsets.all(10),
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                          "Aliments à éviter",
                                                          style: TextStyle(
                                                            fontSize:20,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white),
                                                            ),),),
                                                            GridView.count(
                                                              crossAxisCount:2,
                                                              shrinkWrap:true,
                                                              physics: const NeverScrollableScrollPhysics(),
                                                              children: [
                                                                foodCard(
                                                                  "assets/fast_food.png",
                                                                  "Restauration rapide",
                                                                  "Augmente risque"
                                                                  ),
                                                                  foodCard(
                                                                    "assets/viandes rouges.png",
                                                                    "Viande rouge",
                                                                    "Mauvaise mémoire"
                                                                    ),
                                                                    foodCard("assets/sucreries.png",
                                                                    "Sucreries",
                                                                    "Fatigue cerveau"),
                                                                    foodCard(
                                                                      "assets/beurre.png","Beurre","Graisses saturées"),
                                                                      foodCard(
                                                                        "assets/fromages.png",
                                                                        "Fromage",
                                                                        "Trop de sel"
                                                                        ),
                                                                        ],
                                                                        ),
                                                                       const SizedBox(height:20),
                                                                       ],
                                                                       ),
                                                                       ),),);}



Widget infoCard(image,title,subtitle){
return Container(
height:120,
width:160,
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
),

child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [

Image.asset(
image,
height:40,
),

const SizedBox(height:5),

Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold
),
),

Text(subtitle)

],
),
);
}

/// food card

Widget foodCard(image,title,desc){
return Container(
margin: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
),

child: Column(
children: [

Expanded(
child: Padding(
padding: const EdgeInsets.all(10),
child: Image.asset(image),
),
),

Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold
),
),

Padding(
padding: const EdgeInsets.all(5),
child: Text(
desc,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize:12
),
),
)

],
),
);
}
}

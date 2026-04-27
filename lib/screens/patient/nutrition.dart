import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HealthAnalysis extends StatefulWidget {
  @override
  _HealthAnalysisState createState() => _HealthAnalysisState();
}

class _HealthAnalysisState extends State<HealthAnalysis> {
  
  double age = 65;
  int weight = 75;
  double pressure = 120;
  double sugar = 100;
  bool showResults = false;
  double cognitiveScore = 0.0;
  double motorScore = 0.0;
  double vascScore = 0.0;

  
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color primaryBlue = const Color(0xFF4DA3FF);
  final Color primaryGreen = const Color(0xFF42D392);
  final Color nutritionBg = const Color(0xff8EA7BF);

  
  late FixedExtentScrollController _weightController;

  @override
  void initState() {
    super.initState();
    
    _weightController = FixedExtentScrollController(initialItem: weight - 30);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculateMetrics() {
    setState(() {
      cognitiveScore = (sugar > 140 || sugar < 70) ? 0.45 : 0.90;
      motorScore = (weight > 90) ? 0.50 : 0.85;
      vascScore = (pressure > 140) ? 0.40 : 0.95;
      showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    //title: const Text("Health Analysis"),
    backgroundColor: primaryBlue,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
  ),
      backgroundColor: bgColor,
      body: Stack(
        children: [
         
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text("HEALTH ANALYSIS", 
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
                  const SizedBox(height: 25),
                  _buildAgePicker(),
                  const SizedBox(height: 20),
                  _buildWeightRuler(), 
                  const SizedBox(height: 20),
                  _buildVitalSliders(),
                  const SizedBox(height: 30),
                  _buildAnalyzeButton(),
                  if (showResults) _buildDiagnosticSection(),
                  const SizedBox(height: 150), 
                ],
              ),
            ),
          ),

         
          if (showResults)
            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.1,
              maxChildSize: 0.95,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: nutritionBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 15, bottom: 10),
                          width: 50, height: 6,
                          decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      _buildNutritionContent(),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

 
  Widget _buildNutritionContent() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "Adoptez une alimentation saine pour améliorer la mémoire et protéger le cerveau",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage("assets/healthy food.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            infoCard("assets/eau.png", "Boire d'eau", "6-8 Verres"),
            infoCard("assets/marche.png", "Marche", weight > 90 ? "15 min" : "20 min / jour"),
          ],
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Alimentation saine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        _buildHealthyGrid(),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Aliments à éviter", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        _buildAvoidGrid(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildHealthyGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        foodCard("assets/legumes.png", "Légumes verts", "Améliore mémoire"),
        foodCard("assets/poissons.png", "Poisson", "Riche en Oméga 3"),
        foodCard("assets/noix.png", "Noix", "Protège cerveau"),
        if (sugar < 140) foodCard("assets/fruits.png", "Fruits", "Améliore cognition"),
        foodCard("assets/huile olive.png", "Huile olive", "Anti inflammation"),
      ],
    );
  }

  Widget _buildAvoidGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        foodCard("assets/fast_food.png", "Restauration rapide", weight > 90 ? "DANGER: Obésité" : "Augmente risque"),
        foodCard("assets/sucreries.png", "Sucreries", sugar > 140 ? "DANGER: Glucose" : "Fatigue cerveau"),
        foodCard("assets/viandes rouges.png", "Viande rouge", "Mauvaise mémoire"),
        if (pressure > 140) foodCard("assets/fromages.png", "Fromage", "DANGER: Trop de sel"),
        foodCard("assets/beurre.png", "Beurre", "Graisses saturées"),
      ],
    );
  }

  
  Widget _buildWeightRuler() => _buildCard(
    child: Column(
      children: [
        _buildMetricInfo("Poids", "$weight", "kg"),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: _weightController,
              itemExtent: 45,
              onSelectedItemChanged: (index) => setState(() => weight = index + 30),
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  int val = index + 30;
                  return RotatedBox(
                    quarterTurns: 1,
                    child: Column(
                      children: [
                        Container(
                          width: 2,
                          height: val % 5 == 0 ? 35 : 18,
                          color: val == weight ? primaryBlue : Colors.grey.withOpacity(0.5),
                        ),
                        if (val % 5 == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text("$val", style: TextStyle(fontSize: 10, color: val == weight ? primaryBlue : Colors.black54)),
                          ),
                      ],
                    ),
                  );
                },
                childCount: 121,
              ),
            ),
          ),
        ),
        Icon(Icons.arrow_drop_up, color: primaryGreen, size: 30),
      ],
    ),
  );

  Widget infoCard(String image, String title, String subtitle) {
    return Container(
      height: 110, width: 155,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(image, height: 35, errorBuilder: (c,e,s) => const Icon(Icons.info)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget foodCard(String image, String title, String desc) {
    bool isDanger = desc.contains("DANGER");
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Image.asset(image, errorBuilder: (c,e,s) => const Icon(Icons.fastfood)))),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 5, right: 5),
          child: Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isDanger ? Colors.red : Colors.black54, fontWeight: isDanger ? FontWeight.bold : FontWeight.normal)),
        )
      ]),
    );
  }

  Widget _buildAgePicker() => _buildCard(
    child: Column(children: [
      _buildMetricInfo("Âge", "${age.toInt()}", "ans"),
      SizedBox(height: 100, child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: (age - 40).toInt()),
        itemExtent: 35, 
        onSelectedItemChanged: (i) => setState(() => age = (i + 40).toDouble()), 
        children: List.generate(61, (i) => Center(child: Text("${i + 40}", style: TextStyle(color: primaryBlue)))))),
    ]),
  );

  Widget _buildVitalSliders() => _buildCard(
    child: Column(children: [
      _buildVitalSlider("Pression", pressure, 80, 180, "mmHg"),
      const Divider(),
      _buildVitalSlider("Glucose", sugar, 60, 200, "mg/dL"),
    ]),
  );

  Widget _buildAnalyzeButton() => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _calculateMetrics,
    child: Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(colors: [primaryBlue, primaryGreen])),
      child: const Center(child: Text("ANALYSER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ),
  );

  Widget _buildDiagnosticSection() => Padding(
    padding: const EdgeInsets.only(top: 25),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _buildCircleStat("Cognition", cognitiveScore, primaryBlue),
      _buildCircleStat("Moteur", motorScore, primaryGreen),
      _buildCircleStat("Vasculaire", vascScore, Colors.orange),
    ]),
  );

  Widget _buildCircleStat(String label, double val, Color col) => Column(children: [
    Stack(alignment: Alignment.center, children: [
      SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: val, color: col, strokeWidth: 6, backgroundColor: Colors.white)),
      Text("${(val * 100).toInt()}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
    const SizedBox(height: 8),
    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
  ]);

  Widget _buildCard({required Widget child}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: child);

  Widget _buildMetricInfo(String t, String v, String u) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(color: Colors.grey)), Text("$v $u", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16))]);

  Widget _buildVitalSlider(String t, double v, double min, double max, String u) => Column(children: [
    _buildMetricInfo(t, v.toInt().toString(), u),
    Slider(value: v, min: min, max: max, activeColor: primaryGreen, onChanged: (val) => setState(() => t.contains("Pression") ? pressure = val : sugar = val)),
  ]);
}


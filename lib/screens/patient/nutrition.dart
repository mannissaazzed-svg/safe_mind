import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

class HealthAnalysis extends StatefulWidget {
  final String diseaseType;
  const HealthAnalysis({super.key, required this.diseaseType});

  @override
  _HealthAnalysisState createState() => _HealthAnalysisState();
}

class _HealthAnalysisState extends State<HealthAnalysis> {
  double age      = 65;
  int    weight   = 75;
  int    height   = 170;
  double pressure = 130;
  double sugar    = 100;

  bool hasDiabetes     = false;
  bool hasHTA          = false;
  bool hasDysphagie    = false;
  bool hasDenutrition  = false;
  bool hasConstipation = false;
  bool hasAVC          = false;
  bool hasDepression   = false;
  bool hasEpilepsie    = false;

  bool   showResults      = false;
  double cognitiveScore   = 0.0;
  double motorScore       = 0.0;
  double vascScore        = 0.0;
  double imc              = 0.0;
  String imcLabel         = '';
  bool   htaDetectedCache = false;
  int    selectedMealTab  = 0;

  final Color bgColor      = const Color(0xFFF8FAFC);
  final Color primaryBlue  = const Color(0xFF4DA3FF);
  final Color primaryGreen = const Color(0xFF42D392);
  final Color nutritionBg  = const Color(0xff8EA7BF);

  late FixedExtentScrollController _weightController;
  late FixedExtentScrollController _heightController;

  bool get _isParkinson          => widget.diseaseType == 'Parkinson';
  bool get _isAlzheimer          => widget.diseaseType == 'Alzheimer';
  bool get _isAlzheimerParkinson => widget.diseaseType == 'Alzheimer & Parkinson';

  @override
  void initState() {
    super.initState();
    _weightController = FixedExtentScrollController(initialItem: weight - 30);
    _heightController = FixedExtentScrollController(initialItem: height - 100);
  }

  @override
  void dispose() { _weightController.dispose(); _heightController.dispose(); super.dispose(); }

  
  String _getImcLabel(double v, AppLocalizations t) {
    if (v < 18.5) return t.nutrition_imc_underweight;
    if (v < 21)   return t.nutrition_imc_risk;
    if (v < 25)   return t.nutrition_imc_normal;
    if (v < 30)   return t.nutrition_imc_overweight;
    return t.nutrition_imc_obese;
  }

  Color _getImcColor(double v) {
    if (v < 18.5) return Colors.red;
    if (v < 21)   return Colors.orange;
    if (v < 25)   return primaryGreen;
    if (v < 30)   return Colors.orange;
    return Colors.red;
  }

  void _calculateMetrics(AppLocalizations t) {
    double h       = height / 100;
    double imcCalc = weight / (h * h);
    bool   diabetes = sugar > 140 || hasDiabetes;
    bool   hta      = pressure > 140 || hasHTA;

    setState(() {
      imc              = imcCalc;
      imcLabel         = _getImcLabel(imc, t);
      htaDetectedCache = hta;

      if (_isAlzheimerParkinson) {
        double neuro = 1.0;
        if (age >= 80) neuro -= 0.35; else if (age >= 70) neuro -= 0.18;
        if (diabetes) neuro -= 0.25; if (hta) neuro -= 0.25;
        if (imc >= 30) neuro -= 0.15; if (imc < 18.5) neuro -= 0.30;
        if (hasAVC) neuro -= 0.2; if (hasDepression) neuro -= 0.1;
        if (hasEpilepsie) neuro -= 0.15; if (hasConstipation) neuro -= 0.1;
        if (hasDysphagie) neuro -= 0.15;
        cognitiveScore = neuro.clamp(0.1, 1.0);
        double nutri = 1.0;
        if (hasDenutrition || imc < 18.5) nutri -= 0.5;
        if (imc < 21) nutri -= 0.2; if (hasDysphagie) nutri -= 0.3; if (hasConstipation) nutri -= 0.2;
        motorScore = nutri.clamp(0.1, 1.0);
        double vasc = 1.0;
        if (hta) vasc -= 0.4; if (diabetes) vasc -= 0.3; if (hasAVC) vasc -= 0.3; if (pressure < 90) vasc -= 0.2;
        vascScore = vasc.clamp(0.1, 1.0);
      } else if (_isAlzheimer) {
        double neuro = 1.0;
        if (age >= 80) neuro -= 0.3; else if (age >= 70) neuro -= 0.15;
        if (diabetes) neuro -= 0.25; if (hta) neuro -= 0.25; if (imc >= 30) neuro -= 0.15;
        if (imc < 18.5) neuro -= 0.25; if (hasAVC) neuro -= 0.2; if (hasDepression) neuro -= 0.1; if (hasEpilepsie) neuro -= 0.15;
        cognitiveScore = neuro.clamp(0.2, 1.0);
        double nutri = 1.0;
        if (hasDenutrition || imc < 18.5) nutri -= 0.5; if (imc < 21) nutri -= 0.2; if (hasDysphagie) nutri -= 0.3;
        motorScore = nutri.clamp(0.1, 1.0);
        double vasc = 1.0;
        if (hta) vasc -= 0.4; if (diabetes) vasc -= 0.3; if (hasAVC) vasc -= 0.3; if (pressure < 90) vasc -= 0.2;
        vascScore = vasc.clamp(0.1, 1.0);
      } else {
        double med = 1.0;
        if (hasConstipation) med -= 0.3; if (hasDysphagie) med -= 0.25; if (imc < 18.5) med -= 0.3; if (imc > 30) med -= 0.2; if (diabetes) med -= 0.2;
        cognitiveScore = med.clamp(0.1, 1.0);
        double mobility = 1.0;
        if (hasConstipation) mobility -= 0.4; if (hasDysphagie) mobility -= 0.2; if (imc < 18.5) mobility -= 0.2;
        motorScore = mobility.clamp(0.1, 1.0);
        double balance = 1.0;
        if (hasDenutrition) balance -= 0.4; if (hasDysphagie) balance -= 0.3;
        if (hta && diabetes) balance -= 0.4; else if (hta) balance -= 0.2; else if (diabetes) balance -= 0.2;
        vascScore = balance.clamp(0.1, 1.0);
      }
      showResults = true;
    });
  }

  Map<String, String> _getMealPlan() {
    if (_isAlzheimerParkinson) return _getAlzheimerParkinsonMeal();
    if (_isAlzheimer)          return _getAlzheimerMeal();
    return _getParkinsonMeal();
  }

  Map<String, String> _getAlzheimerParkinsonMeal() {
    if (hasDysphagie && (hasDenutrition || imc < 18.5)) return {'Petit déjeuner': 'Crème enrichie (lait entier + poudre de lait) + compote mixée lisse', 'Collation': 'Crème dessert + yaourt lisse', 'Déjeuner': 'Purée enrichie (beurre + fromage fondu) + viande finement mixée', 'Dîner': 'Soupe épaisse mixée + yaourt nature (texture lisse)'};
    if (hasDysphagie) return {'Petit déjeuner': 'Bouillie lisse (lait + avoine mixés) + compote mixée', 'Collation': 'Crème dessert', 'Déjeuner': 'Purée de légumes + viande finement mixée + yaourt', 'Dîner': 'Soupe mixée épaisse + crème dessert'};
    if (hasDenutrition || imc < 18.5) return {'Petit déjeuner': 'Lait enrichi (poudre de lait) + beurre + miel + pain mou', 'Collation': 'Yaourt enrichi + biscuits mous', 'Déjeuner': 'Purée enrichie (beurre) + viande hachée + légumes bien cuits', 'Dîner': 'Soupe mixée + fromage fondu + yaourt nature'};
    if (hasDiabetes && hasHTA) return {'Petit déjeuner': 'Pain complet + fromage frais (sans sel) + thé sans sucre', 'Collation': 'Yaourt nature', 'Déjeuner': 'Poisson grillé + légumes vapeur (sans sel) + riz complet', 'Dîner': 'Soupe légumes (sans sel) + poulet + légumes verts'};
    if (hasDiabetes) return {'Petit déjeuner': 'Pain complet + fromage + thé sans sucre', 'Collation': 'Fruit frais (IG bas)', 'Déjeuner': 'Poisson + légumes + riz complet', 'Dîner': 'Soupe légumes + purée + yaourt nature'};
    if (hasHTA) return {'Petit déjeuner': 'Lait écrémé + pain complet + miel', 'Collation': 'Fruit frais + yaourt nature', 'Déjeuner': 'Purée légumes + poulet haché + légumes vapeur (sans sel)', 'Dîner': 'Soupe mixée (sans sel) + yaourt'};
    return {'Petit déjeuner': 'Lait + pain + miel (faible en protéines le matin)', 'Collation': 'Yaourt nature', 'Déjeuner': 'Purée + viande hachée (protéines au déjeuner)', 'Dîner': 'Soupe mixée + yaourt'};
  }

  Map<String, String> _getAlzheimerMeal() {
    if (hasAVC) return {'Petit déjeuner': 'Pain complet + huile d\'olive + lait demi-écrémé', 'Collation': 'Amandes + fruit frais', 'Déjeuner': 'Poisson + légumes + riz complet', 'Dîner': 'Soupe + légumes verts'};
    if (hasDepression) return {'Petit déjeuner': 'Lait + chocolat noir + pain complet', 'Collation': 'Banane + noix', 'Déjeuner': 'Poisson + légumes variés', 'Dîner': 'Soupe + œuf + fruit'};
    if (hasEpilepsie) return {'Petit déjeuner': 'Lait + pain complet + fruit', 'Collation': 'Yaourt nature + amandes', 'Déjeuner': 'Viande + légumes bien cuits', 'Dîner': 'Soupe + yaourt + fruit'};
    if (hasDysphagie && (hasDenutrition || imc < 18.5)) return {'Petit déjeuner': 'Bouillie enrichie (lait entier + poudre de lait) + compote mixée + lait chaud', 'Collation': 'Crème dessert + yaourt lisse', 'Déjeuner': 'Purée de légumes enrichie + viande mixée + fromage fondu', 'Dîner': 'Soupe mixée épaisse + crème dessert + yaourt'};
    if (hasDysphagie) return {'Petit déjeuner': 'Bouillie enrichie + compote mixée + lait chaud', 'Collation': 'Crème dessert', 'Déjeuner': 'Purée de légumes + viande mixée + yaourt', 'Dîner': 'Soupe mixée + fromage mou + crème dessert'};
    if (hasDenutrition || imc < 18.5) return {'Petit déjeuner': 'Lait entier enrichi + beurre + confiture + pain complet + banane', 'Collation': 'Yaourt enrichi + biscuits', 'Déjeuner': 'Viande hachée + purée enrichie + légumes bien cuits + yaourt', 'Dîner': 'Omelette (2 œufs) + fromage + pain complet + fruit mou'};
    if (hasDiabetes && hasHTA) return {'Petit déjeuner': 'Pain complet + œuf poché + thé sans sucre (sans sel)', 'Collation': 'Fruit frais (IG bas)', 'Déjeuner': 'Poisson grillé + légumes vapeur (sans sel) + quinoa', 'Dîner': 'Soupe légumes (sans sel) + poulet + salade verte'};
    if (hasDiabetes) return {'Petit déjeuner': 'Pain complet + fromage + thé sans sucre', 'Collation': 'Fruit frais (IG bas)', 'Déjeuner': 'Viande blanche + légumes + semoule complète', 'Dîner': 'Soupe + légumes + poisson'};
    if (hasHTA) return {'Petit déjeuner': 'Lait écrémé + pain complet', 'Collation': 'Fruit + yaourt nature', 'Déjeuner': 'Poulet + légumes vapeur', 'Dîner': 'Potage + yaourt + fruit'};
    return {'Petit déjeuner': 'Lait + pain complet + huile d\'olive + dattes', 'Collation': 'Fruit frais + amandes', 'Déjeuner': 'Poisson + légumes + riz', 'Dîner': 'Yaourt + fruit / Soupe + œuf'};
  }

  Map<String, String> _getParkinsonMeal() {
    if (hasDysphagie && hasDenutrition) return {'Petit déjeuner': 'Crème enrichie (lait entier + poudre de lait) + compote mixée lisse', 'Collation': 'Crème dessert + yaourt lisse', 'Déjeuner': 'Purée enrichie (beurre + fromage fondu) + viande finement mixée', 'Dîner': 'Soupe épaisse mixée + yaourt nature'};
    if (hasDysphagie && hasHTA) return {'Petit déjeuner': 'Bouillie sans sel (lait + flocons d\'avoine mixés) + compote', 'Collation': 'Yaourt lisse', 'Déjeuner': 'Purée de légumes (sans sel) + poisson mixé', 'Dîner': 'Soupe mixée sans sel (légumes frais)'};
    if (hasDysphagie) return {'Petit déjeuner': 'Bouillie lisse (lait + avoine) + compote mixée', 'Collation': 'Crème dessert', 'Déjeuner': 'Purée de légumes + viande finement mixée + yaourt', 'Dîner': 'Soupe mixée épaisse + crème dessert'};
    if (hasDenutrition || imc < 18.5) return {'Petit déjeuner': 'Lait enrichi (poudre de lait) + beurre + confiture + banane', 'Collation': 'Yaourt + biscuits', 'Déjeuner': 'Viande hachée + purée enrichie (beurre) + légumes bien cuits', 'Dîner': 'Omelette (2 œufs) + fromage + pain + yaourt'};
    if (hasDiabetes && hasHTA) return {'Petit déjeuner': 'Pain complet + fromage frais (sans sel) + thé sans sucre', 'Collation': 'Yaourt nature', 'Déjeuner': 'Poisson grillé + légumes vapeur (sans sel) + quinoa', 'Dîner': 'Soupe légumes (sans sel) + poulet + légumes verts'};
    if (hasDiabetes) return {'Petit déjeuner': 'Pain complet + œuf poché + thé sans sucre', 'Collation': 'Yaourt nature', 'Déjeuner': 'Poisson grillé + quinoa + légumes verts', 'Dîner': 'Soupe légumes + poulet grillé + légumes'};
    if (hasHTA) return {'Petit déjeuner': 'Pain complet + fromage frais (faible sel)', 'Collation': 'Fruits frais', 'Déjeuner': 'Poisson grillé + légumes vapeur (sans sel ajouté)', 'Dîner': 'Salade verte + viande blanche + fruits frais'};
    if (hasConstipation) return {'Petit déjeuner': 'Flocons d\'avoine + fruit (pruneaux ou orange) + eau', 'Collation': 'Pruneaux + yaourt probiotique', 'Déjeuner': 'Lentilles + légumes variés + pain complet', 'Dîner': 'Soupe légumes + yaourt probiotique + pruneaux'};
    return {'Petit déjeuner': 'Lait + pain complet + miel + fruit (faible en protéines le matin)', 'Collation': 'Fruit + amandes', 'Déjeuner': 'Poulet grillé + riz complet + légumes vapeur', 'Dîner': 'Soupe légumes + salade + yaourt + amandes'};
  }

  
  Map<String, List<Map<String, String>>> _getMealFoodsByProfile() {
    
    return {
      'Petit déjeuner': [{'asset': 'assets/lait_enrichi.jpg', 'title': 'Lait', 'desc': 'Calcium'}, {'asset': 'assets/pain_complet.jpg', 'title': 'Pain', 'desc': 'Énergie'}],
      'Collation': [{'asset': 'assets/yaourt_nature.jpg', 'title': 'Yaourt', 'desc': 'Probiotiques'}],
      'Déjeuner': [{'asset': 'assets/poissons.png', 'title': 'Poisson', 'desc': 'Oméga 3'}, {'asset': 'assets/legumes.jpg', 'title': 'Légumes', 'desc': 'Vitamines'}],
      'Dîner': [{'asset': 'assets/soupe.jpg', 'title': 'Soupe', 'desc': 'Hydratation'}],
    };
  }

  List<Map<String, String>> _getAvoidFoods(AppLocalizations t) {
    List<Map<String, String>> avoid = [
      {'asset': 'assets/fast_food.png',   'title': t.nutrition_fast_food,    'desc': t.nutrition_fast_food_desc},
      {'asset': 'assets/sucreries.png',   'title': t.nutrition_sweets,       'desc': t.nutrition_sweets_desc},
      {'asset': 'assets/fritures.png',    'title': t.nutrition_fried,        'desc': t.nutrition_fried_desc},
      {'asset': 'assets/Charcuterie.jpg', 'title': t.nutrition_charcuterie,  'desc': t.nutrition_charcuterie_desc},
    ];
    if (hasHTA) avoid.add({'asset': 'assets/sel.png', 'title': t.nutrition_salt, 'desc': t.nutrition_salt_desc});
    if (_isParkinson || _isAlzheimerParkinson) avoid.add({'asset': 'assets/proteine_matin.png', 'title': t.nutrition_protein_morning, 'desc': t.nutrition_protein_morning_desc});
    return avoid;
  }

  
  List<Map<String, String>> _getTips() {
    
    List<Map<String, String>> tips = [];
    if (_isAlzheimerParkinson) {
      tips.add({'icon': '💊', 'title': 'Point critique : Lévodopa/protéines', 'desc': 'Éviter protéines le matin. Réserver protéines au déjeuner et dîner.'});
      tips.add({'icon': '🧠', 'title': 'Double maladie neurologique', 'desc': 'Apport protéique contrôlé + texture adaptée.'});
      if (hasDysphagie) tips.add({'icon': '🥣', 'title': 'DANGER: Dysphagie', 'desc': 'Texture lisse obligatoire. Risque double de fausse route.'});
      if (hasDenutrition || imc < 18.5) tips.add({'icon': '⚠️', 'title': 'Dénutrition — Urgence', 'desc': 'Apport calorique ↑. Enrichissement : lait enrichi, beurre, fromage.'});
      if (hasConstipation) tips.add({'icon': '🌾', 'title': 'Constipation', 'desc': 'Fibres ↑↑ : avoine, lentilles, pruneaux. Eau 6–8 verres/j.'});
    } else if (_isAlzheimer) {
      if (hasAVC) tips.add({'icon': '🫀', 'title': 'Priorité : AVC', 'desc': 'Régime cardio-protecteur. Oméga 3, anti-cholestérol.'});
      if (hasDepression) tips.add({'icon': '🧠', 'title': 'Priorité : Dépression', 'desc': 'Magnésium ↑, oméga 3 ↑, apport énergétique équilibré.'});
      if (hasEpilepsie) tips.add({'icon': '⚡', 'title': 'Priorité : Épilepsie', 'desc': 'Éviter hypoglycémie. Repas réguliers obligatoires.'});
      if (hasDysphagie) tips.add({'icon': '🥣', 'title': 'DANGER: Dysphagie', 'desc': 'Texture lisse obligatoire. Risque de fausse route.'});
      tips.add({'icon': '🧠', 'title': 'Alzheimer', 'desc': 'Oméga 3, antioxydants, hydratation. Régime méditerranéen.'});
    } else {
      tips.add({'icon': '💊', 'title': 'Interaction Lévodopa/protéines', 'desc': 'Éviter protéines le matin. Réserver à midi et au dîner.'});
      if (hasDysphagie) tips.add({'icon': '🥣', 'title': 'DANGER: Dysphagie', 'desc': 'Texture lisse obligatoire. Risque de fausse route élevé.'});
      if (hasDenutrition || imc < 18.5) tips.add({'icon': '⚠️', 'title': 'Dénutrition', 'desc': 'Apport calorique ↑. Enrichissement : lait enrichi, purée enrichie.'});
      if (hasConstipation) tips.add({'icon': '🌾', 'title': 'Constipation (très fréquent Parkinson)', 'desc': 'Fibres ↑↑ + hydratation ↑↑. Pruneaux, lentilles, avoine.'});
      tips.add({'icon': '💧', 'title': 'Hydratation', 'desc': 'Eau 1,5–2L/j. Aide constipation et efficacité médicaments.'});
    }
    return tips;
  }

  
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text('${t.nutrition_title} • ${widget.diseaseType}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: bgColor,
      body: Stack(children: [
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(children: [
            const SizedBox(height: 10),
            Text(t.nutrition_analysis, style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
            const SizedBox(height: 25),
            _buildAgePicker(t),
            const SizedBox(height: 20),
            Row(children: [Expanded(child: _buildWeightRuler(t)), const SizedBox(width: 15), Expanded(child: _buildHeightRuler(t))]),
            const SizedBox(height: 20),
            _buildVitalSliders(t),
            const SizedBox(height: 20),
            _buildComorbiditiesSection(t),
            const SizedBox(height: 30),
            _buildAnalyzeButton(t),
            if (showResults) _buildDiagnosticSection(t),
            const SizedBox(height: 160),
          ]),
        )),
        if (showResults)
          DraggableScrollableSheet(
            initialChildSize: 0.15, minChildSize: 0.1, maxChildSize: 0.95, snap: true,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(color: nutritionBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)]),
              child: ListView(controller: scrollController, padding: EdgeInsets.zero, children: [
                Center(child: Container(margin: const EdgeInsets.only(top: 15, bottom: 10), width: 50, height: 6, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)))),
                _buildNutritionContent(t),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildNutritionContent(AppLocalizations t) {
    String subtitle = _isAlzheimerParkinson ? t.nutrition_subtitle_both : _isAlzheimer ? t.nutrition_subtitle_alzheimer : t.nutrition_subtitle_parkinson;
    final tabs  = ['Petit déjeuner', 'Collation', 'Déjeuner', 'Dîner'];
    final tabLabels = [t.nutrition_tab_morning, t.nutrition_tab_snack, t.nutrition_tab_lunch, t.nutrition_tab_dinner];
    final icons = [Icons.wb_sunny_outlined, Icons.coffee_outlined, Icons.wb_cloudy_outlined, Icons.nightlight_round];
    final mealFoods = _getMealFoodsByProfile();
    final selectedFoods = mealFoods[tabs[selectedMealTab]] ?? [];

    return Column(children: [
      Padding(padding: const EdgeInsets.all(15),
        child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500))),
      Container(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: _getImcColor(imc).withOpacity(0.15), borderRadius: BorderRadius.circular(15), border: Border.all(color: _getImcColor(imc), width: 1.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.monitor_weight_outlined, color: _getImcColor(imc)),
          const SizedBox(width: 8),
          Text('${t.nutrition_imc_label}: ${imc.toStringAsFixed(1)} — $imcLabel', style: TextStyle(color: _getImcColor(imc), fontWeight: FontWeight.bold, fontSize: 15)),
        ])),
      const SizedBox(height: 10),
      Container(height: 180, margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage("assets/healthy food.png"), fit: BoxFit.cover))),
      const SizedBox(height: 15),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _infoCard("assets/eau.png", t.nutrition_water, t.nutrition_water_desc),
        _infoCard("assets/marche.png", t.nutrition_walk, weight > 90 ? t.nutrition_walk_desc_heavy : t.nutrition_walk_desc_normal),
      ]),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft, child: Text(t.nutrition_tips_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
      const SizedBox(height: 10),
      _buildTipsSection(),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft, child: Text(t.nutrition_meal_plan_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
      const SizedBox(height: 10),
      // Tabs
      Container(margin: const EdgeInsets.symmetric(horizontal: 15), padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(children: List.generate(tabs.length, (i) {
          bool selected = selectedMealTab == i;
          return Expanded(child: GestureDetector(onTap: () => setState(() => selectedMealTab = i),
            child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(15),
                boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)] : []),
              child: Column(children: [
                Icon(icons[i], color: selected ? primaryBlue : Colors.white70, size: 20),
                const SizedBox(height: 3),
                Text(tabLabels[i], style: TextStyle(fontSize: 10, color: selected ? primaryBlue : Colors.white70, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ]))));
        }))),
      const SizedBox(height: 15),
      Container(margin: const EdgeInsets.symmetric(horizontal: 15), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
        child: Text(_getMealPlan()[tabs[selectedMealTab]] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1,
          children: selectedFoods.map((f) => _foodCard(f['asset']!, f['title']!, f['desc']!)).toList())),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft, child: Text(t.nutrition_avoid_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.0,
        children: _getAvoidFoods(t).map((f) => _foodCard(f['asset']!, f['title']!, f['desc']!)).toList()),
      const SizedBox(height: 50),
    ]);
  }

  Widget _buildDiagnosticSection(AppLocalizations t) {
    double imcCircleVal = (imc >= 21 && imc <= 25) ? 1.0 : (imc < 21) ? (imc / 21).clamp(0.1, 1.0) : (1.0 - ((imc - 25) / 20)).clamp(0.1, 1.0);
    final nutritionScore = _isAlzheimer ? (cognitiveScore * 0.5 + motorScore * 0.5).clamp(0.0, 1.0) : (cognitiveScore * 0.4 + motorScore * 0.3 + vascScore * 0.3).clamp(0.0, 1.0);

    Color imcStatusColor = (imc >= 21 && imc <= 25) ? Colors.green : (imc >= 18.5 && imc < 21) || (imc >= 25 && imc < 30) ? Colors.orange : Colors.red;
    Color nutColor = nutritionScore >= 0.75 ? Colors.green : nutritionScore >= 0.50 ? Colors.orange : Colors.red;
    String nutLabel = nutritionScore >= 0.75 ? t.nutrition_score_good : nutritionScore >= 0.50 ? t.nutrition_score_medium : t.nutrition_score_low;

    return Padding(padding: const EdgeInsets.only(top: 25), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildCircle(imcCircleVal, imcStatusColor, imc.toStringAsFixed(1), 'kg/m²', Icons.monitor_weight_outlined, t.nutrition_imc_circle_label, '${weight}kg / ${height}cm', imcLabel),
        _buildCircle(nutritionScore, nutColor, '${(nutritionScore * 100).toInt()}%', 'score', Icons.health_and_safety_outlined, t.nutrition_score_circle_label, t.nutrition_score_balanced, nutLabel),
      ]),
    ]));
  }

  Widget _buildCircle(double val, Color color, String main, String sub, IconData icon, String label, String extra, String badge) {
    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 90, height: 90, child: CircularProgressIndicator(value: val, color: color, strokeWidth: 9, backgroundColor: Colors.grey.withOpacity(0.15))),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16), const SizedBox(height: 2),
          Text(main, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
        ]),
      ]),
      const SizedBox(height: 8),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(extra, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.5))),
        child: Text(badge, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildComorbiditiesSection(AppLocalizations t) => _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t.nutrition_comorbidities, style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 15)),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [
      _chip(t.nutrition_diabetes,    hasDiabetes,     (v) => setState(() => hasDiabetes     = v)),
      _chip(t.nutrition_hta,         hasHTA,          (v) => setState(() => hasHTA          = v)),
      _chip(t.nutrition_dysphagia,   hasDysphagie,    (v) => setState(() => hasDysphagie    = v)),
      _chip(t.nutrition_malnutrition,hasDenutrition,  (v) => setState(() => hasDenutrition  = v)),
      _chip(t.nutrition_constipation,hasConstipation, (v) => setState(() => hasConstipation = v)),
      if (_isAlzheimer || _isAlzheimerParkinson) ...[
        _chip(t.nutrition_avc,       hasAVC,          (v) => setState(() => hasAVC          = v)),
        _chip(t.nutrition_depression,hasDepression,   (v) => setState(() => hasDepression   = v)),
        _chip(t.nutrition_epilepsy,  hasEpilepsie,    (v) => setState(() => hasEpilepsie    = v)),
      ],
    ]),
  ]));

  Widget _chip(String label, bool selected, Function(bool) onChanged) => GestureDetector(
    onTap: () => onChanged(!selected),
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: selected ? primaryBlue : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? primaryBlue : Colors.grey.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13))));

  Widget _buildTipsSection() {
    final tips = _getTips();
    return Column(children: tips.map((tip) {
      bool isDanger = tip['title']!.contains('DANGER') || tip['desc']!.contains('obligatoire');
      return Container(margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDanger ? Colors.red.withOpacity(0.12) : Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(15), border: Border.all(color: isDanger ? Colors.red.withOpacity(0.5) : Colors.white30)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip['icon']!, style: const TextStyle(fontSize: 22)), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tip['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: isDanger ? Colors.red[200] : Colors.white, fontSize: 14)),
            const SizedBox(height: 3),
            Text(tip['desc']!, style: TextStyle(color: isDanger ? Colors.red[100] : Colors.white.withOpacity(0.85), fontSize: 13)),
          ])),
        ]));
    }).toList());
  }

  Widget _buildAnalyzeButton(AppLocalizations t) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => _calculateMetrics(t),
    child: Container(width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(colors: [primaryBlue, primaryGreen])),
      child: Center(child: Text(t.nutrition_analyze_btn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))));

  Widget _buildAgePicker(AppLocalizations t) => _buildCard(child: Column(children: [
    _metricInfo(t.nutrition_age, '${age.toInt()}', t.nutrition_age_unit),
    SizedBox(height: 100, child: CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: (age - 40).toInt()), itemExtent: 35,
      onSelectedItemChanged: (i) => setState(() => age = (i + 40).toDouble()),
      children: List.generate(61, (i) => Center(child: Text('${i + 40}', style: TextStyle(color: primaryBlue)))))),
  ]));

  Widget _buildWeightRuler(AppLocalizations t) => _buildCard(child: Column(children: [
    _metricInfo(t.nutrition_weight, '$weight', t.nutrition_weight_unit), const SizedBox(height: 10),
    SizedBox(height: 80, child: RotatedBox(quarterTurns: -1, child: ListWheelScrollView.useDelegate(
      controller: _weightController, itemExtent: 45,
      onSelectedItemChanged: (i) => setState(() => weight = i + 30),
      childDelegate: ListWheelChildBuilderDelegate(childCount: 121, builder: (ctx, index) {
        int val = index + 30;
        return RotatedBox(quarterTurns: 1, child: Column(children: [
          Container(width: 2, height: val % 5 == 0 ? 35 : 18, color: val == weight ? primaryBlue : Colors.grey.withOpacity(0.5)),
          if (val % 5 == 0) Padding(padding: const EdgeInsets.only(top: 5), child: Text('$val', style: TextStyle(fontSize: 10, color: val == weight ? primaryBlue : Colors.black54))),
        ]));
      })))),
    Icon(Icons.arrow_drop_up, color: primaryGreen, size: 30),
  ]));

  Widget _buildHeightRuler(AppLocalizations t) => _buildCard(child: Column(children: [
    _metricInfo(t.nutrition_height, '$height', t.nutrition_height_unit), const SizedBox(height: 10),
    SizedBox(height: 80, child: RotatedBox(quarterTurns: -1, child: ListWheelScrollView.useDelegate(
      controller: _heightController, itemExtent: 45,
      onSelectedItemChanged: (i) => setState(() => height = i + 100),
      childDelegate: ListWheelChildBuilderDelegate(childCount: 121, builder: (ctx, index) {
        int val = index + 100;
        return RotatedBox(quarterTurns: 1, child: Column(children: [
          Container(width: 2, height: val % 5 == 0 ? 35 : 18, color: val == height ? primaryGreen : Colors.grey.withOpacity(0.5)),
          if (val % 5 == 0) Padding(padding: const EdgeInsets.only(top: 5), child: Text('$val', style: TextStyle(fontSize: 10, color: val == height ? primaryGreen : Colors.black54))),
        ]));
      })))),
    Icon(Icons.arrow_drop_up, color: primaryBlue, size: 30),
  ]));

  Widget _buildVitalSliders(AppLocalizations t) => _buildCard(child: Column(children: [
    _vitalSlider(t.nutrition_pressure, pressure, 80, 180, t.nutrition_pressure_unit, t, true),
    const Divider(),
    _vitalSlider(t.nutrition_glucose, sugar, 60, 200, t.nutrition_glucose_unit, t, false),
  ]));

  Widget _vitalSlider(String title, double val, double min, double max, String unit, AppLocalizations t, bool isPression) {
    Color c = val < (isPression ? 90 : 70) ? Colors.blue : val <= 140 ? primaryGreen : Colors.red;
    String zone = val < (isPression ? 90 : 70) ? t.nutrition_pressure_low : val <= 140 ? t.nutrition_pressure_normal : t.nutrition_pressure_high;
    IconData icon = val < (isPression ? 90 : 70) ? Icons.arrow_downward_rounded : val <= 140 ? Icons.check_circle_outline : Icons.arrow_upward_rounded;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Row(children: [
          Icon(icon, color: c, size: 16), const SizedBox(width: 4),
          Text('${val.toInt()} $unit', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.4))),
            child: Text(zone, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
      ]),
      SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: c, inactiveTrackColor: c.withOpacity(0.2), thumbColor: c, overlayColor: c.withOpacity(0.15), trackHeight: 5),
        child: Slider(value: val, min: min, max: max, onChanged: (v) => setState(() => isPression ? pressure = v : sugar = v))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isPression ? '${t.nutrition_pressure_low}\n<90' : '${t.nutrition_pressure_low}\n<70', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.blue)),
        Text(isPression ? '${t.nutrition_pressure_normal}\n90–140' : '${t.nutrition_pressure_normal}\n70–140', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: primaryGreen)),
        Text('${t.nutrition_pressure_high}\n>140', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.red)),
      ])),
    ]);
  }

  Widget _foodCard(String image, String title, String desc) {
    bool isDanger = desc.contains("éviter") || desc.contains("Bloque") || desc.contains("Blocks") || desc.contains("يعيق");
    return Container(margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(fit: StackFit.expand, children: [
        Image.asset(image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 50, color: Colors.grey))),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.75), Colors.transparent])),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(desc, style: TextStyle(color: isDanger ? Colors.red[300] : Colors.white70, fontSize: 10, fontWeight: isDanger ? FontWeight.bold : FontWeight.normal)),
          ]))),
        if (isDanger) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.warning_rounded, color: Colors.white, size: 14))),
      ])));
  }

  Widget _infoCard(String image, String title, String subtitle) => Container(height: 110, width: 155,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset(image, height: 35, errorBuilder: (c, e, s) => const Icon(Icons.info)),
      const SizedBox(height: 5),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]));

  Widget _buildCard({required Widget child}) => Container(padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
    child: child);

  Widget _metricInfo(String t, String v, String u) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(t, style: const TextStyle(color: Colors.grey)),
    Text('$v $u', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
  ]);
}


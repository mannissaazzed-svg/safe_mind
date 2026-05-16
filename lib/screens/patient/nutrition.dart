import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HealthAnalysis extends StatefulWidget {
  final String diseaseType;
  const HealthAnalysis({super.key, required this.diseaseType});

  @override
  _HealthAnalysisState createState() => _HealthAnalysisState();
}

class _HealthAnalysisState extends State<HealthAnalysis> {
  
  double age = 65;
  int weight = 75;
  int height = 170;
  double pressure = 130;
  double sugar = 100;

  bool hasDiabetes     = false;
  bool hasHTA          = false;
  bool hasDysphagie    = false;
  bool hasDenutrition  = false;
  bool hasConstipation = false;

 
  bool hasAVC         = false;
  bool hasDepression  = false;
  bool hasEpilepsie   = false;

 
  bool   showResults      = false;
  double cognitiveScore   = 0.0;
  double motorScore       = 0.0;
  double vascScore        = 0.0;
  double imc              = 0.0;
  String imcLabel         = '';
  bool   htaDetectedCache = false;

  int selectedMealTab = 0;

  final Color bgColor      = const Color(0xFFF8FAFC);
  final Color primaryBlue  = const Color(0xFF4DA3FF);
  final Color primaryGreen = const Color(0xFF42D392);
  final Color nutritionBg  = const Color(0xff8EA7BF);

  late FixedExtentScrollController _weightController;
  late FixedExtentScrollController _heightController;

  @override
  void initState() {
    super.initState();
    _weightController = FixedExtentScrollController(initialItem: weight - 30);
    _heightController = FixedExtentScrollController(initialItem: height - 100);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String _getImcLabel(double imc) {
    if (imc < 18.5) return 'Dénutrition';
    if (imc < 21)   return 'Risque dénutrition';
    if (imc < 25)   return 'Normal';
    if (imc < 30)   return 'Surpoids';
    return 'Obésité';
  }

  Color _getImcColor(double imc) {
    if (imc < 18.5) return Colors.red;
    if (imc < 21)   return Colors.orange;
    if (imc < 25)   return primaryGreen;
    if (imc < 30)   return Colors.orange;
    return Colors.red;
  }

  void _calculateMetrics() {
    double h = height / 100;
    double imcCalc = weight / (h * h);

    bool diabetes = sugar > 140 || hasDiabetes;
    bool hta = pressure > 140 || hasHTA;

    setState(() {
      imc = imcCalc;
      imcLabel = _getImcLabel(imc);
      htaDetectedCache = hta;

      if (widget.diseaseType == 'Alzheimer') {
        double neuro = 1.0;
        if (age >= 80)   neuro -= 0.3;
        else if (age >= 70) neuro -= 0.15;
        if (diabetes)    neuro -= 0.25;
        if (hta)         neuro -= 0.25;
        if (imc >= 30)   neuro -= 0.15;
        if (imc < 18.5)  neuro -= 0.25;
        if (hasAVC)      neuro -= 0.2;
        if (hasDepression) neuro -= 0.1;
        if (hasEpilepsie)  neuro -= 0.15;
        cognitiveScore = neuro.clamp(0.2, 1.0);

        double nutri = 1.0;
        if (hasDenutrition || imc < 18.5) nutri -= 0.5;
        if (imc < 21)      nutri -= 0.2;
        if (hasDysphagie)  nutri -= 0.3;
        motorScore = nutri.clamp(0.1, 1.0);

        double vasc = 1.0;
        if (hta)           vasc -= 0.4;
        if (diabetes)      vasc -= 0.3;
        if (hasAVC)        vasc -= 0.3;
        if (pressure < 90) vasc -= 0.2;
        vascScore = vasc.clamp(0.1, 1.0);

      } else {
        double med = 1.0;
        if (hasConstipation) med -= 0.3;
        if (hasDysphagie)    med -= 0.25;
        if (imc < 18.5)      med -= 0.3;
        if (imc > 30)        med -= 0.2;
        if (diabetes)        med -= 0.2;
        cognitiveScore = med.clamp(0.1, 1.0);

        double mobility = 1.0;
        if (hasConstipation) mobility -= 0.4;
        if (hasDysphagie)    mobility -= 0.2;
        if (imc < 18.5)      mobility -= 0.2;
        motorScore = mobility.clamp(0.1, 1.0);

        double balance = 1.0;
        if (hasDenutrition)  balance -= 0.4;
        if (hasDysphagie)    balance -= 0.3;
        if (hta && diabetes) balance -= 0.4;
        else if (hta)        balance -= 0.2;
        else if (diabetes)   balance -= 0.2;
        vascScore = balance.clamp(0.1, 1.0);
      }

      showResults = true;
    });
  }

  

  Map<String, String> _getMealPlan() {
    if (widget.diseaseType == 'Alzheimer') {
      return _getAlzheimerMeal();
    } else {
      return _getParkinsonMeal();
    }
  }

  Map<String, String> _getAlzheimerMeal() {
    // ── AVC ──
    if (hasAVC) {
      return {
        'Petit déjeuner': 'Pain complet + huile d\'olive + lait demi-écrémé',
        'Collation':      'Amandes + fruit frais',
        'Déjeuner':       'Poisson + légumes + riz complet',
        'Dîner':          'Soupe + légumes verts',
      };
    }
    // ── Dépression ──
    if (hasDepression) {
      return {
        'Petit déjeuner': 'Lait + chocolat noir + pain complet',
        'Collation':      'Banane + noix',
        'Déjeuner':       'Poisson + légumes variés',
        'Dîner':          'Soupe + œuf + fruit',
      };
    }
    // ── Épilepsie ──
    if (hasEpilepsie) {
      return {
        'Petit déjeuner': 'Lait + pain complet + fruit',
        'Collation':      'Yaourt nature + amandes',
        'Déjeuner':       'Viande + légumes bien cuits',
        'Dîner':          'Soupe + yaourt + fruit',
      };
    }

    if (hasDysphagie) {
      if (hasDenutrition || imc < 18.5) {
        return {
          'Petit déjeuner': 'Bouillie enrichie (lait entier + poudre de lait) + compote mixée + lait chaud',
          'Collation':      'Crème dessert + yaourt lisse',
          'Déjeuner':       'Purée de légumes enrichie + viande mixée + fromage fondu',
          'Dîner':          'Soupe mixée épaisse + crème dessert + yaourt',
        };
      }
      if (hasHTA) {
        return {
          'Petit déjeuner': 'Bouillie sans sel (lait + flocons avoine) + compote',
          'Collation':      'Yaourt nature lisse',
          'Déjeuner':       'Purée de légumes vapeur + poisson mixé (sans sel)',
          'Dîner':          'Soupe mixée sans sel + yaourt nature',
        };
      }
      return {
        'Petit déjeuner': 'Bouillie enrichie + compote mixée + lait chaud',
        'Collation':      'Crème dessert',
        'Déjeuner':       'Purée de légumes + viande mixée + yaourt',
        'Dîner':          'Soupe mixée + fromage mou + crème dessert',
      };
    }
    if (hasDenutrition || imc < 18.5) {
      return {
        'Petit déjeuner': 'Lait entier enrichi (poudre de lait) + beurre + confiture + pain complet + banane',
        'Collation':      'Yaourt enrichi + biscuits',
        'Déjeuner':       'Viande hachée + purée enrichie (beurre + fromage) + légumes bien cuits + yaourt',
        'Dîner':          'Omelette (2 œufs) + fromage + pain complet + fruit mou',
      };
    }
    if (imc < 21 && imc >= 18.5) {
      if (age >= 80) {
        return {
          'Petit déjeuner': 'Lait enrichi + pain mou + confiture + fruit mixé',
          'Collation':      'Compote + biscuit mou',
          'Déjeuner':       'Poisson + purée bien cuite + légumes fondants',
          'Dîner':          'Soupe épaisse + yaourt enrichi + fruit',
        };
      }
      return {
        'Petit déjeuner': 'Lait entier + pain complet + beurre + fruit',
        'Collation':      'Yaourt + fruit',
        'Déjeuner':       'Viande + purée + légumes cuits + fromage',
        'Dîner':          'Soupe + œuf + yaourt + fruit',
      };
    }
    if (age >= 80) {
      if (hasDiabetes && hasHTA) {
        return {
          'Petit déjeuner': 'Pain complet + fromage frais (sans sel) + thé sans sucre',
          'Collation':      'Fruit frais (IG bas)',
          'Déjeuner':       'Poisson + légumes vapeur + riz complet',
          'Dîner':          'Soupe légumes (sans sel) + yaourt nature',
        };
      }
      if (hasDiabetes) {
        return {
          'Petit déjeuner': 'Pain complet + œuf + thé sans sucre',
          'Collation':      'Yaourt nature',
          'Déjeuner':       'Poisson + riz complet + légumes verts vapeur',
          'Dîner':          'Soupe légumes + poulet + yaourt nature',
        };
      }
      if (hasHTA) {
        return {
          'Petit déjeuner': 'Pain complet + fromage frais (sans sel) + fruit',
          'Collation':      'Fruit + amandes',
          'Déjeuner':       'Poisson + légumes vapeur (sans sel)',
          'Dîner':          'Soupe légumes + viande blanche + yaourt',
        };
      }
      return {
        'Petit déjeuner': 'Lait entier + pain mou + confiture + fruit (banane ou compote)',
        'Collation':      'Fruit mou + yaourt',
        'Déjeuner':       'Poisson + purée de légumes + légumes bien cuits + yaourt',
        'Dîner':          'Soupe de légumes + fromage mou + fruit mou',
      };
    }
    if (hasDiabetes && hasHTA) {
      return {
        'Petit déjeuner': 'Pain complet + œuf poché + thé sans sucre (sans sel)',
        'Collation':      'Fruit frais (IG bas)',
        'Déjeuner':       'Poisson grillé + légumes vapeur (sans sel) + quinoa',
        'Dîner':          'Soupe légumes (sans sel) + poulet + salade verte',
      };
    }
    if (hasDiabetes) {
      return {
        'Petit déjeuner': 'Pain complet + fromage + thé sans sucre',
        'Collation':      'Fruit frais (IG bas)',
        'Déjeuner':       'Viande blanche + légumes + semoule complète',
        'Dîner':          'Soupe + légumes + poisson',
      };
    }
    if (hasHTA) {
      return {
        'Petit déjeuner': 'Lait écrémé + pain complet',
        'Collation':      'Fruit + yaourt nature',
        'Déjeuner':       'Poulet + légumes vapeur',
        'Dîner':          'Potage + yaourt + fruit',
      };
    }
    if (imc >= 30) {
      return {
        'Petit déjeuner': 'Pain complet + fromage 0% + café sans sucre + fruit',
        'Collation':      'Yaourt nature 0%',
        'Déjeuner':       'Poulet grillé + légumes vapeur + riz complet (petite portion)',
        'Dîner':          'Soupe légumes + salade + yaourt nature',
      };
    }
    if (imc >= 25) {
      return {
        'Petit déjeuner': 'Pain complet + œuf + fruit + café sans sucre',
        'Collation':      'Fruit frais',
        'Déjeuner':       'Poisson + légumes vapeur + riz complet',
        'Dîner':          'Soupe + salade + yaourt',
      };
    }
    if (age >= 70) {
      return {
        'Petit déjeuner': 'Lait + flocons d\'avoine + myrtilles + noix + huile d\'olive',
        'Collation':      'Amandes + fruit rouge',
        'Déjeuner':       'Saumon grillé + riz complet + épinards à l\'huile d\'olive',
        'Dîner':          'Soupe légumes + lentilles + yaourt + noix',
      };
    }
    return {
      'Petit déjeuner': 'Lait + pain complet + huile d\'olive + dattes',
      'Collation':      'Fruit frais + amandes',
      'Déjeuner':       'Poisson + légumes + riz',
      'Dîner':          'Yaourt + fruit / Soupe + œuf',
    };
  }

  Map<String, String> _getParkinsonMeal() {
    if (hasDysphagie && hasDenutrition) {
      return {
        'Petit déjeuner': 'Crème enrichie (lait entier + poudre de lait) + compote mixée lisse',
        'Collation':      'Crème dessert + yaourt lisse',
        'Déjeuner':       'Purée enrichie (beurre + fromage fondu) + viande finement mixée',
        'Dîner':          'Soupe épaisse mixée + yaourt nature (texture lisse)',
      };
    }
    if (hasDysphagie && hasHTA) {
      return {
        'Petit déjeuner': 'Bouillie sans sel (lait + flocons d\'avoine mixés) + compote',
        'Collation':      'Yaourt lisse',
        'Déjeuner':       'Purée de légumes (sans sel) + poisson mixé',
        'Dîner':          'Soupe mixée sans sel (légumes frais)',
      };
    }
    if (hasDysphagie) {
      return {
        'Petit déjeuner': 'Bouillie lisse (lait + avoine) + compote mixée',
        'Collation':      'Crème dessert',
        'Déjeuner':       'Purée de légumes + viande finement mixée + yaourt',
        'Dîner':          'Soupe mixée épaisse + crème dessert',
      };
    }
    if (hasDenutrition || imc < 18.5) {
      if (hasDiabetes) {
        return {
          'Petit déjeuner': 'Lait entier + céréales complètes (sans sucre) + fruit (IG bas)',
          'Collation':      'Yaourt nature + amandes',
          'Déjeuner':       'Viande + légumes variés + lentilles (protéines + fibres)',
          'Dîner':          'Poisson + salade + yaourt nature (calories contrôlées)',
        };
      }
      return {
        'Petit déjeuner': 'Lait enrichi (poudre de lait) + beurre + confiture + banane',
        'Collation':      'Yaourt + biscuits',
        'Déjeuner':       'Viande hachée + purée enrichie (beurre) + légumes bien cuits',
        'Dîner':          'Omelette (2 œufs) + fromage + pain + yaourt',
      };
    }
    if (hasDiabetes && hasHTA) {
      return {
        'Petit déjeuner': 'Pain complet + fromage frais (sans sel) + thé sans sucre',
        'Collation':      'Yaourt nature',
        'Déjeuner':       'Poisson grillé + légumes vapeur (sans sel) + quinoa',
        'Dîner':          'Soupe légumes (sans sel) + poulet + légumes verts',
      };
    }
    if (hasDiabetes) {
      return {
        'Petit déjeuner': 'Pain complet + œuf poché + thé sans sucre',
        'Collation':      'Yaourt nature',
        'Déjeuner':       'Poisson grillé + quinoa + légumes verts',
        'Dîner':          'Soupe légumes + poulet grillé + légumes',
      };
    }
    if (hasHTA) {
      return {
        'Petit déjeuner': 'Pain complet + fromage frais (faible sel)',
        'Collation':      'Fruits frais',
        'Déjeuner':       'Poisson grillé + légumes vapeur (sans sel ajouté)',
        'Dîner':          'Salade verte + viande blanche + fruits frais',
      };
    }
    if (hasConstipation) {
      return {
        'Petit déjeuner': 'Flocons d\'avoine + fruit (pruneaux ou orange) + eau (grand verre)',
        'Collation':      'Pruneaux + yaourt probiotique',
        'Déjeuner':       'Lentilles + légumes variés + pain complet',
        'Dîner':          'Soupe légumes + yaourt probiotique + pruneaux',
      };
    }
    if (age >= 80) {
      return {
        'Petit déjeuner': 'Bouillie lisse + compote + lait chaud',
        'Collation':      'Crème dessert',
        'Déjeuner':       'Purée légumes + poisson mixé + yaourt',
        'Dîner':          'Soupe mixée + crème dessert',
      };
    }
    if (age < 65) {
      return {
        'Petit déjeuner': 'Lait + céréales complètes + fruit frais',
        'Collation':      'Fruits secs (amandes, noix)',
        'Déjeuner':       'Viande + pâtes complètes + légumes variés',
        'Dîner':          'Poisson + salade + fruits secs (amandes, noix)',
      };
    }
    return {
      'Petit déjeuner': 'Lait + pain complet + miel + fruit (faible en protéines le matin)',
      'Collation':      'Fruit + amandes',
      'Déjeuner':       'Poulet grillé + riz complet + légumes vapeur',
      'Dîner':          'Soupe légumes + salade + yaourt + amandes',
    };
  }

  

  List<Map<String, String>> _baseFoods(bool isAlzheimer) {
    if (isAlzheimer) {
      return [
        {'asset': 'assets/sardine.jpg',     'title': 'Sardines',      'desc': 'Oméga 3'},
        {'asset': 'assets/maquereau.jpg',   'title': 'Maquereau',     'desc': 'Oméga 3'},
        {'asset': 'assets/saumon.jpg',      'title': 'Saumon',        'desc': 'Oméga 3'},
        {'asset': 'assets/myrtille.jpg',    'title': 'Myrtilles',     'desc': 'Antioxydants'},
        {'asset': 'assets/fraise.jpg',      'title': 'Fraises',       'desc': 'Antioxydants'},
        {'asset': 'assets/orange.jpg',      'title': 'Orange',        'desc': 'Vitamine C'},
        {'asset': 'assets/banane.jpg',      'title': 'Banane',        'desc': 'Énergie'},
        {'asset': 'assets/epinards.jpg',    'title': 'Épinards',      'desc': 'Mémoire'},
        {'asset': 'assets/brocoli.jpg',     'title': 'Brocoli',       'desc': 'Neuro-protecteur'},
        {'asset': 'assets/lentilles.jpg',   'title': 'Lentilles',     'desc': 'Protéines végétales'},
        {'asset': 'assets/noix.jpg',        'title': 'Noix',          'desc': 'Cerveau'},
        {'asset': 'assets/amandes.jpg',     'title': 'Amandes',       'desc': 'Énergie'},
        {'asset': 'assets/huile_olive.png', 'title': 'Huile d\'olive','desc': 'Anti-inflammatoire'},
        {'asset': 'assets/oeuf.jpg',        'title': 'Œufs',          'desc': 'Vit B12'},
        {'asset': 'assets/lait_enrichi.jpg','title': 'Lait',          'desc': 'Calcium'},
        {'asset': 'assets/riz_complet.jpg', 'title': 'Riz complet',   'desc': 'Fibres'},
        {'asset': 'assets/avoine.jpg',      'title': 'Avoine',        'desc': 'Énergie lente'},
      ];
    } else {
      return [
        {'asset': 'assets/avoine.jpg',        'title': 'Avoine',      'desc': 'Transit'},
        {'asset': 'assets/lentilles.jpg',     'title': 'Lentilles',   'desc': 'Fibres'},
        {'asset': 'assets/pruneaux.jpg',      'title': 'Pruneaux',    'desc': 'Constipation'},
        {'asset': 'assets/poisson.jpg',       'title': 'Poisson',     'desc': 'Oméga 3'},
        {'asset': 'assets/poulet.jpg',        'title': 'Poulet',      'desc': 'Protéines'},
        {'asset': 'assets/viande_rouges.jpg', 'title': 'Viande',      'desc': 'Protéines'},
        {'asset': 'assets/noix.jpg',          'title': 'Noix',        'desc': 'Énergie'},
        {'asset': 'assets/huile_olive.png',   'title': 'Huile d\'olive','desc': 'Anti-inflammatoire'},
        {'asset': 'assets/fruits.png',        'title': 'Fruits',      'desc': 'Vitamines'},
        {'asset': 'assets/legumes.jpg',       'title': 'Légumes',     'desc': 'Fibres'},
        {'asset': 'assets/riz.jpg',           'title': 'Riz',         'desc': 'Énergie'},
      ];
    }
  }

  void _addFoods(List<Map<String, String>> foods) {
    if (hasDenutrition) {
      foods.addAll([
        {'asset': 'assets/beurre.jpg',  'title': 'Beurre',  'desc': 'Calories'},
        {'asset': 'assets/fromage.jpg', 'title': 'Fromage', 'desc': 'Protéines'},
      ]);
    }
    if (hasConstipation) {
      foods.add({'asset': 'assets/pruneaux.jpg', 'title': 'Pruneaux', 'desc': 'Laxatif naturel'});
    }
    if (hasHTA) {
      foods.add({'asset': 'assets/legumes_vapeur.jpg', 'title': 'Légumes vapeur', 'desc': 'Sans sel'});
    }
  }

  void _removeFoods(List<Map<String, String>> foods) {
    if (hasDiabetes) {
      foods.removeWhere((f) =>
          f['title']!.contains('Fraises') ||
          f['title']!.contains('Orange') ||
          f['title']!.contains('Banane'));
    }
    if (hasDysphagie) {
      foods.clear();
      foods.addAll([
        {'asset': 'assets/puree.jpg',    'title': 'Purée',        'desc': 'Texture adaptée'},
        {'asset': 'assets/soupe.jpg',    'title': 'Soupe mixée',  'desc': 'Sécurité'},
        {'asset': 'assets/bouillie.jpg', 'title': 'Bouillie',     'desc': 'Facile à avaler'},
      ]);
    }
  }

  List<Map<String, String>> _getHealthyFoods() {
    bool isAlzheimer = widget.diseaseType == 'Alzheimer';
    List<Map<String, String>> foods = _baseFoods(isAlzheimer);
    _addFoods(foods);
    _removeFoods(foods);
    final unique = <String, Map<String, String>>{};
    for (var f in foods) { unique[f['title']!] = f; }
    return unique.values.toList();
  }

  List<Map<String, String>> _getAvoidFoods() {
    List<Map<String, String>> avoid = [
      {'asset': 'assets/fastfood.png',   'title': 'Fast-food',   'desc': 'Inflammation'},
      {'asset': 'assets/sucreries.png',  'title': 'Sucreries',   'desc': 'Glycémie'},
      {'asset': 'assets/fritures.png',   'title': 'Fritures',    'desc': 'Graisses'},
      {'asset': 'assets/charcuterie.png','title': 'Charcuterie', 'desc': 'Sel'},
    ];
    if (hasHTA) {
      avoid.add({'asset': 'assets/sel.png', 'title': 'Sel', 'desc': 'HTA'});
    }
    if (widget.diseaseType == 'Parkinson') {
      avoid.add({
        'asset': 'assets/proteine_matin.png',
        'title': 'Protéines matin',
        'desc': 'Bloque médicament',
      });
    }
    return avoid;
  }

  

  List<Map<String, String>> _getTips() {
    List<Map<String, String>> tips = [];
    bool isAlzheimer = widget.diseaseType == 'Alzheimer';

    if (isAlzheimer) {
     
      if (hasAVC) {
        tips.add({'icon': '🫀', 'title': 'Priorité médicale : AVC',
          'desc': 'Régime cardio-protecteur. Anti-cholestérol, oméga 3 (poisson, huile d\'olive). Éviter graisses saturées et sel excessif'});
        tips.add({'icon': '🐟', 'title': 'Besoins nutritionnels : AVC',
          'desc': 'Oméga 3 ↑ (poissons gras), anti-cholestérol, régime cardio-vasculaire. Apport : pain complet + huile d\'olive + poisson + riz complet'});
        return tips;
      }

     
      if (hasDepression) {
        tips.add({'icon': '🧠', 'title': 'Priorité médicale : Dépression',
          'desc': 'Bon apport énergétique. Aliments riches en magnésium et oméga 3 pour soutenir l\'humeur et la fonction cérébrale'});
        tips.add({'icon': '🍫', 'title': 'Besoins nutritionnels : Dépression',
          'desc': 'Magnésium ↑, oméga 3 ↑, apport énergétique équilibré. Programme : lait + chocolat noir + pain / poisson + légumes / banane'});
        return tips;
      }

    
      if (hasEpilepsie) {
        tips.add({'icon': '⚡', 'title': 'Priorité médicale : Épilepsie',
          'desc': 'Éviter absolument l\'hypoglycémie. Repas réguliers obligatoires, ne jamais sauter un repas. Équilibre alimentaire strict'});
        tips.add({'icon': '🥛', 'title': 'Besoins nutritionnels : Épilepsie',
          'desc': 'Équilibre alimentaire, prévention hypoglycémie. Programme : lait + pain complet / viande + légumes / fruit + soupe + yaourt'});
        return tips;
      }

     
      if (hasDysphagie) {
        tips.add({'icon': '🥣', 'title': 'DANGER: Dysphagie',
          'desc': 'Texture lisse obligatoire (purée, soupe mixée, bouillie). Risque de fausse route. Priorité sécurité maximale'});
      }

     
      if (hasDenutrition || imc < 18.5) {
        tips.add({'icon': '⚠️', 'title': 'Besoins nutritionnels : Dénutrition',
          'desc': 'Apport énergétique ↑. Enrichissement : lait enrichi, beurre, fromage. Fractionnement en 5 prises. Priorité apports caloriques'});
      } else if (imc < 21) {
        tips.add({'icon': '⚖️', 'title': 'Remarque : IMC < 21',
          'desc': 'Risque dénutrition gériatrique. Surveillance renforcée du poids. Apport énergétique et protéique adapté à l\'âge'});
      }

      
      if (hasDiabetes) {
        tips.add({'icon': '🩸', 'title': 'Besoins nutritionnels : Diabète',
          'desc': 'Contrôle glycémique strict. IG bas, éviter sucres rapides. Repas réguliers sans sauter. Programme : pain complet + fromage / viande blanche + légumes + semoule complète'});
      }

     
      if (hasHTA) {
        tips.add({'icon': '❤️', 'title': 'Besoins nutritionnels : HTA',
          'desc': 'Réduction du sel, hydratation ↑, régime DASH. Lait écrémé, légumes vapeur, éviter aliments industriels et charcuteries'});
      }

     
      tips.add({'icon': '🧠', 'title': 'Besoins nutritionnels : Alzheimer',
        'desc': 'Apport énergétique, oméga 3, antioxydants, hydratation. Régime méditerranéen : poisson + légumes + riz / lait + pain complet + huile d\'olive + dattes'});

      if (age >= 80) {
        tips.add({'icon': '💧', 'title': 'Remarque : ≥ 80 ans',
          'desc': 'Hydratation renforcée 1,5–2L/j. Textures adaptées. Enrichissement protéique. Surveiller poids régulièrement'});
      }

    } else {
     
      tips.add({'icon': '💊', 'title': 'Point critique : Interaction Lévodopa/protéines',
        'desc': 'Éviter protéines le matin (viande, œufs). Réserver protéines à midi et au dîner uniquement. Très important pour l\'efficacité du traitement'});

      
      if (hasDysphagie && hasDenutrition) {
        tips.add({'icon': '🥣', 'title': 'Priorité médicale : Dysphagie + Dénutrition',
          'desc': 'Sécurité + calories. Texture mixée enrichie. Équilibre difficile : apport calorique ↑ avec texture lisse obligatoire. Appétit souvent réduit'});
      } else if (hasDysphagie && hasHTA) {
        tips.add({'icon': '🥣', 'title': 'Priorité médicale : Dysphagie + HTA',
          'desc': 'Sécurité + tension. Texture modifiée + sel ↓. Programme : bouillie sans sel / purée + poisson / soupe'});
      } else if (hasDysphagie) {
        tips.add({'icon': '🥣', 'title': 'Priorité médicale : Dysphagie',
          'desc': 'Sécurité maximale. Texture mixée/hachée, aliments lisses obligatoires. Risque élevé de fausse route dans Parkinson'});
      }

      
      if ((hasDenutrition || imc < 18.5) && hasDiabetes) {
        tips.add({'icon': '⚖️', 'title': 'Priorité médicale : Dénutrition + Diabète',
          'desc': 'Conflit médical. Calories ↑ mais sucres contrôlés. Équilibre délicat : lait + céréales complètes / viande + légumes / poisson'});
      } else if (hasDenutrition || imc < 18.5) {
        tips.add({'icon': '⚠️', 'title': 'Priorité médicale : Dénutrition',
          'desc': 'Apport calorique ↑. Repas fractionnés, enrichissement : lait enrichi, purée enrichie, biscuits. Perte de poids rapide à surveiller'});
      }

     
      if (hasDiabetes && hasHTA) {
        tips.add({'icon': '⚖️', 'title': 'Priorité médicale : Diabète + HTA',
          'desc': 'Double contrôle glycémie + tension. IG bas + sel ↓ + fibres ↑. Régime restrictif → risque carence. Faible sel + faible sucre'});
      } else if (hasDiabetes) {
        tips.add({'icon': '🩸', 'title': 'Besoins nutritionnels : Diabète',
          'desc': 'IG bas, supprimer sucres rapides, repas réguliers. Éviter pics glycémiques + gérer protéines avec lévodopa'});
      } else if (hasHTA) {
        tips.add({'icon': '❤️', 'title': 'Besoins nutritionnels : HTA',
          'desc': 'Sel ↓, aliments frais, potassium ↑. Sel caché dans produits industriels. Régime DASH adapté Parkinson'});
      }

     
      if (hasConstipation) {
        tips.add({'icon': '🌾', 'title': 'Remarque : Constipation (très fréquent Parkinson)',
          'desc': 'Fibres ↑↑ : avoine, lentilles, pruneaux. Hydratation ↑↑ : eau 6–8 verres/j. Très fréquent dans Parkinson'});
      }

      
      tips.add({'icon': '💧', 'title': 'Besoins nutritionnels : Hydratation',
        'desc': 'Eau 1,5–2L/j. Aide constipation et efficacité médicaments. 6–8 verres par jour recommandés'});

      
      if (age >= 80) {
        tips.add({'icon': '👴', 'title': 'Remarque : ≥ 80 ans',
          'desc': 'Texture adaptée (bouillie, purée, soupe mixée). Apport énergétique 30–35 kcal/kg/j. Enrichissement protéique + fractionnement'});
      }
    }
    return tips;
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nutrition • ${widget.diseaseType}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  Text(
                    "ANALYSE NUTRITIONNELLE",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildAgePicker(),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _buildWeightRuler()),
                    const SizedBox(width: 15),
                    Expanded(child: _buildHeightRuler()),
                  ]),
                  const SizedBox(height: 20),
                  _buildVitalSliders(),
                  const SizedBox(height: 20),
                  _buildComorbiditiesSection(),
                  const SizedBox(height: 30),
                  _buildAnalyzeButton(),
                  if (showResults) _buildDiagnosticSection(),
                  const SizedBox(height: 160),
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
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 15, bottom: 10),
                          width: 50, height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(10)),
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
    String subtitle = widget.diseaseType == 'Alzheimer'
        ? "Adoptez une alimentation saine pour améliorer la mémoire et protéger le cerveau"
        : "Une alimentation équilibrée peut atténuer les symptômes de la maladie de Parkinson";

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(15),
        child: Text(subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _getImcColor(imc).withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _getImcColor(imc), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.monitor_weight_outlined, color: _getImcColor(imc)),
          const SizedBox(width: 8),
          Text(
            'IMC: ${imc.toStringAsFixed(1)} — $imcLabel',
            style: TextStyle(color: _getImcColor(imc), fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      ),
      const SizedBox(height: 10),
      Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage("assets/healthy food.png"),
            fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 15),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _infoCard("assets/eau.png",    "Boire de l'eau", "6-8 Verres/jour"),
        _infoCard("assets/marche.png", "Marche",         weight > 90 ? "15 min/jour" : "20 min/jour"),
      ]),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft,
          child: Text("Conseils & Avertissements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
      const SizedBox(height: 10),
      _buildTipsSection(),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft,
          child: Text("Programme repas personnalisé",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
      const SizedBox(height: 10),
      _buildMealTabs(),
      const SizedBox(height: 20),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Align(alignment: Alignment.centerLeft,
          child: Text("Aliments à éviter",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
      _buildAvoidGrid(),
      const SizedBox(height: 50),
    ]);
  }

  

  Widget _buildMealTabs() {
    final tabs  = ['Petit déjeuner', 'Collation', 'Déjeuner', 'Dîner'];
    final icons = [
      Icons.wb_sunny_outlined,
      Icons.coffee_outlined,
      Icons.wb_cloudy_outlined,
      Icons.nightlight_round,
    ];

    Map<String, List<Map<String, String>>> mealFoods = _getMealFoodsByProfile();
    final selectedFoods = mealFoods[tabs[selectedMealTab]] ?? [];

    return Column(
      children: [
       
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              bool selected = selectedMealTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedMealTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: selected
                          ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icons[i],
                          color: selected ? primaryBlue : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          i == 0 ? 'Matin' : i == 1 ? 'Collation' : i == 2 ? 'Déjeuner' : 'Dîner',
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? primaryBlue : Colors.white70,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 15),

       
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            _getMealDescription(tabs[selectedMealTab]),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
        ),

        const SizedBox(height: 12),

       
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: selectedFoods
                .map((food) => _foodCard(food['asset']!, food['title']!, food['desc']!))
                .toList(),
          ),
        ),
      ],
    );
  }

  String _getMealDescription(String mealTime) {
    final plan = _getMealPlan();
    return plan[mealTime] ?? '';
  }

  Map<String, List<Map<String, String>>> _getMealFoodsByProfile() {
    if (widget.diseaseType == 'Alzheimer') {
      return _getAlzheimerMealFoods();
    } else {
      return _getParkinsonMealFoods();
    }
  }

  
  Map<String, List<Map<String, String>>> _getAlzheimerMealFoods() {

    // ── AVC (Source docx) ──
    if (hasAVC) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/pain_complet.jpg', 'title': 'Pain complet',    'desc': 'Fibres'},
          {'asset': 'assets/huile_olive.png',  'title': 'Huile d\'olive',  'desc': 'Cardio-protecteur'},
        ],
        'Collation': [
          {'asset': 'assets/amandes.jpg',      'title': 'Amandes',         'desc': 'Oméga 3'},
          {'asset': 'assets/fruits.png',       'title': 'Fruit frais',     'desc': 'Antioxydants'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poissons.png',     'title': 'Poisson',         'desc': 'Oméga 3'},
          {'asset': 'assets/legumes.jpg',      'title': 'Légumes',         'desc': 'Anti-cholestérol'},
          {'asset': 'assets/riz_complet.jpg',  'title': 'Riz complet',     'desc': 'Fibres'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',        'title': 'Soupe',           'desc': 'Hydratation'},
          {'asset': 'assets/legumes.jpg',      'title': 'Légumes verts',   'desc': 'Antioxydants'},
        ],
      };
    }

    
    if (hasDepression) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg', 'title': 'Lait',            'desc': 'Calcium'},
          {'asset': 'assets/pain_complet.jpg', 'title': 'Pain complet',    'desc': 'Fibres'},
        ],
        'Collation': [
          {'asset': 'assets/banane.jpg',       'title': 'Banane',          'desc': 'Magnésium'},
          {'asset': 'assets/noix.jpg',         'title': 'Noix',            'desc': 'Oméga 3'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poissons.png',     'title': 'Poisson',         'desc': 'Oméga 3'},
          {'asset': 'assets/legumes.jpg',      'title': 'Légumes variés',  'desc': 'Vitamines'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',        'title': 'Soupe',           'desc': 'Hydratation'},
          {'asset': 'assets/oeuf.jpg',         'title': 'Œuf',             'desc': 'Vit B12'},
          {'asset': 'assets/fruits.png',       'title': 'Fruit',           'desc': 'Antioxydants'},
        ],
      };
    }

    
    if (hasEpilepsie) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg', 'title': 'Lait',            'desc': 'Calcium'},
          {'asset': 'assets/pain_complet.jpg', 'title': 'Pain complet',    'desc': 'IG stable'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt.jpg',       'title': 'Yaourt nature',   'desc': 'Protéines'},
          {'asset': 'assets/amandes.jpg',      'title': 'Amandes',         'desc': 'Énergie stable'},
        ],
        'Déjeuner': [
          {'asset': 'assets/viande_rouges.jpg','title': 'Viande',          'desc': 'Protéines'},
          {'asset': 'assets/legumes.jpg',      'title': 'Légumes',         'desc': 'Vitamines'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',        'title': 'Soupe',           'desc': 'Hydratation'},
          {'asset': 'assets/yaourt.jpg',       'title': 'Yaourt',          'desc': 'Calcium'},
          {'asset': 'assets/fruits.png',       'title': 'Fruit',           'desc': 'Vitamines'},
        ],
      };
    }

   
    if (hasDysphagie) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Bouillie enrichie', 'desc': 'Texture lisse'},
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait entier',       'desc': 'Calcium + calories'},
          {'asset': 'assets/puree.jpg',       'title': 'Compote mixée',     'desc': 'Vitamines'},
        ],
        'Collation': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Crème dessert',     'desc': 'Énergie'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt lisse',      'desc': 'Probiotiques'},
        ],
        'Déjeuner': [
          {'asset': 'assets/puree.jpg',       'title': 'Purée enrichie',    'desc': 'Beurre + fromage'},
          {'asset': 'assets/viande_rouges.jpg','title': 'Viande mixée',     'desc': 'Protéines'},
          {'asset': 'assets/fromage.jpg',     'title': 'Fromage fondu',     'desc': 'Calories'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe mixée épaisse','desc': 'Hydratation'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt',            'desc': 'Probiotiques'},
          {'asset': 'assets/bouillie.jpg',    'title': 'Crème dessert',     'desc': 'Énergie'},
        ],
      };
    }

   
    if (hasDenutrition || imc < 18.5) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait enrichi',      'desc': 'Poudre de lait'},
          {'asset': 'assets/beurre.jpg',      'title': 'Beurre',            'desc': 'Calories'},
          {'asset': 'assets/banane.jpg',      'title': 'Banane',            'desc': 'Énergie'},
          {'asset': 'assets/riz_complet.jpg', 'title': 'Pain complet',      'desc': 'Fibres'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt enrichi',    'desc': 'Calories'},
          {'asset': 'assets/fromage.jpg',     'title': 'Biscuits',          'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/viande_rouges.jpg','title': 'Viande hachée',    'desc': 'Protéines'},
          {'asset': 'assets/puree.jpg',       'title': 'Purée enrichie',    'desc': 'Beurre + fromage'},
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes bien cuits','desc': 'Vitamines'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt',            'desc': 'Calcium'},
        ],
        'Dîner': [
          {'asset': 'assets/oeuf.jpg',        'title': 'Omelette (2 œufs)', 'desc': 'Vit B12'},
          {'asset': 'assets/fromage.jpg',     'title': 'Fromage',           'desc': 'Protéines'},
          {'asset': 'assets/riz_complet.jpg', 'title': 'Pain complet',      'desc': 'Fibres'},
          {'asset': 'assets/fruits.png',      'title': 'Fruit mou',         'desc': 'Vitamines'},
        ],
      };
    }

    
    if (hasDiabetes && hasHTA) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/riz_complet.jpg', 'title': 'Pain complet',      'desc': 'IG bas'},
          {'asset': 'assets/oeuf.jpg',        'title': 'Œuf poché',         'desc': 'Protéines'},
          {'asset': 'assets/fromage.jpg',     'title': 'Fromage frais',     'desc': 'Sans sel'},
        ],
        'Collation': [
          {'asset': 'assets/fruits.png',      'title': 'Fruit frais (IG bas)','desc': 'Vitamines'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poisson.jpg',     'title': 'Poisson grillé',    'desc': 'Oméga 3'},
          {'asset': 'assets/legumes_vapeur.jpg','title': 'Légumes vapeur',  'desc': 'Sans sel'},
          {'asset': 'assets/riz_complet.jpg', 'title': 'Quinoa',            'desc': 'Protéines végétales'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe légumes',     'desc': 'Sans sel'},
          {'asset': 'assets/poulet.jpg',      'title': 'Poulet',            'desc': 'Protéines maigres'},
          {'asset': 'assets/legumes.jpg',     'title': 'Salade verte',      'desc': 'Antioxydants'},
        ],
      };
    }

    
    if (hasDiabetes) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/pain_complet.jpg', 'title': 'Pain complet',    'desc': 'IG bas'},
          {'asset': 'assets/fromages.png',     'title': 'Fromage frais',   'desc': 'Protéines'},
        ],
        'Collation': [
          {'asset': 'assets/fruits.png',       'title': 'Fruit frais',     'desc': 'IG bas'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poulet.jpg',       'title': 'Viande blanche',  'desc': 'Protéines maigres'},
          {'asset': 'assets/legumes.jpg',      'title': 'Légumes variés',  'desc': 'Fibres'},
          {'asset': 'assets/semoule_complete.jpg','title': 'Semoule complète','desc': 'IG bas'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',        'title': 'Soupe légumes',   'desc': 'Hydratation'},
          {'asset': 'assets/poissons.png',     'title': 'Poisson',         'desc': 'Oméga 3'},
          {'asset': 'assets/fruits.png',       'title': 'Fruit frais',     'desc': 'IG bas'},
        ],
      };
    }

    
    if (hasHTA) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_ecreme.jpg', 'title': 'Lait écrémé',     'desc': 'Faible sel'},
          {'asset': 'assets/pain_complet.jpg','title': 'Pain complet',    'desc': 'Fibres'},
        ],
        'Collation': [
          {'asset': 'assets/fruits.png',      'title': 'Fruit',           'desc': 'Potassium'},
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt nature',  'desc': 'Probiotiques'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poulet.jpg',      'title': 'Poulet',          'desc': 'Protéines maigres'},
          {'asset': 'assets/legumes_vapeur.jpg','title': 'Légumes vapeur','desc': 'Sans sel ajouté'},
        ],
        'Dîner': [
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt nature',  'desc': 'Probiotiques'},
          {'asset': 'assets/fruits.png',       'title': 'Fruit',          'desc': 'Vitamines'},
        ],
      };
    }

    
    if (age >= 80) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait entier',       'desc': 'Calcium'},
          {'asset': 'assets/riz_complet.jpg', 'title': 'Pain mou',          'desc': 'Digestion facile'},
          {'asset': 'assets/banane.jpg',      'title': 'Banane (compote)',   'desc': 'Énergie'},
          {'asset': 'assets/huile_olive.png', 'title': 'Huile d\'olive',    'desc': 'Neuroprotecteur'},
        ],
        'Collation': [
          {'asset': 'assets/puree.jpg',       'title': 'Compote',           'desc': 'Vitamines'},
          {'asset': 'assets/fromage.jpg',     'title': 'Biscuit mou',       'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poisson.jpg',     'title': 'Poisson',           'desc': 'Oméga 3'},
          {'asset': 'assets/puree.jpg',       'title': 'Purée de légumes',  'desc': 'Texture adaptée'},
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes fondants',  'desc': 'Fibres'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt enrichi',    'desc': 'Protéines'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe épaisse',     'desc': 'Hydratation'},
          {'asset': 'assets/fromage.jpg',     'title': 'Fromage mou',       'desc': 'Calcium'},
          {'asset': 'assets/fruits.png',      'title': 'Fruit mou',         'desc': 'Vitamines'},
        ],
      };
    }

    
    return {
      'Petit déjeuner': [
        {'asset': 'assets/lait_enrichi.jpg','title': 'Lait',              'desc': 'Calcium'},
        {'asset': 'assets/pain_complet.jpg','title': 'Pain complet',      'desc': 'Fibres'},
        {'asset': 'assets/huile_olive.png', 'title': 'Huile d\'olive',    'desc': 'Anti-inflammatoire'},
        {'asset': 'assets/dattes.jpg',      'title': 'Dattes',            'desc': 'Énergie naturelle'},
      ],
      'Collation': [
        {'asset': 'assets/fruits.png',      'title': 'Fruit frais',       'desc': 'Antioxydants'},
        {'asset': 'assets/amandes.jpg',     'title': 'Amandes',           'desc': 'Oméga 3'},
      ],
      'Déjeuner': [
        {'asset': 'assets/poissons.png',    'title': 'Poisson',           'desc': 'Oméga 3'},
        {'asset': 'assets/legumes.jpg',     'title': 'Légumes verts',     'desc': 'Antioxydants'},
        {'asset': 'assets/riz.jpg',         'title': 'Riz complet',       'desc': 'Fibres'},
      ],
      'Dîner': [
        {'asset': 'assets/soupe.jpg',       'title': 'Soupe légumes verts','desc': 'Hydratation'},
        {'asset': 'assets/oeuf.jpg',        'title': 'Œuf',               'desc': 'Vit B12'},
        {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt',           'desc': 'Probiotiques'},
        {'asset': 'assets/fruits.png',      'title': 'Fruits rouges',     'desc': 'Antioxydants'},
      ],
    };
  }

 
  Map<String, List<Map<String, String>>> _getParkinsonMealFoods() {

    // ── Dysphagie + Dénutrition ──
    if (hasDysphagie && hasDenutrition) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/creme_enrichie.jpg','title': 'Crème enrichie', 'desc': 'Lait + poudre de lait'},
        ],
        'Collation': [
          {'asset': 'assets/bouillie.jpg',      'title': 'Crème dessert',  'desc': 'Énergie'},
          {'asset': 'assets/yaourt_nature.jpg', 'title': 'Yaourt lisse',   'desc': 'Probiotiques'},
        ],
        'Déjeuner': [
          {'asset': 'assets/puree.jpg',         'title': 'Purée',          'desc': 'Beurre + fromage fondu'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',         'title': 'Soupe épaisse',  'desc': 'Hydratation'},
          {'asset': 'assets/yaourt_nature.jpg', 'title': 'Yaourt lisse',   'desc': 'Probiotiques'},
        ],
      };
    }

   
    if (hasDysphagie && hasHTA) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Bouillie sans sel','desc': 'Lait + avoine mixés'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt lisse',    'desc': 'Probiotiques'},
        ],
        'Déjeuner': [
          {'asset': 'assets/puree.jpg',       'title': 'Purée',            'desc': 'Sans sel'},
          {'asset': 'assets/poissons.png',    'title': 'Poisson mixé',     'desc': 'Oméga 3'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe mixée sans sel','desc': 'Légumes frais'},
        ],
      };
    }

    
    if (hasDysphagie) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Bouillie lisse',   'desc': 'Lait + avoine'},
        ],
        'Collation': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Crème dessert',    'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/puree.jpg',       'title': 'Purée de légumes', 'desc': 'Vitamines'},
          {'asset': 'assets/viande_hachée.jpg','title': 'Viande mixée',    'desc': 'Protéines'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe mixée',      'desc': 'Hydratation'},
        ],
      };
    }

    
    if ((hasDenutrition || imc < 18.5) && hasDiabetes) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait entier',      'desc': 'Calcium + calories'},
          {'asset': 'assets/cereales_completes.jpg','title': 'Céréales complètes','desc': 'Sans sucre ajouté'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt nature',   'desc': 'Protéines'},
          {'asset': 'assets/amandes.jpg',      'title': 'Amandes',         'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/viandes_rouges.png','title': 'Viande',         'desc': 'Protéines'},
          {'asset': 'assets/legumes.jpg',       'title': 'Légumes variés', 'desc': 'Fibres'},
        ],
        'Dîner': [
          {'asset': 'assets/poissons.png',      'title': 'Poisson',        'desc': 'Oméga 3'},
        ],
      };
    }

    
    if (hasDenutrition || imc < 18.5) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait enrichi',     'desc': 'Poudre de lait'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt',           'desc': 'Calcium'},
          {'asset': 'assets/fromage.jpg',     'title': 'Biscuits',         'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/viande_rouges.png','title': 'Viande',          'desc': 'Protéines'},
          {'asset': 'assets/puree.jpg',        'title': 'Purée',           'desc': 'Beurre ajouté'},
        ],
        'Dîner': [
          {'asset': 'assets/omelette.jpg',    'title': 'Omelette (2 œufs)','desc': 'Protéines'},
          {'asset': 'assets/fromages.png',    'title': 'Fromage',          'desc': 'Calcium + calories'},
        ],
      };
    }

    
    if (hasDiabetes && hasHTA) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/pain_complet.jpg','title': 'Pain complet',     'desc': 'IG bas'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt nature',   'desc': 'Probiotiques'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poissons.png',    'title': 'Poisson',          'desc': 'Oméga 3'},
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes',          'desc': 'Sans sel'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe',            'desc': 'Sans sel'},
          {'asset': 'assets/poulet.jpg',      'title': 'Poulet',           'desc': 'Protéines maigres'},
        ],
      };
    }

   
    if (hasDiabetes) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/pain_complet.jpg','title': 'Pain complet',     'desc': 'IG bas'},
          {'asset': 'assets/oeuf.jpg',        'title': 'Œuf',              'desc': 'Protéines'},
        ],
        'Collation': [
          {'asset': 'assets/yaourt_nature.jpg','title': 'Yaourt nature',   'desc': 'IG bas'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poissons.png',    'title': 'Poisson',          'desc': 'Oméga 3'},
          {'asset': 'assets/quinoa.jpg',      'title': 'Quinoa',           'desc': 'Protéines végétales'},
        ],
        'Dîner': [
          {'asset': 'assets/poulet.jpg',      'title': 'Poulet',           'desc': 'Protéines'},
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes',          'desc': 'Fibres'},
        ],
      };
    }

    
    if (hasHTA) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/pain_complet.jpg','title': 'Pain complet',     'desc': 'Fibres'},
        ],
        'Collation': [
          {'asset': 'assets/fruits.png',      'title': 'Fruits frais',     'desc': 'Potassium'},
        ],
        'Déjeuner': [
          {'asset': 'assets/poissons.png',    'title': 'Poisson',          'desc': 'Oméga 3'},
          {'asset': 'assets/legumes_vapeur.jpg','title': 'Légumes vapeur', 'desc': 'Sans sel ajouté'},
        ],
        'Dîner': [
          {'asset': 'assets/salade.jpg',      'title': 'Salade',           'desc': 'Antioxydants'},
          {'asset': 'assets/poulet.jpg',      'title': 'Viande blanche',   'desc': 'Protéines maigres'},
        ],
      };
    }

   
    if (hasConstipation) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/avoine.jpg',      'title': 'Avoine',           'desc': 'Transit'},
          {'asset': 'assets/fruits.png',      'title': 'Fruit frais',      'desc': 'Vitamines'},
        ],
        'Collation': [
          {'asset': 'assets/pruneaux.jpg',    'title': 'Pruneaux',         'desc': 'Laxatif naturel'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt probiotique','desc': 'Transit'},
        ],
        'Déjeuner': [
          {'asset': 'assets/lentilles.jpg',   'title': 'Lentilles',        'desc': 'Fibres ++'},
        ],
        'Dîner': [
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes variés',   'desc': 'Vitamines'},
        ],
      };
    }

    
    if (age >= 80) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Bouillie lisse',   'desc': 'Texture adaptée'},
          {'asset': 'assets/puree.jpg',       'title': 'Compote',          'desc': 'Vitamines'},
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait chaud',       'desc': 'Calcium'},
        ],
        'Collation': [
          {'asset': 'assets/bouillie.jpg',    'title': 'Crème dessert',    'desc': 'Énergie'},
        ],
        'Déjeuner': [
          {'asset': 'assets/puree.jpg',       'title': 'Purée légumes',    'desc': 'Texture adaptée'},
          {'asset': 'assets/poisson.jpg',     'title': 'Poisson mixé',     'desc': 'Oméga 3'},
          {'asset': 'assets/yaourt.jpg',      'title': 'Yaourt',           'desc': 'Calcium'},
        ],
        'Dîner': [
          {'asset': 'assets/soupe.jpg',       'title': 'Soupe mixée',      'desc': 'Hydratation'},
          {'asset': 'assets/bouillie.jpg',    'title': 'Crème dessert',    'desc': 'Énergie'},
        ],
      };
    }

   
    if (age < 65) {
      return {
        'Petit déjeuner': [
          {'asset': 'assets/lait_enrichi.jpg','title': 'Lait',             'desc': 'Calcium'},
          {'asset': 'assets/avoine.jpg',      'title': 'Céréales complètes','desc': 'Énergie lente'},
          {'asset': 'assets/fruits.png',      'title': 'Fruit frais',      'desc': 'Vitamines'},
        ],
        'Collation': [
          {'asset': 'assets/amandes.jpg',     'title': 'Amandes',          'desc': 'Énergie'},
          {'asset': 'assets/noix.jpg',        'title': 'Noix',             'desc': 'Oméga 3'},
        ],
        'Déjeuner': [
          {'asset': 'assets/viande_rouges.jpg','title': 'Viande',          'desc': 'Protéines'},
          {'asset': 'assets/riz_complet.jpg', 'title': 'Pâtes complètes',  'desc': 'Fibres'},
          {'asset': 'assets/legumes.jpg',     'title': 'Légumes variés',   'desc': 'Vitamines'},
        ],
        'Dîner': [
          {'asset': 'assets/poisson.jpg',     'title': 'Poisson',          'desc': 'Oméga 3'},
          {'asset': 'assets/legumes.jpg',     'title': 'Salade',           'desc': 'Antioxydants'},
          {'asset': 'assets/amandes.jpg',     'title': 'Amandes',          'desc': 'Énergie'},
          {'asset': 'assets/noix.jpg',        'title': 'Noix',             'desc': 'Oméga 3'},
        ],
      };
    }

    
    return {
      'Petit déjeuner': [
        {'asset': 'assets/pain.jpg',        'title': 'Pain',               'desc': 'Calcium (faible protéines)'},
        {'asset': 'assets/fruits.png',      'title': 'Fruit',              'desc': 'Vitamines'},
      ],
      'Collation': [
        {'asset': 'assets/fruits.png',      'title': 'Fruit',              'desc': 'Vitamines'},
        {'asset': 'assets/amandes.jpg',     'title': 'Amandes',            'desc': 'Énergie'},
      ],
      'Déjeuner': [
        {'asset': 'assets/poulet.jpg',      'title': 'Poulet',             'desc': 'Protéines'},
        {'asset': 'assets/legumes.jpg',     'title': 'Légumes',            'desc': 'Vitamines'},
      ],
      'Dîner': [
        {'asset': 'assets/poissons.png',    'title': 'Poisson',            'desc': 'Oméga 3'},
        {'asset': 'assets/soupe.jpg',       'title': 'Soupe',              'desc': 'Hydratation'},
      ],
    };
  }

  

  Widget _buildTipsSection() {
    final tips = _getTips();
    return Column(
      children: tips.map((tip) {
        bool isDanger = tip['title']!.contains('DANGER') ||
            tip['desc']!.contains('obligatoire') ||
            tip['title']!.contains('Dysphagie') ||
            tip['title']!.contains('fausse route');
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDanger ? Colors.red.withOpacity(0.12) : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDanger ? Colors.red.withOpacity(0.5) : Colors.white30),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tip['title']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDanger ? Colors.red[200] : Colors.white,
                  fontSize: 14,
                )),
              const SizedBox(height: 3),
              Text(tip['desc']!,
                style: TextStyle(
                  color: isDanger ? Colors.red[100] : Colors.white.withOpacity(0.85),
                  fontSize: 13,
                )),
            ])),
          ]),
        );
      }).toList(),
    );
  }

 

  Widget _buildHealthyGrid() {
    final foods = _getHealthyFoods();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: foods.map((f) => _foodCard(f['asset']!, f['title']!, f['desc']!)).toList(),
    );
  }

  Widget _buildAvoidGrid() {
    final foods = _getAvoidFoods();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: foods.map((f) => _foodCard(f['asset']!, f['title']!, f['desc']!)).toList(),
    );
  }

  

  Widget _buildComorbiditiesSection() {
    bool isAlzheimer = widget.diseaseType == 'Alzheimer';
    return _buildCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Maladies associées',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _comorbidityChip('Diabète',      hasDiabetes,     (v) => setState(() => hasDiabetes     = v)),
            _comorbidityChip('HTA',          hasHTA,          (v) => setState(() => hasHTA          = v)),
            _comorbidityChip('Dysphagie',    hasDysphagie,    (v) => setState(() => hasDysphagie    = v)),
            _comorbidityChip('Dénutrition',  hasDenutrition,  (v) => setState(() => hasDenutrition  = v)),
            _comorbidityChip('Constipation', hasConstipation, (v) => setState(() => hasConstipation = v)),
            if (isAlzheimer) ...[
              _comorbidityChip('AVC',        hasAVC,          (v) => setState(() => hasAVC          = v)),
              _comorbidityChip('Dépression', hasDepression,   (v) => setState(() => hasDepression   = v)),
              _comorbidityChip('Épilepsie',  hasEpilepsie,    (v) => setState(() => hasEpilepsie    = v)),
            ],
          ],
        ),
      ]),
    );
  }

  Widget _comorbidityChip(String label, bool selected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryBlue : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryBlue : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          )),
      ),
    );
  }

  

  Widget _buildWeightRuler() => _buildCard(
    child: Column(children: [
      _buildMetricInfo("Poids", "$weight", "kg"),
      const SizedBox(height: 10),
      SizedBox(
        height: 80,
        child: RotatedBox(
          quarterTurns: -1,
          child: ListWheelScrollView.useDelegate(
            controller: _weightController,
            itemExtent: 45,
            onSelectedItemChanged: (i) => setState(() => weight = i + 30),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 121,
              builder: (context, index) {
                int val = index + 30;
                return RotatedBox(quarterTurns: 1,
                  child: Column(children: [
                    Container(width: 2, height: val % 5 == 0 ? 35 : 18,
                      color: val == weight ? primaryBlue : Colors.grey.withOpacity(0.5)),
                    if (val % 5 == 0)
                      Padding(padding: const EdgeInsets.only(top: 5),
                        child: Text("$val", style: TextStyle(fontSize: 10,
                          color: val == weight ? primaryBlue : Colors.black54))),
                  ]));
              },
            ),
          ),
        ),
      ),
      Icon(Icons.arrow_drop_up, color: primaryGreen, size: 30),
    ]),
  );

  Widget _buildHeightRuler() => _buildCard(
    child: Column(children: [
      _buildMetricInfo("Taille", "$height", "cm"),
      const SizedBox(height: 10),
      SizedBox(
        height: 80,
        child: RotatedBox(
          quarterTurns: -1,
          child: ListWheelScrollView.useDelegate(
            controller: _heightController,
            itemExtent: 45,
            onSelectedItemChanged: (i) => setState(() => height = i + 100),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 121,
              builder: (context, index) {
                int val = index + 100;
                return RotatedBox(quarterTurns: 1,
                  child: Column(children: [
                    Container(width: 2, height: val % 5 == 0 ? 35 : 18,
                      color: val == height ? primaryGreen : Colors.grey.withOpacity(0.5)),
                    if (val % 5 == 0)
                      Padding(padding: const EdgeInsets.only(top: 5),
                        child: Text("$val", style: TextStyle(fontSize: 10,
                          color: val == height ? primaryGreen : Colors.black54))),
                  ]));
              },
            ),
          ),
        ),
      ),
      Icon(Icons.arrow_drop_up, color: primaryBlue, size: 30),
    ]),
  );

  Widget _buildAgePicker() => _buildCard(
    child: Column(children: [
      _buildMetricInfo("Âge", "${age.toInt()}", "ans"),
      SizedBox(
        height: 100,
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: (age - 40).toInt()),
          itemExtent: 35,
          onSelectedItemChanged: (i) => setState(() => age = (i + 40).toDouble()),
          children: List.generate(61, (i) => Center(
            child: Text("${i + 40}", style: TextStyle(color: primaryBlue)))),
        ),
      ),
    ]),
  );

  Widget _buildVitalSliders() => _buildCard(
    child: Column(children: [
      _buildVitalSlider("Pression", pressure, 80, 180, "mmHg"),
      const Divider(),
      _buildVitalSlider("Glucose",  sugar,    60, 200, "mg/dL"),
    ]),
  );

  Widget _buildAnalyzeButton() => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _calculateMetrics,
    child: Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [primaryBlue, primaryGreen]),
      ),
      child: const Center(
        child: Text("ANALYSER",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ),
  );

  Widget _buildDiagnosticSection() {
    final bool isAlzheimer = widget.diseaseType == 'Alzheimer';

    double imcCircleVal;
    if (imc >= 21 && imc <= 25) {
      imcCircleVal = 1.0;
    } else if (imc < 21) {
      imcCircleVal = (imc / 21).clamp(0.1, 1.0);
    } else {
      imcCircleVal = (1.0 - ((imc - 25) / 20)).clamp(0.1, 1.0);
    }

    final nutritionScore = isAlzheimer
        ? (cognitiveScore * 0.5 + motorScore * 0.5).clamp(0.0, 1.0)
        : (cognitiveScore * 0.4 + motorScore * 0.3 + vascScore * 0.3).clamp(0.0, 1.0);

    String imcStateLabel;
    if (imc < 18.5)       imcStateLabel = 'Dénutrition';
    else if (imc < 21)    imcStateLabel = 'Risque';
    else if (imc < 25)    imcStateLabel = 'Normal';
    else if (imc < 30)    imcStateLabel = 'Surpoids';
    else                  imcStateLabel = 'Obésité';

    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildImcCircle(imcCircleVal, imcStateLabel),
            _buildNutritionCircle(nutritionScore),
          ],
        ),
        const SizedBox(height: 16),
        ..._buildCircleTips(),
      ]),
    );
  }

  Widget _buildImcCircle(double val, String stateLabel) {
    Color statusColor;
    if (imc >= 21 && imc <= 25)       statusColor = Colors.green;
    else if (imc >= 18.5 && imc < 21) statusColor = Colors.orange;
    else if (imc >= 25 && imc < 30)   statusColor = Colors.orange;
    else                               statusColor = Colors.red;

    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 90, height: 90,
          child: CircularProgressIndicator(
            value: val,
            color: statusColor,
            strokeWidth: 9,
            backgroundColor: Colors.grey.withOpacity(0.15),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.monitor_weight_outlined, color: statusColor, size: 16),
          const SizedBox(height: 2),
          Text(
            imc.toStringAsFixed(1),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
          ),
          Text('kg/m²', style: TextStyle(fontSize: 9, color: statusColor.withOpacity(0.8))),
        ]),
      ]),
      const SizedBox(height: 8),
      const Text('IMC\nIndice Corporel',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('${weight}kg / ${height}cm',
        style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Text(stateLabel,
          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _buildNutritionCircle(double val) {
    Color statusColor;
    String statusText;
    if (val >= 0.75)      { statusColor = Colors.green;  statusText = 'Bon'; }
    else if (val >= 0.50) { statusColor = Colors.orange; statusText = 'Moyen'; }
    else                  { statusColor = Colors.red;    statusText = 'Faible'; }

    List<String> factors = [];
    if (sugar > 140 || hasDiabetes)     factors.add('Sucre↑');
    if (pressure > 140 || hasHTA)       factors.add('TA↑');
    if (hasDenutrition || imc < 18.5)   factors.add('Dénut.');
    if (hasDysphagie)                   factors.add('Dysph.');
    if (hasConstipation)                factors.add('Const.');
    if (hasAVC)                         factors.add('AVC');
    if (hasDepression)                  factors.add('Dép.');
    if (hasEpilepsie)                   factors.add('Épil.');
    String factorStr = factors.isEmpty ? 'Équilibré' : factors.join(' · ');

    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 90, height: 90,
          child: CircularProgressIndicator(
            value: val,
            color: statusColor,
            strokeWidth: 9,
            backgroundColor: Colors.grey.withOpacity(0.15),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.health_and_safety_outlined, color: statusColor, size: 16),
          const SizedBox(height: 2),
          Text(
            '${(val * 100).toInt()}%',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
          ),
          Text('score', style: TextStyle(fontSize: 9, color: statusColor.withOpacity(0.8))),
        ]),
      ]),
      const SizedBox(height: 8),
      const Text('Nutrition\nScore Global',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(factorStr,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, color: Colors.grey)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Text(statusText,
          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  List<Widget> _buildCircleTips() {
    List<Widget> tips = [];
    final bool isAlzheimer = widget.diseaseType == 'Alzheimer';

    void addTip(String emoji, String text, Color color) {
      tips.add(Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text,
            style: TextStyle(color: color, fontSize: 12, height: 1.4))),
        ]),
      ));
    }

    if (isAlzheimer) {
      if (hasAVC)
        addTip('🫀', 'AVC — Régime cardio-protecteur : oméga 3 (poisson, huile d\'olive), anti-cholestérol. Éviter graisses saturées', primaryBlue);
      if (hasDepression)
        addTip('🍫', 'Dépression — Magnésium ↑, oméga 3 ↑. Alimentation : lait + chocolat noir + poisson + banane', primaryBlue);
      if (hasEpilepsie)
        addTip('⚡', 'Épilepsie — Éviter hypoglycémie. Repas réguliers obligatoires, ne jamais sauter un repas', Colors.orange);
      if (cognitiveScore < 0.60)
        addTip('🧠', 'Protection neuronale faible — Oméga 3, antioxydants, hydratation. Régime : poisson + légumes + riz complet', primaryBlue);
      if (motorScore < 0.55)
        addTip('⚠️', 'Dénutrition — Apport énergétique ↑. Enrichissement : lait enrichi, purée enrichie. Fractionnement 5 prises/j', Colors.red);
      if (vascScore < 0.55)
        addTip('❤️', 'Risque vasculaire — Réduction sel, hydratation ↑, régime DASH adapté', Colors.orange);
      if (hasDysphagie)
        addTip('🥣', 'Dysphagie — Texture lisse obligatoire (purée, soupe mixée). Risque de fausse route', Colors.red);
      if (age >= 80)
        addTip('💧', '≥ 80 ans — Hydratation 1,5–2L/j, textures adaptées, enrichissement protéique', primaryBlue);
    } else {
      if (cognitiveScore < 0.60)
        addTip('💊', 'Efficacité Lévodopa réduite — Éviter protéines le matin. Réserver au dîner uniquement', primaryBlue);
      else if (cognitiveScore < 0.80)
        addTip('💊', 'Interaction Lévodopa/protéines — Protéines à midi et au dîner uniquement', primaryBlue);
      if (motorScore < 0.55)
        addTip('🚶', 'Mobilité réduite — Fibres ↑↑ (avoine, lentilles, pruneaux) + eau 6–8 verres/j', Colors.red);
      else if (hasConstipation)
        addTip('🌾', 'Constipation (très fréquent Parkinson) — Fibres ↑↑ + hydratation ++. Pruneaux, lentilles, avoine', primaryGreen);
      else if (imc < 18.5)
        addTip('⚠️', 'Perte de poids — Fractionnement repas, enrichissement calorique : lait enrichi, purée enrichie', Colors.red);
      if (vascScore < 0.50)
        addTip('⚖️', 'Double contrainte (HTA + Diabète) — Régime restrictif → risque carence. IG bas + sel ↓', Colors.orange);
      else if (hasDysphagie && hasDenutrition)
        addTip('🥣', 'Dysphagie + Dénutrition — Texture mixée enrichie. Équilibre difficile, appétit souvent réduit', Colors.red);
      else if (hasDysphagie)
        addTip('🥣', 'Dysphagie — Texture lisse obligatoire. Risque de fausse route élevé dans Parkinson', Colors.red);
      else if (htaDetectedCache)
        addTip('🧂', 'HTA — Sel ↓ (produits industriels cachés), potassium ↑ (légumes, fruits), régime DASH', Colors.orange);
    }
    return tips;
  }

  

  Widget _buildCircleStat(String label, double val, Color col, IconData icon) {
    String statusText;
    Color statusColor;
    if (val >= 0.75) {
      statusText  = 'Bon';
      statusColor = Colors.green;
    } else if (val >= 0.50) {
      statusText  = 'Moyen';
      statusColor = Colors.orange;
    } else {
      statusText  = 'Faible';
      statusColor = Colors.red;
    }

    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 80, height: 80,
          child: CircularProgressIndicator(
            value: val,
            color: statusColor,
            strokeWidth: 8,
            backgroundColor: Colors.grey.withOpacity(0.15),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: statusColor, size: 18),
          const SizedBox(height: 2),
          Text(
            "${(val * 100).toInt()}%",
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ]),
      ]),
      const SizedBox(height: 8),
      Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Text(statusText,
          style: TextStyle(
            fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _foodCard(String image, String title, String desc) {
    bool isDanger = desc.contains("DANGER") || desc.contains("éviter");
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                    Text(desc,
                      style: TextStyle(
                        color: isDanger ? Colors.red[300] : Colors.white70,
                        fontSize: 10,
                        fontWeight: isDanger ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ),
            if (isDanger)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String image, String title, String subtitle) {
    return Container(
      height: 110, width: 155,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(image, height: 35,
          errorBuilder: (c, e, s) => const Icon(Icons.info)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
    ),
    child: child,
  );

  Widget _buildMetricInfo(String t, String v, String u) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(t, style: const TextStyle(color: Colors.grey)),
      Text("$v $u", style: TextStyle(
        color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
    ],
  );

  Widget _buildVitalSlider(String t, double v, double min, double max, String u) {
    bool isPression = t.contains("Pression");
    Color sliderColor;
    String zoneLabel;
    IconData zoneIcon;

    if (isPression) {
      if (v < 90)        { sliderColor = Colors.blue;  zoneLabel = "Bas";    zoneIcon = Icons.arrow_downward_rounded; }
      else if (v <= 140) { sliderColor = primaryGreen; zoneLabel = "Normal"; zoneIcon = Icons.check_circle_outline; }
      else               { sliderColor = Colors.red;   zoneLabel = "Élevé";  zoneIcon = Icons.arrow_upward_rounded; }
    } else {
      if (v < 70)        { sliderColor = Colors.blue;  zoneLabel = "Bas";    zoneIcon = Icons.arrow_downward_rounded; }
      else if (v <= 140) { sliderColor = primaryGreen; zoneLabel = "Normal"; zoneIcon = Icons.check_circle_outline; }
      else               { sliderColor = Colors.red;   zoneLabel = "Élevé";  zoneIcon = Icons.arrow_upward_rounded; }
    }

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(t, style: const TextStyle(color: Colors.grey)),
        Row(children: [
          Icon(zoneIcon, color: sliderColor, size: 16),
          const SizedBox(width: 4),
          Text("${v.toInt()} $u",
            style: TextStyle(color: sliderColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: sliderColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sliderColor.withOpacity(0.4))),
            child: Text(zoneLabel,
              style: TextStyle(color: sliderColor, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor:   sliderColor,
          inactiveTrackColor: sliderColor.withOpacity(0.2),
          thumbColor:         sliderColor,
          overlayColor:       sliderColor.withOpacity(0.15),
          trackHeight:        5,
        ),
        child: Slider(
          value: v, min: min, max: max,
          onChanged: (val) => setState(() =>
              isPression ? pressure = val : sugar = val),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isPression ? "Bas\n<90"  : "Bas\n<70",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.blue)),
          Text(isPression ? "Normal\n90–140" : "Normal\n70–140",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: primaryGreen)),
          Text("Élevé\n>140",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: Colors.red)),
        ]),
      ),
    ]);
  }
}


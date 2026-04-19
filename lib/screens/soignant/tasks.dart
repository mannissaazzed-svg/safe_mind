import 'package:flutter/material.dart';
import 'package:safemind/screens/task_status.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});
  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  int selectedIndex = 0;
  List<DateTime> days = List.generate(14, (i) => DateTime.now().add(Duration(days: i)));

  
List<List<TaskData>> weekTasks = [
  [
    TaskData("Prendre médicaments", Colors.indigo,
      ["19:45 Veuillez prendre votre dose de Donepezil", "00:26 Il est temps de prendre votre Vitamine"], "assets/medicine.png"),
    
    TaskData("Repas équilibré", Colors.orange,
      ["08:30 C'est l'heure de prendre votre Petit déjeuner", "13:00 Veuillez prendre votre Déjeuner"], "assets/food.png"),
    
    TaskData("Activité physique", Colors.green,
      ["10:00 Il est l'heure de faire votre Marche", "10:30 Veuillez commencer vos Exercices"], "assets/sport.png"),
    
    TaskData("Activité cognitive", Colors.lime,
      ["16:00 Il est temps de jouer au Jeu de mémoire", "16:30 C'est le moment de votre Lecture"], "assets/brain.png"),
    
    TaskData("Médicaments soir", Colors.purple,
      ["20:00 Prenez vos médicaments du soir", "23:54 Veuillez vérifier vos prises"], "assets/medicine.png"),
  ],

  [
    TaskData("Prendre médicaments", Colors.indigo,
      ["08:00 Veuillez prendre la Rivastigmine", "09:00 C'est l'heure de la Vitamine B12"], "assets/medicine.png"),
      
    TaskData("Repas équilibré", Colors.orange,
      ["08:30 Mangez vos Fruits", "13:00 C'est l'heure de manger le Couscous"], "assets/food.png"),
      
    TaskData("Activité physique", Colors.green,
      ["10:00 Allez faire votre Marche", "10:30 Faites vos exercices pour les bras"], "assets/sport.png"),
      
    TaskData("Activité cognitive", Colors.lime,
      ["16:00 Commencez votre Puzzle", "16:30 Il est temps de lire un peu"], "assets/brain.png"),
      
    TaskData("Médicaments soir", Colors.purple,
      ["20:00 Prenez votre Traitement", "20:15 N'oubliez pas de boire de l'Eau"], "assets/medicine.png"),
  ],
    
  [
    TaskData("Prendre médicaments", Colors.indigo,
      ["08:00 Prenez vos Médicaments maintenant"], "assets/medicine.png"),
      
    TaskData("Repas équilibré", Colors.orange,
      ["13:00 C'est l'heure de votre Déjeuner"], "assets/food.png"),
      
    TaskData("Activité physique", Colors.green,
      ["10:00 Il est temps de faire votre Marche"], "assets/sport.png"),
      
    TaskData("Activité cognitive", Colors.lime,
      ["16:00 Commencez votre séance de Lecture"], "assets/brain.png"),
  ],
      
  [
    TaskData("Prendre médicaments", Colors.indigo,
      ["08:00 Veuillez prendre votre Traitement"], "assets/medicine.png"),
      
    TaskData("Repas équilibré", Colors.orange,
      ["13:00 Mangez votre plat de Riz"], "assets/food.png"),
  ],
      
  [
    TaskData("Prendre médicaments", Colors.indigo,
      ["08:00 Prenez vos Médicaments habituels"], "assets/medicine.png"),
      
    TaskData("Activité physique", Colors.green,
      ["10:00 C'est le moment de votre Marche"], "assets/sport.png"),
  ],
    
  [
    TaskData("Activité cognitive", Colors.lime,
      ["16:00 Allez faire votre Jeu de mémoire"], "assets/brain.png"),
  ],
    
  [
    TaskData("Rendez-vous médecin", Colors.red,
      ["11:00 Préparez-vous pour votre RDV chez le Médecin"], "assets/doctor.png"),
  ],
];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TaskStatus.notifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white, elevation: 0,
            title: const Text("Suivi Patient", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buildDaysList(),
                const SizedBox(height: 25),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildTimeline(),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: weekTasks[selectedIndex % weekTasks.length]
                              .map((task) => buildTaskCard(task)).toList(),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTimeline() {
    List<Widget> timelineElements = [];
    final tasks = weekTasks[selectedIndex % weekTasks.length];

    for (var task in tasks) {
      for (var item in task.list) {
        final key = "${task.title}-$item";
        timelineElements.add(
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 16, width: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: TaskStatus.getStatus(key), width: 4),
                ),
              ),
              Container(height: 75, width: 2, color: Colors.grey.shade200),
            ],
          ),
        );
      }
    }
    return Column(children: timelineElements);
  }

  
  Widget buildTaskCard(TaskData task) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: task.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Image.asset(task.image, width: 35), const SizedBox(width: 10), Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: task.color))]),
          const SizedBox(height: 10),
          ...task.list.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(e, style: const TextStyle(fontSize: 13)))),
        ],
      ),
    );
  }

  Widget buildDaysList() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final d = days[index];
          bool isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: isSelected ? Colors.indigo : Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"][d.weekday - 1], style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                Text(d.day.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
              ]),
            ),
          );
        },
      ),
    );
  }
}













import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:safemind/screens/task_status.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});
  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? timer;
  Map<String, int> attempts = {}; 
  Set<String> firedTasks = {};
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
  void initState() {
    super.initState();
    initNotification();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => checkTasks());
  }

  Future initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: android));
  }

  void checkTasks() {
    final now = DateTime.now();
    final currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final tasks = weekTasks[selectedIndex % weekTasks.length];

    for (var task in tasks) {
      for (var item in task.list) {
        final time = item.split(" ")[0];
        final key = "${task.title}-$item";

        if (time == currentTime && !firedTasks.contains(key)) {
          firedTasks.add(key);
          triggerTaskFlow(task.title, item, task.image);
        }
      }
    }
  }

  void triggerTaskFlow(String title, String body, String image) {
    showNotification(title, body);
    showDialogTask(title, body, image);
  }

  Future showNotification(String title, String body) async {
    
    const android = AndroidNotificationDetails("tasks", "Mes Tâches", importance: Importance.max, priority: Priority.high);
    await flutterLocalNotificationsPlugin.show(0, title, body, const NotificationDetails(android: android));
  }

  void showDialogTask(String title, String body, String image) {
    final key = "$title-$body";
    int attempt = attempts[key] ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(image, width: 70),
              const SizedBox(height: 15),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Text(
                "Vous devez effectuer cette tâche (Tentative $attempt):\n$body", 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F6BDE), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () {
                        TaskStatus.setStatus(key, attempt == 1 ? Colors.green : Colors.orange);
                        Navigator.pop(context);
                        setState(() {});
                      },
                     
                      child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (attempt < 3) {
                          attempts[key] = attempt + 1;
                          Timer(const Duration(minutes: 2), () => triggerTaskFlow(title, body, image));
                        } else {
                          TaskStatus.setStatus(key, Colors.red);
                          setState(() {});
                        }
                      },
                      
                      child: const Text("Annuler", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text("Mes tâches", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildDaysList(),
            const SizedBox(height: 20),
            ...weekTasks[selectedIndex % weekTasks.length].map((task) => buildTaskCard(task)).toList(),
          ],
        ),
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
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"][d.weekday - 1],
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  Text(d.day.toString(),
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTaskCard(TaskData task) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: task.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(task.image, width: 40),
              const SizedBox(width: 15),
              Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, color: task.color, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ...task.list.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [Icon(Icons.notifications, color: task.color, size: 18), const SizedBox(width: 10), Text(item)]),
              )),
        ],
      ),
    );
  }
}









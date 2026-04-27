import 'package:flutter/material.dart';
import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/soignant/check.dart';

class CaregiverAddTasks extends StatefulWidget {
  const CaregiverAddTasks({super.key});

  @override
  State<CaregiverAddTasks> createState() => _CaregiverAddTasksState();
}

class _CaregiverAddTasksState extends State<CaregiverAddTasks> {
  DateTime selectedDate = DateTime.now();

  
  Map<String, List<Map<String, dynamic>>> tasksByDate = {};

  String get dateKey => selectedDate.toIso8601String().split("T")[0];

  List<Map<String, dynamic>> get tasks =>
      tasksByDate[dateKey] ?? [];

  
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  
  Map<String, Map<String, dynamic>> taskTypes = {
    "medicine": {
      "color": "indigo",
      "image": "assets/medicine.png"
    },
    "food": {
      "color": "orange",
      "image": "assets/food.png"
    },
    "sport": {
      "color": "green",
      "image": "assets/sport.png"
    },
    "brain": {
      "color": "lime",
      "image": "assets/brain.png"
    },
  };

 
  void addOrEditTask({Map<String, dynamic>? task, int? index}) {
    TextEditingController title =
        TextEditingController(text: task?["title"] ?? "");
    TextEditingController detail =
        TextEditingController(text: task?["detail"] ?? "");

    TimeOfDay selectedTime = task != null
        ? TimeOfDay(
            hour: int.parse(task["time"].split(":")[0]),
            minute: int.parse(task["time"].split(":")[1]),
          )
        : TimeOfDay.now();

    String selectedType = task?["type"] ?? "medicine";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task == null ? "Nouvelle tâche" : "Modifier tâche"),

                const SizedBox(height: 10),

                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    hintText: "Titre",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: detail,
                  decoration: const InputDecoration(
                    hintText: "Détails",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

               
                Row(
                  children: [
                    const Icon(Icons.access_time),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (t != null) {
                          setStateDialog(() => selectedTime = t);
                        }
                      },
                      child: Text(selectedTime.format(context)),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

               
                DropdownButton<String>(
                  value: selectedType,
                  items: taskTypes.keys.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setStateDialog(() => selectedType = v!);
                  },
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newTask = {
                            "title": title.text,
                            "detail": detail.text,
                            "time":
                                "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                            "type": selectedType,
                          };

                          setState(() {
                            tasksByDate.putIfAbsent(dateKey, () => []);

                            if (task == null) {
                             
                              tasksByDate[dateKey]!.add(newTask);
                            } else {
                             
                              tasksByDate[dateKey]![index!] = newTask;
                            }
                          });

                          Navigator.pop(context);
                        },
                        child: Text(task == null ? "Ajouter" : "Modifier"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  
  void deleteTask(int index) {
    setState(() {
      tasksByDate[dateKey]!.removeAt(index);
    });
  }

  Future sendTasks() async {
    if (tasks.isEmpty) return;

    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var t in tasks) {
      grouped.putIfAbsent(t["type"], () => []);
      grouped[t["type"]]!.add(t);
    }

    for (var type in grouped.keys) {
      final info = taskTypes[type]!;

      await SupabaseService.client.from('tasks').insert({
        "patient_id": SupabaseService.patientId,
        "task_date": selectedDate.toIso8601String(),
        "title": type,
        "color": info["color"],
        "image": info["image"],
        "sub_tasks": grouped[type]!
            .map((t) => {
                  "title": "${t["time"]} ${t["detail"]}"
                })
            .toList(),
        "status": {}
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tâches envoyées")),
    );
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planifier les tâches"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(dateKey),
                IconButton(
                  onPressed: pickDate,
                  icon: const Icon(Icons.calendar_month),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => addOrEditTask(),
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter tâche"),
                )
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text("Aucune tâche"))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final t = tasks[index];

                        return ListTile(
                          title: Text(t["title"]),
                          subtitle:
                              Text("${t["time"]} - ${t["detail"]}"),

                        
                          onTap: () =>
                              addOrEditTask(task: t, index: index),

                          
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteTask(index),
                          ),
                        );
                      },
                    ),
            ),

            if (tasks.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: sendTasks,
                      child: const Text("Envoyer au patient"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Tasks(),
                          ),
                        );
                      },
                      child: const Text("Suivi"),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}

/*               },
                    child: const Text("Choisir l'heure"),
                  )
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          tasks.add({
                            "title": title.text,
                            "detail": "${time.format(context)} ${detail.text}"
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Ajouter"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler"),
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

  // 📤 إرسال المهام
  Future sendTasks() async {
    for (var t in tasks) {
      await SupabaseService.client.from('tasks').insert({
        "patient_id": SupabaseService.patientId,
        "task_date": selectedDate.toIso8601String(),
        "title": t["title"],
        "color": "indigo",
        "image": "assets/medicine.png",
        "sub_tasks": [
          {"title": t["detail"]}
        ],
        "status": {}
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tâches envoyées")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planifier les tâches"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text("${selectedDate.toLocal()}".split(" ")[0]),
                IconButton(onPressed: pickDate, icon: const Icon(Icons.calendar_month)),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed: addTaskDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter tâche"),
                )
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text("Aucune tâche"))
                  : ListView(
                      children: tasks.map((t) {
                        return ListTile(
                          title: Text(t["title"]),
                          subtitle: Text(t["detail"]),
                        );
                      }).toList(),
                    ),
            ),

            // 👇 يظهر فقط إذا يوجد مهام
            if (tasks.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: sendTasks,
                      child: const Text("Envoyer au patient"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CaregiverTasksView()),
                        );
                      },
                      child: const Text("Suivi"),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
*/






/*import 'package:flutter/material.dart';
import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/soignant/check.dart';

class CaregiverAddTasks extends StatefulWidget {
  const CaregiverAddTasks({super.key});

  @override
  State<CaregiverAddTasks> createState() => _CaregiverAddTasksState();
}

class _CaregiverAddTasksState extends State<CaregiverAddTasks> {
  DateTime selectedDate = DateTime.now();
  List<Map> tasks = [];

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void addTaskDialog() {
    TextEditingController title = TextEditingController();
import 'package:flutter/material.dart';
import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/soignant/check.dart';

class CaregiverAddTasks extends StatefulWidget {
  const CaregiverAddTasks({super.key});

  @override
  State<CaregiverAddTasks> createState() => _CaregiverAddTasksState();
}

class _CaregiverAddTasksState extends State<CaregiverAddTasks> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> tasks = [];

  // 📅 اختيار التاريخ
  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ➕ إضافة مهمة
  void addTaskDialog() {
    TextEditingController title = TextEditingController();
    TextEditingController detail = TextEditingController();
    TimeOfDay time = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nouvelle tâche", style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              TextField(
                controller: title,
                decoration: const InputDecoration(
                  hintText: "Titre de la tâche",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: detail,
                decoration: const InputDecoration(
                  hintText: "Détails",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.access_time),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: time);
                      if (t != null) time = t;
         TextEditingController detail = TextEditingController();
    TimeOfDay time = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة مهمة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(hintText: "اسم المهمة")),
            TextField(controller: detail, decoration: const InputDecoration(hintText: "تفاصيل المهمة")),
            TextButton(
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: time);
                if (t != null) time = t;
              },
              child: const Text("اختيار الوقت"),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                tasks.add({
                  "title": title.text,
                  "detail": "${time.format(context)} ${detail.text}"
                });
              });
              Navigator.pop(context);
            },
            child: const Text("إضافة"),
          )
        ],
      ),
    );
  }

  Future sendTasks() async {
    for (var t in tasks) {
      await SupabaseService.client.from('tasks').insert({
        "patient_id": SupabaseService.patientId,
        "task_date": selectedDate.toIso8601String(),
        "title": t["title"],
        "color": "indigo",
        "image": "assets/medicine.png",
        "sub_tasks": [
          {"title": t["detail"]}
        ],
        "status": {}
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إرسال المهام")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة المهام")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text("${selectedDate.toLocal()}".split(" ")[0]),
                IconButton(onPressed: pickDate, icon: const Icon(Icons.calendar_month)),
                const Spacer(),
                IconButton(onPressed: addTaskDialog, icon: const Icon(Icons.add_circle, size: 35))
              ],
            ),

            Expanded(
              child: ListView(
                children: tasks.map((t) => ListTile(title: Text(t["title"]), subtitle: Text(t["detail"]))).toList(),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: sendTasks,
                    child: const Text("إرسال للمريض"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverTasksView()));
                    },
                    child: const Text("تفقد"),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
*/









/*import 'package:flutter/material.dart';
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
      ["12:26 Veuillez prendre votre dose de Donepezil", "00:26 Il est temps de prendre votre Vitamine"], "assets/medicine.png"),
    
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
*/












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

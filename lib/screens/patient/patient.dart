import 'package:flutter/material.dart';
import 'dart:async';

import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/task_model.dart';
import 'package:safemind/screens/task_status.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  Timer? timer;

  int selectedIndex = 0;

  List<TaskModel> currentTasks = [];
  Set<String> firedTasks = {};
  Map<String, int> attempts = {};

  List<DateTime> days =
      List.generate(14, (i) => DateTime.now().add(Duration(days: i)));

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkTasks();
    });
  }

 
  void updateTasks(List<TaskModel> tasks) {
    currentTasks = tasks;
  }

  
  void checkTasks() {
    final now = DateTime.now();

    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    for (var task in currentTasks) {
      for (var sub in task.subTasks) {
        final text = (sub is Map && sub['title'] != null)
            ? sub['title']
            : '';

        final time = text.split(" ")[0];
        final key = "${task.id}-$text";

        if (time == currentTime && !firedTasks.contains(key)) {
          firedTasks.add(key);
          showTaskDialog(task, text);
        }
      }
    }
  }

  
  void showTaskDialog(TaskModel task, String body) {
    final key = "${task.id}-$body";
    int attempt = attempts[key] ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(task.image, width: 70),
              const SizedBox(height: 15),

              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Tentative $attempt\n$body",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F6BDE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        TaskStatus.setStatus(key, Colors.green);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text(
                        "Confirmer",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);

                        if (attempt < 2) {
                          attempts[key] = attempt + 1;

                          TaskStatus.setStatus(key, Colors.orange);

                          Timer(const Duration(minutes: 5), () {
                            firedTasks.remove(key);
                            showTaskDialog(task, body);
                          });
                        } else {
                          TaskStatus.setStatus(key, Colors.red);
                        }

                        setState(() {});
                      },
                      child: const Text(
                        "Annuler",
                        style: TextStyle(color: Colors.white),
                      ),
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
    return StreamBuilder<List<TaskModel>>(
      stream: SupabaseService.streamTasksByDate(
        SupabaseService.patientId,
        days[selectedIndex],
      ),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        updateTasks(tasks);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Mes tâches"),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buildDaysList(),
                const SizedBox(height: 20),
                ...tasks.map((t) => buildTaskCard(t)).toList(),
              ],
            ),
          ),
        );
      },
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
          final isSelected = selectedIndex == index;

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
                  Text(
                    ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
                        [d.weekday - 1],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  
  Widget buildTaskCard(TaskModel task) {
    final color = task.getBaseColor(); // ✅ FIX HERE

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(task.image, width: 40),
              const SizedBox(width: 10),
              Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...task.subTasks.map((e) {
            final text = (e is Map && e['title'] != null)
                ? e['title']
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: color, size: 18),
                  const SizedBox(width: 10),
                  Text(text),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}







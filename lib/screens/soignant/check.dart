import 'package:flutter/material.dart';
import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/task_model.dart';
import 'package:safemind/screens/task_status.dart';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  int selectedIndex = 0;

  List<DateTime> days =
      List.generate(14, (i) => DateTime.now().add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: SupabaseService.streamTasksByDate(
        SupabaseService.patientId,
        days[selectedIndex],
      ),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              "Suivi Patient",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      buildTimeline(tasks),
                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          children: tasks.map((t) => buildTaskCard(t)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

 
  Widget buildTimeline(List<TaskModel> tasks) {
    List<Widget> items = [];

    for (var task in tasks) {
      for (var sub in task.subTasks) {
        final text = (sub is Map && sub['title'] != null)
            ? sub['title']
            : '';

        final key = "${task.id}-$text";

        items.add(
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: TaskStatus.getStatus(key),
                    width: 4,
                  ),
                ),
              ),
              Container(
                height: 75,
                width: 2,
                color: Colors.grey.shade200,
              ),
            ],
          ),
        );
      }
    }

    return Column(children: items);
  }

  Widget buildTaskCard(TaskModel task) {
    final color = task.getBaseColor();

    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(task.image, width: 35),
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }),
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
}
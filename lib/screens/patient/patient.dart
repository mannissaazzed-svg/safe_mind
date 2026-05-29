import 'package:flutter/material.dart';
import 'package:safemind/generated/l10n/app_localizations_ar.dart';
import 'dart:async';
import 'package:safemind/services/supabase_service.dart';
import 'package:safemind/screens/task_model.dart';
import 'package:safemind/screens/task_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

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
  _loadPatientId();
  timer = Timer.periodic(const Duration(seconds: 5), (_) => checkTasks());
}

String? _patientId;

Future<void> _loadPatientId() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  final data = await supabase
      .from('users')
      .select('linked_to, role')
      .eq('id', userId)
      .maybeSingle();

  setState(() {
    final role = data?['role'] as String?;
    _patientId = role == 'patient'
        ? userId
        : data?['linked_to'] as String?;
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
  final t = AppLocalizations.of(context)!;
  final key = "${task.id}-$body";
  int attempt = attempts[key] ?? 1;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(task.image, width: 70),
            const SizedBox(height: 15),
            Text(task.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            //Text("Tentative $attempt\n$body",
             Text(
                "${t.attempt} $attempt\n$body",
                textAlign: TextAlign.center,
              ),
           
            const SizedBox(height: 20),
            Row(
              children: [

                // ══════ CONFIRMER ══════
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F6BDE),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                     
                      final color = attempt == 1 ? "green" : "orange";

                      TaskStatus.setStatus(
                        key,
                        attempt == 1 ? Colors.green : Colors.orange,
                      );

                      
                      await SupabaseService.updateTaskStatus(
                        taskId: task.id,
                        subKey: body,
                        color: color,
                      );

                      setState(() {});
                    },
                    child:  Text(t.confirm,
                        style: TextStyle(color: Colors.white)),
                  ),
                ),

                const SizedBox(width: 10),

               
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      if (attempt < 2) {
                       
                        attempts[key] = attempt + 1;

                        Timer(const Duration(minutes: 5), () {
                          if (mounted) {
                            firedTasks.remove(key);
                            showTaskDialog(task, body);
                          }
                        });
                      } else {
                       
                        TaskStatus.setStatus(key, Colors.red);

                       
                        await SupabaseService.updateTaskStatus(
                          taskId: task.id,
                          subKey: body,
                          color: "red",
                        );
                      }

                      setState(() {});
                    },
                    child: Text(t.cancel,
                        style: TextStyle(color: Colors.white)),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  
  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;
    return StreamBuilder<List<TaskModel>>(
      stream: _patientId == null
    ? const Stream.empty()
    : SupabaseService.streamTasksByDate(_patientId!, days[selectedIndex]),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        updateTasks(tasks);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(t.myTasks),
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
    final color = task.getBaseColor(); 

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







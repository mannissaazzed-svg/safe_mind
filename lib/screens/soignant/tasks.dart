import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/soignant/check.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

class CaregiverAddTasks extends StatefulWidget {
  const CaregiverAddTasks({super.key});

  @override
  State<CaregiverAddTasks> createState() => _CaregiverAddTasksState();
}

class _CaregiverAddTasksState extends State<CaregiverAddTasks> {
  final supabase = Supabase.instance.client;
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> tasks = [];
  bool _isLoading = false;
  bool _isSending = false;

  String get dateKey => selectedDate.toIso8601String().split("T")[0];

  final Map<String, Map<String, dynamic>> taskTypes = {
    "medicine": {"color": "indigo",  "image": "assets/medicine.png"},
    "food":     {"color": "orange",  "image": "assets/food.png"},
    "sport":    {"color": "green",   "image": "assets/sport.png"},
    "brain":    {"color": "lime",    "image": "assets/brain.png"},
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  
  Future<String?> _getPatientId() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await supabase
        .from('users')
        .select('linked_to')
        .eq('id', userId)
        .maybeSingle();
    return data?['linked_to'] as String?;
  }

  
  Future<void> _loadTasks() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final patientId = await _getPatientId();
      if (patientId == null) return;

      final data = await supabase
          .from('tasks')
          .select()
          .eq('patient_id', patientId)
          .eq('task_date', dateKey)
          .order('created_at');

      setState(() {
        tasks = [];
        for (final row in data) {
          final subTasks = (row['sub_tasks'] as List?) ?? [];
          for (final sub in subTasks) {
            tasks.add({
              'id':     row['id'],
              'title':  sub['title']?.split(' ').skip(1).join(' ') ?? '',
              'detail': sub['title'] ?? '',
              'time':   sub['title']?.split(' ').first ?? '',
              'type':   row['title'],
            });
          }
        }
      });
    } catch (e) {
      _showSnack('${t.errorLoading}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _loadTasks();
    }
  }

  void addOrEditTask({Map<String, dynamic>? task, int? index}) {
    final t = AppLocalizations.of(context)!;
    final titleCtrl  = TextEditingController(text: task?['title']  ?? '');
    final detailCtrl = TextEditingController(text: task?['detail'] ?? '');
    TimeOfDay selectedTime = task != null
        ? TimeOfDay(
            hour:   int.parse(task['time'].split(':')[0]),
            minute: int.parse(task['time'].split(':')[1]),
          )
        : TimeOfDay.now();
    String selectedType = task?['type'] ?? 'medicine';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task == null ? "Nouvelle tâche" : t.editTask,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: t.title, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detailCtrl,
                  decoration: InputDecoration(
                    hintText: t.details, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.access_time),
                  TextButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: selectedTime);
                      if (t != null) setStateDialog(() => selectedTime = t);
                    },
                    child: Text(selectedTime.format(context)),
                  ),
                ]),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: taskTypes.keys.map((e) =>
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateDialog(() => selectedType = v!),
                ),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newTask = {
                          'title':  titleCtrl.text,
                          'detail': detailCtrl.text,
                          'time':   '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          'type':   selectedType,
                        };
                        setState(() {
                          if (index == null) {
                            tasks.add(newTask);
                          } else {
                            tasks[index] = newTask;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(task == null ? t.add : t.edit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.cancel),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void deleteTask(int index) {
    setState(() => tasks.removeAt(index));
  }

  
  Future<bool> sendTasks() async {
    final t = AppLocalizations.of(context)!;
  if (tasks.isEmpty) return true;
  setState(() => _isSending = true);

  try {
    final patientId = await _getPatientId();
    if (patientId == null) {
      _showSnack(t.noLinkedPatient);
      return false;
    }

    await supabase
        .from('tasks')
        .delete()
        .eq('patient_id', patientId)
        .eq('task_date', dateKey);

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var t in tasks) {
      grouped.putIfAbsent(t['type'], () => []);
      grouped[t['type']]!.add(t);
    }

    for (var type in grouped.keys) {
      final info = taskTypes[type]!;
      await supabase.from('tasks').insert({
        'patient_id': patientId,
        'task_date':  dateKey,
        'title':      type,
        'color':      info['color'],
        'image':      info['image'],
        'sub_tasks':  grouped[type]!.map((t) => {
          'title': '${t['time']} ${t['detail']}',
        }).toList(),
        'status': {},
      });
    }

    _showSnack(t.addSuccess, isError: false);
    return true; 
  } catch (e) {
    _showSnack('${t.error}:$e');
    return false; 
  } finally {
    if (mounted) setState(() => _isSending = false);
  }
}

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.planTasks),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            Row(children: [
              Text(
                dateKey,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_month),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => addOrEditTask(),
                icon: const Icon(Icons.add),
                label: Text(t.add),
              ),
            ]),

            const SizedBox(height: 20),

           
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? Center(child: Text(t.noTasks))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final t = tasks[index];
                            final color = _getColor(t['type']);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Image.asset(
                                    taskTypes[t['type']]!['image']!,
                                    width: 25,
                                    errorBuilder: (c, e, s) =>
                                        Icon(Icons.task_alt, color: color),
                                  ),
                                ),
                                title: Text(t['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${t['time']} - ${t['detail']}',
                                    style:
                                        const TextStyle(color: Colors.grey)),
                                onTap: () =>
                                    addOrEditTask(task: t, index: index),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => deleteTask(index),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            
            if (tasks.isNotEmpty)
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : sendTasks,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(t.sendToPatient),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
               
Expanded(
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Tasks()),
      );
    },
    icon: const Icon(Icons.track_changes),
    label: Text(t.followUp),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
  ),
),
           ]),
          ],
        ),
      ),
    );
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'orange': return Colors.orange;
      case 'green':  return Colors.green;
      case 'lime':   return Colors.lime;
      default:       return Colors.indigo;
    }
  }
}



import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/task_model.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static String get patientId => client.auth.currentUser!.id;

  

  static Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    await client.from('patient_locations').upsert({
      'user_id': userId,
      'latitude': lat,
      'longitude': lng,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getPatientStream(String userId) {
    return client
        .from('patient_locations')
        .stream(primaryKey: ['id'])
        .map((data) =>
            data.where((e) => e['user_id'] == userId).toList());
  }

 
  static Stream<List<TaskModel>> streamTasksByDate(
    String patientId,
    DateTime date,
  ) {
    final day = date.toIso8601String().split("T")[0];

    return client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .map((data) {
      final filtered = data.where((e) {
        final taskDate = (e['task_date'] ?? '').toString();
        return e['patient_id'] == patientId &&
            taskDate.startsWith(day);
      }).toList();

      return filtered.map((e) => TaskModel.fromMap(e)).toList();
    });
  }

  
  static Future<void> sendTasks(
    String patientId,
    DateTime date,
    List<Map<String, dynamic>> tasks,
  ) async {
    for (var t in tasks) {
      final style = getTaskStyle(t["type"]);

      await client.from('tasks').insert({
        "patient_id": patientId,
        "task_date": date.toIso8601String(),

        "title": t["title"],
        "type": t["type"],

        
        "color": style["color"],
        "image": style["image"],

        
        "sub_tasks": [
          {
            "title": "${t["time"]} ${t["detail"]}"
          }
        ],

        "status": {}
      });
    }
  }

 
  static Future<void> updateTask({
    required String taskId,
    required String title,
    required String detail,
    required String time,
    required String type,
  }) async {
    final style = getTaskStyle(type);

    await client.from('tasks').update({
      "title": title,
      "type": type,
      "color": style["color"],
      "image": style["image"],
      "sub_tasks": [
        {"title": "$time $detail"}
      ],
    }).eq('id', taskId);
  }

  
  static Future<void> deleteTask(String taskId) async {
    await client.from('tasks').delete().eq('id', taskId);
  }

  
  static Map<String, String> getTaskStyle(String type) {
    switch (type) {
      case "food":
        return {
          "color": "orange",
          "image": "assets/food.png"
        };

      case "sport":
        return {
          "color": "green",
          "image": "assets/sport.png"
        };

      case "brain":
        return {
          "color": "lime",
          "image": "assets/brain.png"
        };

      case "doctor":
        return {
          "color": "red",
          "image": "assets/doctor.png"
        };

      default:
        return {
          "color": "indigo",
          "image": "assets/medicine.png"
        };
    }
  }
}

import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final String color;
  final String image;
  final List<dynamic> subTasks;
  final Map<String, dynamic> status;

  TaskModel({
    required this.id,
    required this.title,
    required this.color,
    required this.image,
    required this.subTasks,
    required this.status,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      color: map['color'] ?? 'indigo',
      image: map['image'] ?? 'assets/medicine.png',
      subTasks: (map['sub_tasks'] ?? []) as List,
      status: Map<String, dynamic>.from(map['status'] ?? {}),
    );
  }

  // ================= BASE COLOR =================
  Color getBaseColor() {
    switch (color) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'lime':
        return Colors.lime;
      default:
        return Colors.indigo;
    }
  }

  // ================= STATUS COLOR (IMPORTANT) =================
  Color getStatusColor(String key) {
    final s = status[key];

    if (s == "green") return Colors.green;
    if (s == "orange") return Colors.orange;
    if (s == "red") return Colors.red;

    return getBaseColor();
  }
}
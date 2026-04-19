import 'package:flutter/material.dart';

enum TaskStatus { pending, green, orange, red }

class TaskModel {
  String title;
  List<String> subTasks;
  String image;
  TaskStatus status;
  int attempt;

  TaskModel({
    required this.title,
    required this.subTasks,
    required this.image,
    this.status = TaskStatus.pending,
    this.attempt = 0,
  });
}
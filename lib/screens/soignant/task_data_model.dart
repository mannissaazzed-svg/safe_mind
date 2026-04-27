import 'package:flutter/material.dart';

class TaskData {
  String title;
  String description;
  Color color;
  String image;

  TaskData({
    required this.title,
    required this.description,
    required this.color,
    required this.image,
  });

  factory TaskData.fromJson(Map<String, dynamic> json) {
    return TaskData(
      title: json['title'],
      description: json['description'],
      color: Colors.indigo,
      image: json['image'],
    );
  }
}
import 'package:flutter/material.dart';

class TaskStatus {
  static final Map<String, Color> statusMap = {};

  static final ValueNotifier<int> notifier = ValueNotifier(0);

  static void setStatus(String key, Color color) {
    statusMap[key] = color;
    notifier.value++; 
  }

  static Color getStatus(String key) {
    return statusMap[key] ?? Colors.grey;
  }
}










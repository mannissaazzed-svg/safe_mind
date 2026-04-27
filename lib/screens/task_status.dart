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












/*import 'package:flutter/material.dart';

class TaskStatus {
  static Map<String, Color> status = {};
  static final ValueNotifier<int> notifier = ValueNotifier(0);

  static void setStatus(String key, Color color) {
    status[key] = color;
    notifier.value++;
  }

  static Color getStatus(String key) {
    return status[key] ?? Colors.grey.shade300;
  }
}

class TaskData {
  final String title;
  final Color color;
  final List<String> list;
  final String image;
  TaskData(this.title, this.color, this.list, this.image);
}
*/



import 'package:flutter/material.dart';

class TaskStyle {
  static Color color(String c) {
    switch (c) {
      case "medicine":
        return Colors.indigo;
      case "food":
        return Colors.orange;
      case "sport":
        return Colors.green;
      case "brain":
        return Colors.lime;
      case "doctor":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String image(String c) {
    switch (c) {
      case "medicine":
        return "assets/medicine.png";
      case "food":
        return "assets/food.png";
      case "sport":
        return "assets/sport.png";
      case "brain":
        return "assets/brain.png";
      case "doctor":
        return "assets/doctor.png";
      default:
        return "assets/default.png";
    }
  }
}
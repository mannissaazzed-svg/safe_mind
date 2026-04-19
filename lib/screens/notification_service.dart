import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await plugin.initialize(settings);
  }

  Future show(String title, String body) async {
    const android = AndroidNotificationDetails(
      "tasks",
      "tasks",
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await plugin.show(0, title, body, details);
  }
}
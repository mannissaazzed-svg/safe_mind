import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await plugin.initialize(settings);
  }

  // 🔔 إشعار عام (Tasks + Safe Zone)
  Future show({
    required String title,
    required String body,
    String channelId = "tasks",
    String channelName = "tasks",
  }) async {

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await plugin.show(0, title, body, details);
  }
}












/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
*/
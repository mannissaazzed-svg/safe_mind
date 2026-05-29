import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await plugin.initialize(settings);
  }

  // 🔔 إشعار عادي
  Future show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "tasks",
      "tasks",
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await plugin.show(0, title, body, details);
  }

  // 📞 إشعار مكالمة (مهم)
  Future showIncomingCall({
    required String callerName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      "calls",
      "incoming calls",
      importance: Importance.max,
      priority: Priority.high,

      playSound: true,
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await plugin.show(
      1,
      "Appel entrant",
      "$callerName vous appelle...",
      details,
    );
  }
}
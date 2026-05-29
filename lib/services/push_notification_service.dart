import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  static Future<void> init() async {
    // طلب صلاحيات
    await _messaging.requestPermission();

    // تهيئة Local Notification
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _local.initialize(settings);

    // استقبال الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // استقبال الإشعارات في foreground
    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(message);
    });

    // طباعة التوكن
    String? token = await _messaging.getToken();
    print("🔥 FCM TOKEN: $token");
  }

  // ================= BACKGROUND =================
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
  }

  // ================= SHOW NOTIFICATION =================
  static void _showNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
      "calls",
      "Calls",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    _local.show(
      0,
      message.notification?.title ?? "Call",
      message.notification?.body ?? "",
      details,
    );
  }
}
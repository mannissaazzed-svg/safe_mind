import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  static final _supabase = Supabase.instance.client;

  static Future<void> initFCM() async {
    final fcm = FirebaseMessaging.instance;

    await fcm.requestPermission();

    final token = await fcm.getToken();

    if (token != null) {
      await _supabase.from('users').update({
        'fcm_token': token,
      }).eq('id', _supabase.auth.currentUser!.id);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _supabase.from('users').update({
        'fcm_token': newToken,
      }).eq('id', _supabase.auth.currentUser!.id);
    });
  }
}
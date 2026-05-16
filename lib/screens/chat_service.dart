import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', chatId)
        .order('created_at')
        .map((data) => data);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    String? text,
    String? mediaUrl,
    required String type,
  }) async {
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': text,
      'media_url': mediaUrl,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
      'is_seen': false,
    });
  }

  Future<void> setOnline(String userId, bool status) async {
    await supabase.from('users').update({
      'is_online': status,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
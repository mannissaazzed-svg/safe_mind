// call_service.dart
// ✅ يقرأ من جدول users (لا profiles)
// ✅ بدون Token
// ✅ short_code بدل connection_code

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'call_record.dart';
import 'package:safemind/screens/notification_service.dart';
import 'package:safemind/services/sound_service.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  String get _myId => _supabase.auth.currentUser!.id;

 final NotificationService _notif = NotificationService();
  bool _isPlayingRing = false;
  // ══════════════════════════════════════════════════
  // بدء مكالمة
  // ══════════════════════════════════════════════════
  Future<CallStartResult> startCall({
    String? callerId,
    required String receiverId,
    required String channelId,
    required String type,
  }) async {
    try {
      await _cancelStaleCalls();
      final activeCallerId = callerId ?? _myId;

      // ✅ من جدول users لا profiles
      final me = await _supabase
          .from('users')
          .select('full_name, name, avatar_url')
          .eq('id', activeCallerId)
          .maybeSingle();

      final receiver = await _supabase
          .from('users')
          .select('full_name, name, avatar_url')
          .eq('id', receiverId)
          .maybeSingle();

      if (receiver == null) {
        return CallStartResult.error('Destinataire introuvable');
      }

      final callerName =
          (me?['full_name'] ?? me?['name'] ?? 'Utilisateur').toString();
      final receiverName =
          (receiver['full_name'] ?? receiver['name'] ?? 'Utilisateur')
              .toString();

      final insert = await _supabase.from('calls').insert({
        'caller_id':     activeCallerId,
        'receiver_id':   receiverId,
        'channel_id':    channelId,
        'type':          type,
        'status':        'ringing',
        'caller_name':   callerName,
        'receiver_name': receiverName,
        'created_at':    DateTime.now().toIso8601String(),
      }).select('id').single();

      final callId = insert['id'].toString();

      return CallStartResult.success(
        callId:     callId,
        callerName: callerName,
      );
    } catch (e) {
      debugPrint('startCall error: $e');
      return CallStartResult.error(e.toString());
    }
  }

  // ══════════════════════════════════════════════════
  // Streams
  // ══════════════════════════════════════════════════
 Stream<CallRecord?> listenIncomingCalls() {
  return _supabase
      .from('calls')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', _myId)
      .map((data) {
    final ringing = data.where((e) => e['status'] == 'ringing');

    if (ringing.isEmpty) {
      _isPlayingRing = false;
      SoundService.stopRing(); // 🔥 مهم جداً إذا موجودة
      return null;
    }

    final call = CallRecord.fromMap(ringing.first);

    // 🔔 notification
    _notif.show(
      title: "Appel entrant",
      body: call.callerName ?? "Quelqu'un vous appelle",
    );

    // 🔊 sound (FIXED)
    if (!_isPlayingRing) {
      _isPlayingRing = true;
      SoundService.playRing();
    }

    return call;
  });
}

  Stream<String?> listenCallStatus(String callId) {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((data) =>
            data.isEmpty ? null : data.first['status'] as String?);
  }

  Stream<List<CallRecord>> listenCallHistory() {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => (data as List)
            .where((e) =>
                e['caller_id'] == _myId || e['receiver_id'] == _myId)
            .map((e) => CallRecord.fromMap(e))
            .toList());
  }

  // ══════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════
  Future<void> acceptCall(String callId) async {
    await _supabase.from('calls').update({
      'status':      'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', callId);
  }

  Future<void> rejectCall(String callId) async {
    await _supabase
        .from('calls')
        .update({'status': 'rejected'})
        .eq('id', callId);
  }

  Future<void> endCall(String callId, {int durationSeconds = 0}) async {
    await _supabase.from('calls').update({
      'status':           'ended',
      'ended_at':         DateTime.now().toIso8601String(),
      'duration_seconds': durationSeconds,
    }).eq('id', callId);
  }

  Future<void> cancelCall(String callId) async {
    await _supabase.from('calls').update({
      'status': 'cancelled',
    }).eq('id', callId).eq('caller_id', _myId);
  }

  Future<void> missedCall(String callId) async {
    await _supabase.from('calls').update({
      'status': 'missed',
    }).eq('id', callId);
  }

  // ✅ حفظ أثر المكالمة في المحادثة
  Future<void> saveCallRecord({
    required String conversationId,
    required String receiverId,
    required String type,
    required String status,
    required int durationSeconds,
  }) async {
    try {
      final duration = _formatDuration(durationSeconds);
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id':       _myId,
        'receiver_id':     receiverId,
        'type':            'call',
        'call_status':     status,
        'call_duration':   duration,
        'content': status == 'ended'
            ? '${type == 'video' ? '📹' : '📞'} Appel $duration'
            : type == 'video'
                ? '📹 Appel vidéo manqué'
                : '📞 Appel manqué',
        'is_seen':    false,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('saveCallRecord error: $e');
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _cancelStaleCalls() async {
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: 2))
        .toIso8601String();
    await _supabase
        .from('calls')
        .update({'status': 'cancelled'})
        .eq('caller_id', _myId)
        .eq('status', 'ringing')
        .lt('created_at', cutoff);
  }

  // ✅ جلب المحادثات التلقائية (linked_to)
  Future<List<Map<String, dynamic>>> getAutoContacts() async {
    try {
      final me = await _supabase
          .from('users')
          .select('role, linked_to')
          .eq('id', _myId)
          .maybeSingle();

      if (me == null) return [];

      final role     = me['role'] as String? ?? '';
      final linkedTo = me['linked_to'] as String?;
      final contacts = <Map<String, dynamic>>[];

      // مريض/مرافق → يرى الشخص المرتبط به تلقائياً
      if (linkedTo != null) {
        final linked = await _supabase
            .from('users')
            .select('id, full_name, name, avatar_url, role, is_online')
            .eq('id', linkedTo)
            .maybeSingle();
        if (linked != null) contacts.add(linked);
      }

      // طبيب → يرى مرضاه
      if (role == 'medecin' || role == 'doctor') {
        final patients = await _supabase
            .from('patients')
            .select('patient_user_id, caregiver_id, name')
            .eq('medecin_id', _myId);

        for (final p in patients) {
          if (p['patient_user_id'] != null) {
            final user = await _supabase
                .from('users')
                .select('id, full_name, name, avatar_url, role, is_online')
                .eq('id', p['patient_user_id'])
                .maybeSingle();
            if (user != null) contacts.add(user);
          }
          if (p['caregiver_id'] != null) {
            final caregiver = await _supabase
                .from('users')
                .select('id, full_name, name, avatar_url, role, is_online')
                .eq('id', p['caregiver_id'])
                .maybeSingle();
            if (caregiver != null) contacts.add(caregiver);
          }
        }
      }

      // إزالة المكررات
      final seen  = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final c in contacts) {
        final id = c['id'].toString();
        if (!seen.contains(id) && id != _myId) {
          seen.add(id);
          unique.add(c);
        }
      }
      return unique;
    } catch (e) {
      debugPrint('getAutoContacts error: $e');
      return [];
    }
  }
}

// ══════════════════════════════════════════════════
class CallStartResult {
  final bool    success;
  final String? callId;
  final String? callerName;
  final String? error;

  String? get errorMessage => error;

  CallStartResult._(
      this.success, this.callId, this.callerName, this.error);

  factory CallStartResult.success({
    required String callId,
    required String callerName,
  }) => CallStartResult._(true, callId, callerName, null);

  factory CallStartResult.error(String msg) =>
      CallStartResult._(false, null, null, msg);
}
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════
// Service d'appels — SafeMind
// Gestion complète : démarrage, écoute, accepter,
//                    rejeter, terminer, nettoyage
// ═══════════════════════════════════════════════════════

class CallService {
  final _supabase = Supabase.instance.client;

  String get _myId => _supabase.auth.currentUser!.id;

  // ══════════════════════════════════════════════════════
  // DÉMARRER UN APPEL
  // ══════════════════════════════════════════════════════

  Future<String?> startCall({
    required String callerId,
    required String receiverId,
    required String channelId,
    required String type, // 'audio' ou 'video'
  }) async {
    try {
      // ✅ Annuler tout appel précédent en cours
      await _cancelPreviousCalls(callerId);

      final result = await _supabase.from('calls').insert({
        'caller_id': callerId,
        'receiver_id': receiverId,
        'channel_id': channelId,
        'type': type,
        'status': 'ringing',
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return result['id'].toString();
    } catch (e) {
      print('Erreur startCall: $e');
      return null;
    }
  }

  // ── Annuler les anciens appels en attente ──────────
  Future<void> _cancelPreviousCalls(String callerId) async {
    try {
      await _supabase
          .from('calls')
          .update({'status': 'cancelled'})
          .eq('caller_id', callerId)
          .eq('status', 'ringing');
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════
  // ÉCOUTER LES APPELS ENTRANTS
  // ══════════════════════════════════════════════════════

  Stream<Map<String, dynamic>?> listenIncoming(String userId) {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          // ✅ Uniquement les appels "ringing" des 30 dernières secondes
          final recent = data.where((c) {
            if (c['status'] != 'ringing') return false;
            final created = DateTime.tryParse(c['created_at'] ?? '');
            if (created == null) return false;
            return DateTime.now().difference(created).inSeconds < 30;
          });
          return recent.isEmpty ? null : recent.first;
        });
  }

  // ══════════════════════════════════════════════════════
  // ÉCOUTER LE STATUT D'UN APPEL (côté appelant)
  // Pour savoir si l'autre a accepté/rejeté
  // ══════════════════════════════════════════════════════

  Stream<String?> listenCallStatus(String callId) {
    return _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .map((data) {
          if (data.isEmpty) return null;
          return data.first['status'] as String?;
        });
  }

  // ══════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════

  // ✅ Accepter
  Future<void> acceptCall(String id) async {
    try {
      await _supabase
          .from('calls')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      print('Erreur acceptCall: $e');
    }
  }

  // ❌ Rejeter
  Future<void> rejectCall(String id) async {
    try {
      await _supabase
          .from('calls')
          .update({'status': 'rejected'})
          .eq('id', id);
    } catch (e) {
      print('Erreur rejectCall: $e');
    }
  }

  // 🔚 Terminer
  Future<void> endCall(String id) async {
    try {
      await _supabase
          .from('calls')
          .update({
            'status': 'ended',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      print('Erreur endCall: $e');
    }
  }

  // ⏱️ Appel sans réponse (timeout)
  Future<void> missedCall(String id) async {
    try {
      await _supabase
          .from('calls')
          .update({'status': 'missed'})
          .eq('id', id);
    } catch (e) {
      print('Erreur missedCall: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // HISTORIQUE DES APPELS
  // ══════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getCallHistory() async {
    try {
      final data = await _supabase
          .from('calls')
          .select()
          .or('caller_id.eq.$_myId,receiver_id.eq.$_myId')
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erreur getCallHistory: $e');
      return [];
    }
  }
}
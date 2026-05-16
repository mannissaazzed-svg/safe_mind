import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════
// Enregistreur vocal — SafeMind
// Compatible : record ^5.0.0
// ═══════════════════════════════════════════════════════

class VoiceRecorder {
  // ✅ record v5 utilise AudioRecorder() et non Record()
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  // ── Vérifier la permission ─────────────────────────
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // ── Démarrer l'enregistrement ──────────────────────
  Future<String?> start() async {
    try {
      // Vérifier la permission avant de commencer
      final permitted = await _recorder.hasPermission();
      if (!permitted) {
        print('Microphone permission denied');
        return null;
      }

      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // ✅ API correcte pour record v5
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // ✅ aacLc — plus compatible que aacHe
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,             // mono — suffisant pour la voix
        ),
        path: _path!,
      );

      return _path;
    } catch (e) {
      print('Erreur démarrage enregistrement: $e');
      return null;
    }
  }

  // ── Arrêter l'enregistrement ───────────────────────
  Future<String?> stop() async {
    try {
      // ✅ stop() retourne le path dans record v5
      final path = await _recorder.stop();
      _path = path;
      return path;
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
      return null;
    }
  }

  // ── Annuler sans sauvegarder ───────────────────────
  Future<void> cancel() async {
    try {
      await _recorder.stop();
      _path = null;
    } catch (e) {
      print('Erreur annulation: $e');
    }
  }

  // ── Vérifier si en cours ───────────────────────────
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // ── Libérer les ressources ─────────────────────────
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

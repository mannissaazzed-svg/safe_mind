import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playRing() async {
    if (_isPlaying) return;

    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/ring.mp3'));
  }

  static Future<void> stopRing() async {
    _isPlaying = false;
    await _player.stop();
  }
}
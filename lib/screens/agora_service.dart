import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  late RtcEngine engine;

  Future<void> init(String appId) async {
    engine = createAgoraRtcEngine();

    await engine.initialize(
      RtcEngineContext(appId: appId),
    );

    await engine.enableVideo();
    await engine.enableAudio();
  }

  Future<void> joinChannel({
    required String token,
    required String channelName,
    required int uid,
  }) async {
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
  }

  Future<void> toggleMute(bool mute) async {
    await engine.muteLocalAudioStream(mute);
  }

  Future<void> toggleCamera() async {
    await engine.switchCamera();
  }
}
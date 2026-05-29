// video_call_page.dart
// ✅ بدون Token
// ✅ أزرار تحكم تحت مثل Messenger
// ✅ رنين عند الاتصال
// ✅ App ID: feaef859a6c740ee9880322144128c96

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'call_service.dart';
import 'package:safemind/services/sound_service.dart';

class VideoCallPage extends StatefulWidget {
  final String  channelId;
  final String  appId;
  final String  callId;
  final bool    isVoiceOnly;
  final String? remoteUserName;
  final String? remoteUserAvatar;
  final String? conversationId;
  final String? receiverId;

  const VideoCallPage({
    super.key,
    required this.channelId,
    required this.appId,
    required this.callId,
    this.isVoiceOnly       = false,
    this.remoteUserName,
    this.remoteUserAvatar,
    this.conversationId,
    this.receiverId,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {

  static const String _appId = 'feaef859a6c740ee9880322144128c96';

  RtcEngine? _engine;
  int?  _remoteUid;
  bool  _localJoined   = false;
  bool  _remoteJoined  = false;

  // Controls
  bool  _micMuted      = false;
  bool  _cameraOff     = false;
  bool  _speakerOn     = true;
  bool  _frontCamera   = true;
  bool  _localSwapped  = false;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer?  _durationTimer;
  String  _durationText = '00:00';
  int     _durationSeconds = 0;

  // Ringing
  final AudioPlayer _ringPlayer = AudioPlayer();
  bool  _isRinging = true;

  // Status stream
  StreamSubscription<String?>? _statusSub;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  static const Color _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _startRinging();
    _initAgora();
    _listenStatus();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusSub?.cancel();
    _pulseCtrl.dispose();
    _ringPlayer.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ══════════════════════════════════════════════════
  // RINGING
  // ══════════════════════════════════════════════════
  Future<void> _startRinging() async {
    try {
      await _ringPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringPlayer.play(AssetSource('sounds/ring.mp3'));
    } catch (_) {}
  }

  Future<void> _stopRinging() async {
    if (_isRinging) {
      _isRinging = false;
      await _ringPlayer.stop();
    }
  }

  // ══════════════════════════════════════════════════
  // AGORA — بدون Token
  // ══════════════════════════════════════════════════
  Future<void> _initAgora() async {
    final perms = widget.isVoiceOnly
        ? [Permission.microphone]
        : [Permission.camera, Permission.microphone];
    await perms.request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: _appId));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (_, __) {
        if (mounted) setState(() => _localJoined = true);
      },
      onUserJoined: (_, uid, __) {
        if (mounted) {
          _stopRinging();
          setState(() {
            _remoteUid    = uid;
            _remoteJoined = true;
          });
          _startTimer();
        }
      },
      onUserOffline: (_, uid, __) {
        if (mounted) {
          setState(() {
            _remoteUid    = null;
            _remoteJoined = false;
          });
          _onRemoteLeft();
        }
      },
      onError: (err, msg) => debugPrint('Agora: $err — $msg'),
    ));

    await _engine!.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster);

    if (!widget.isVoiceOnly) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
    }

    await _engine!.setEnableSpeakerphone(true);

    // ✅ بدون Token — نمرر null أو string فارغ
    await _engine!.joinChannel(
      token: '',
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        publishCameraTrack:     !widget.isVoiceOnly,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile:
            ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // STATUS LISTENER
  // ══════════════════════════════════════════════════
  void _listenStatus() {
    _statusSub =
        CallService().listenCallStatus(widget.callId).listen((status) {
      if (status == 'ended' ||
          status == 'rejected' ||
          status == 'cancelled') {
        if (mounted) _hangUp(updateDb: false);
      }
    });
  }

  // ══════════════════════════════════════════════════
  // TIMER
  // ══════════════════════════════════════════════════
  void _startTimer() {
    _stopwatch.start();
    _durationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _durationSeconds = _stopwatch.elapsed.inSeconds;
      final m = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_durationSeconds % 60).toString().padLeft(2, '0');
      setState(() => _durationText = '$m:$s');
    });
  }

  // ══════════════════════════════════════════════════
  // CONTROLS
  // ══════════════════════════════════════════════════
  Future<void> _toggleMic() async {
    _micMuted = !_micMuted;
    await _engine?.muteLocalAudioStream(_micMuted);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOff = !_cameraOff;
    await _engine?.muteLocalVideoStream(_cameraOff);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _flipCamera() async {
    _frontCamera = !_frontCamera;
    await _engine?.switchCamera();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.setEnableSpeakerphone(_speakerOn);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Future<void> _hangUp({bool updateDb = true}) async {
    _stopRinging();
    _durationTimer?.cancel();
    _stopwatch.stop();

    if (updateDb) {
      await CallService().endCall(
        widget.callId,
        durationSeconds: _durationSeconds,
      );

      // ✅ حفظ أثر المكالمة في المحادثة
      if (widget.conversationId != null && widget.receiverId != null) {
        await CallService().saveCallRecord(
          conversationId:  widget.conversationId!,
          receiverId:      widget.receiverId!,
          type:            widget.isVoiceOnly ? 'audio' : 'video',
          status:          _remoteJoined ? 'ended' : 'missed',
          durationSeconds: _durationSeconds,
        );
      }
    }

    await _engine?.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  void _onRemoteLeft() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("L'autre personne a raccroché"),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
      ));
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _hangUp(updateDb: true);
    });
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Vidéo principale ───────────────────────
        _buildMainView(),

        // ── Miniature locale (coin haut droit) ─────
        if (!widget.isVoiceOnly && _localJoined)
          _buildLocalThumbnail(),

        // ── Overlay audio ───────────────────────────
        if (widget.isVoiceOnly || !_remoteJoined)
          _buildAudioOverlay(),

        // ── Bandeau haut (nom + durée) ──────────────
        _buildTopBar(),

        // ── CONTRÔLES EN BAS (style Messenger) ──────
        _buildBottomControls(),
      ]),
    );
  }

  // ── Vidéo principale ────────────────────────────
  Widget _buildMainView() {
    if (widget.isVoiceOnly || _engine == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
      );
    }

    if (_remoteJoined && _remoteUid != null && !_localSwapped) {
      return SizedBox.expand(
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelId),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      ),
    );
  }

  // ── Miniature locale ────────────────────────────
  Widget _buildLocalThumbnail() {
    if (_engine == null) return const SizedBox();
    return Positioned(
      top: 100, right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _localSwapped = !_localSwapped),
        child: Container(
          width: 100, height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white30, width: 1.5),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10)],
          ),
          clipBehavior: Clip.hardEdge,
          child: _cameraOff
              ? Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.videocam_off,
                        color: Colors.white54, size: 28),
                  ),
                )
              : AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Overlay audio / en attente ──────────────────
  Widget _buildAudioOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Avatar animé
            ScaleTransition(
              scale: _pulseAnim,
              child: _buildAvatar(size: 100),
            ),
            const SizedBox(height: 24),
            Text(
              widget.remoteUserName ?? 'Correspondant',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _remoteJoined
                  ? _durationText
                  : _isRinging
                      ? 'Appel en cours...'
                      : 'Connexion...',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 16),
            ),
            if (_isRinging && !_remoteJoined) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) =>
                  _DotAnimation(delay: Duration(milliseconds: i * 300))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({double size = 80}) {
    if (widget.remoteUserAvatar != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(widget.remoteUserAvatar!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _primary.withOpacity(0.3),
      child: Text(
        (widget.remoteUserName ?? '?')[0].toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Bandeau supérieur ───────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16, right: 16, bottom: 20,
        ),
        child: Row(children: [
          // Bouton retour
          GestureDetector(
            onTap: () => _hangUp(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.remoteUserName ?? 'Appel',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _remoteJoined ? _durationText : 'En attente...',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ✅ CONTRÔLES EN BAS — Style Messenger
  // ══════════════════════════════════════════════════
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 30,
          top: 30,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Rangée 1: Micro + Caméra + Haut-parleur ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Micro
                _CallButton(
                  icon:    _micMuted ? Icons.mic_off : Icons.mic,
                  label:   _micMuted ? 'Muet' : 'Micro',
                  active:  !_micMuted,
                  onTap:   _toggleMic,
                  size:    56,
                ),

                // Caméra
                if (!widget.isVoiceOnly)
                  _CallButton(
                    icon:   _cameraOff
                        ? Icons.videocam_off
                        : Icons.videocam,
                    label:  _cameraOff ? 'Caméra off' : 'Caméra',
                    active: !_cameraOff,
                    onTap:  _toggleCamera,
                    size:   56,
                  ),

                // Haut-parleur
                _CallButton(
                  icon:   _speakerOn
                      ? Icons.volume_up
                      : Icons.volume_off,
                  label:  _speakerOn ? 'HP activé' : 'HP désactivé',
                  active: _speakerOn,
                  onTap:  _toggleSpeaker,
                  size:   56,
                ),

                // Retourner caméra
                if (!widget.isVoiceOnly)
                  _CallButton(
                    icon:   Icons.flip_camera_ios,
                    label:  'Retourner',
                    active: true,
                    onTap:  _flipCamera,
                    size:   56,
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Bouton Raccrocher (centré, grand) ────────
            GestureDetector(
              onTap: () => _hangUp(),
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                    Icons.call_end, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Raccrocher',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════

class _CallButton extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      active;
  final VoidCallback onTap;
  final double    size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size, height: size,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Icon(icon,
                color: active ? Colors.white : Colors.white38,
                size: size * 0.42),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white70 : Colors.white38,
                  fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Points animés (en attente) ───────────────────
class _DotAnimation extends StatefulWidget {
  final Duration delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
            color: Colors.white60, shape: BoxShape.circle),
      ),
    );
  }
}
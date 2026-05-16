import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safemind/screens/call_service.dart'; // تأكد من المسار الصحيح

// ═══════════════════════════════════════════════════════
// Page d'appel vidéo professionnelle — SafeMind
// Fonctionnalités : vidéo locale/distante, micro, caméra,
//                   haut-parleur, retournement caméra, chrono
// ═══════════════════════════════════════════════════════

class VideoCallPage extends StatefulWidget {
  final String channelId;
  final String appId;
  final String callId;
// 
  final bool isVoiceOnly; // t
  

  const VideoCallPage({
    super.key,
    required this.channelId,
    required this.appId,
    this.callId = '', // أضف هذه القيمة الافتراضية
    this.isVoiceOnly = false,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {
  // ── Agora ──────────────────────────────────────────
  late RtcEngine _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _engineReady = false;

  // ── Contrôles ──────────────────────────────────────
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _speakerOn = true;
  bool _frontCamera = true;
  bool _showControls = true;

  // ── Chronomètre ────────────────────────────────────
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _duration = '00:00';

  // ── Animation ──────────────────────────────────────
  late AnimationController _controlsController;
  late Animation<double> _controlsAnimation;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();

    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning && mounted) {
        setState(() => _duration = _formatDuration(_stopwatch.elapsed));
      }
    });

    void _endCall() {
    // إرسال طلب إنهاء لـ Supabase قبل الخروج
    CallService().endCall(widget.callId); 
    Navigator.pop(context);
  }
  
   
    _initAgora();
  }

  @override
  void dispose() {
    _timer.cancel();
    _hideControlsTimer?.cancel();
    _controlsController.dispose();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // INITIALISATION AGORA
  // ══════════════════════════════════════════════════════

  Future<void> _initAgora() async {
    // Demande de permissions
    await [Permission.camera, Permission.microphone].request();

    // Création du moteur
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: widget.appId));

    // Événements
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() => _joined = true);
            _stopwatch.start();
          }
        },
        onUserJoined: (connection, uid, elapsed) {
          if (mounted) setState(() => _remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          if (mounted) {
            setState(() => _remoteUid = null);
            // Fin d'appel si l'autre raccroche
            _showCallEndedDialog();
          }
        },
        onError: (err, msg) {
          debugPrint('Agora error: $err — $msg');
        },
      ),
    );

    // Configuration vidéo
    if (!widget.isVoiceOnly) {
      await _engine.enableVideo();
      await _engine.startPreview();
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 0,
        ),
      );
    } else {
      await _engine.enableAudio();
    }

    // Haut-parleur activé par défaut
    await _engine.setEnableSpeakerphone(true);

    // Rejoindre le canal
    await _engine.joinChannel(
      token: '',             // ← Remplacer par un token en production
      channelId: widget.channelId,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: !widget.isVoiceOnly,
        publishMicrophoneTrack: true,
      ),
    );

    if (mounted) setState(() => _engineReady = true);
    _scheduleHideControls();
  }

  // ══════════════════════════════════════════════════════
  // CONTRÔLES
  // ══════════════════════════════════════════════════════

  Future<void> _toggleMic() async {
    _micMuted = !_micMuted;
    await _engine.muteLocalAudioStream(_micMuted);
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOff = !_cameraOff;
    await _engine.muteLocalVideoStream(_cameraOff);
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine.setEnableSpeakerphone(_speakerOn);
    setState(() {});
  }

  Future<void> _flipCamera() async {
    _frontCamera = !_frontCamera;
    await _engine.switchCamera();
    setState(() {});
  }

  void _endCall() {
    Navigator.pop(context);
  }

  void _onTapScreen() {
    setState(() => _showControls = true);
    _controlsController.forward();
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _remoteUid != null) {
        _controlsController.reverse();
        setState(() => _showControls = false);
      }
    });
  }

  void _showCallEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Appel terminé'),
        content: Text('Durée : $_duration'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ferme dialog
              Navigator.pop(context); // quitte la page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTapScreen,
        child: Stack(
          children: [
            // ── Vidéo distante (plein écran) ────────────
            _buildRemoteVideo(),

            // ── Vidéo locale (coin) ─────────────────────
            if (!widget.isVoiceOnly) _buildLocalVideo(),

            // ── Gradient haut ───────────────────────────
            _buildTopGradient(),

            // ── Gradient bas ────────────────────────────
            _buildBottomGradient(),

            // ── Infos en haut ───────────────────────────
            _buildTopBar(),

            // ── Contrôles en bas ────────────────────────
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // ── Vidéo distante ─────────────────────────────────
  Widget _buildRemoteVideo() {
    if (widget.isVoiceOnly) {
      return _buildVoiceOnlyBackground();
    }

    if (_remoteUid != null && _engineReady) {
      return SizedBox.expand(
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelId),
          ),
        ),
      );
    }

    return _buildWaitingScreen();
  }

  // ── Écran d'attente ────────────────────────────────
  Widget _buildWaitingScreen() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.person,
                  size: 52, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'En attente...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appel en cours de connexion',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF6C63FF).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fond appel vocal ───────────────────────────────
  Widget _buildVoiceOnlyBackground() {
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.6),
                  width: 3,
                ),
              ),
              child: const Icon(Icons.person,
                  size: 60, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Appel vocal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _joined ? _duration : 'Connexion...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vidéo locale ───────────────────────────────────
  Widget _buildLocalVideo() {
    return Positioned(
      top: 60,
      right: 16,
      child: GestureDetector(
        onTap: _flipCamera,
        child: Container(
          width: 110,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _joined && _engineReady && !_cameraOff
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: const Icon(Icons.videocam_off,
                        color: Colors.white54, size: 32),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Gradient haut ──────────────────────────────────
  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 160,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient bas ───────────────────────────────────
  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 200,
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
      ),
    );
  }

  // ── Barre supérieure ───────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _controlsAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Bouton retour
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                // Titre + chrono
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isVoiceOnly ? 'Appel vocal' : 'Appel vidéo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_joined)
                        Text(
                          _duration,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                // Indicateur connexion
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _joined
                        ? const Color(0xFF4ADE80).withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _joined
                          ? const Color(0xFF4ADE80).withOpacity(0.5)
                          : Colors.orange.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _joined
                              ? const Color(0xFF4ADE80)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _joined ? 'Connecté' : 'Connexion...',
                        style: TextStyle(
                          color: _joined
                              ? const Color(0xFF4ADE80)
                              : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Contrôles bas ──────────────────────────────────
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _controlsAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Rangée 1 : contrôles secondaires ──
                if (!widget.isVoiceOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SecondaryButton(
                          icon: _speakerOn
                              ? Icons.volume_up
                              : Icons.volume_off,
                          label: _speakerOn ? 'HP activé' : 'HP désactivé',
                          active: _speakerOn,
                          onTap: _toggleSpeaker,
                        ),
                        _SecondaryButton(
                          icon: Icons.flip_camera_ios_outlined,
                          label: 'Retourner',
                          active: true,
                          onTap: _flipCamera,
                        ),
                      ],
                    ),
                  ),

                // ── Rangée 2 : contrôles principaux ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Micro
                    _ControlButton(
                      icon: _micMuted ? Icons.mic_off : Icons.mic,
                      label: _micMuted ? 'Micro off' : 'Micro',
                      active: !_micMuted,
                      onTap: _toggleMic,
                    ),

                    // Raccrocher (bouton central rouge)
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    // Caméra (ou haut-parleur si vocal)
                    widget.isVoiceOnly
                        ? _ControlButton(
                            icon: _speakerOn
                                ? Icons.volume_up
                                : Icons.volume_off,
                            label: _speakerOn ? 'HP on' : 'HP off',
                            active: _speakerOn,
                            onTap: _toggleSpeaker,
                          )
                        : _ControlButton(
                            icon: _cameraOff
                                ? Icons.videocam_off
                                : Icons.videocam,
                            label:
                                _cameraOff ? 'Caméra off' : 'Caméra',
                            active: !_cameraOff,
                            onTap: _toggleCamera,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// WIDGETS HELPERS
// ══════════════════════════════════════════════════════

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white70 : Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white38,
                size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white70 : Colors.white30,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'call_service.dart';
import 'video_call_page.dart';
import 'agora_service.dart';
import 'package:safemind/screens/notification_service.dart';
import 'package:safemind/services/sound_service.dart'; // ✅ ADD

class IncomingCallPage extends StatefulWidget {
  final String channelId;
  final String callId;
  final String appId;
  final String type;
  final String callerName;
  final String? callerAvatar;

  const IncomingCallPage({
    super.key,
    required this.channelId,
    required this.callId,
    required this.appId,
    required this.type,
    required this.callerName,
    this.callerAvatar,
  });

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _slideCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;
  late Animation<Offset> _slideAnim;

  Timer? _timeoutTimer;
  int _secondsLeft = 45;
  bool _navigating = false;

  final _callService = CallService();
  final NotificationService _notif = NotificationService();

  bool _notified = false;

  @override
  void initState() {
    super.initState();

    HapticFeedback.heavyImpact();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initAnimations();
    _startTimeout();

    // 🔔 Notification + 🔊 Ring
    _notif.init().then((_) {
      if (!_notified) {
        _notif.show(
  title: "Appel entrant",
  body: widget.callerName,
);

SoundService.playRing(); 
        _notified = true;
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _slideCtrl.dispose();
    _timeoutTimer?.cancel();

    SoundService.stopRing(); // 🔥 STOP SOUND ON EXIT

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _ring1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.0, 0.7)),
    );

    _ring2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.2, 0.9)),
    );

    _ring3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.4, 1.0)),
    );

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _slideCtrl.forward();
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        t.cancel();
        _onMissed();
      }
    });
  }

  Future<void> _onAccept() async {
    if (_navigating) return;
    _navigating = true;

    _timeoutTimer?.cancel();
    HapticFeedback.mediumImpact();

    SoundService.stopRing(); // 🔥 STOP ON ACCEPT

    await _callService.acceptCall(widget.callId);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallPage(
          channelId: widget.channelId,
          appId: widget.appId,
          callId: widget.callId,
          isVoiceOnly: widget.type == 'audio',
          remoteUserName: widget.callerName,
          remoteUserAvatar: widget.callerAvatar,
        ),
      ),
    );
  }

  Future<void> _onReject() async {
    if (_navigating) return;
    _navigating = true;

    _timeoutTimer?.cancel();
    HapticFeedback.mediumImpact();

    SoundService.stopRing(); // 🔥 STOP ON REJECT

    await _callService.rejectCall(widget.callId);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _onMissed() async {
    if (_navigating) return;
    _navigating = true;

    SoundService.stopRing(); // 🔥 STOP ON MISS

    await _callService.missedCall(widget.callId);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF1A1A2E),
              Color(0xFF0F1B3D)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _onReject,
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: _onAccept,
                    child: const Icon(Icons.call),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
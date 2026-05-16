import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safemind/screens/call_service.dart';
import 'package:safemind/screens/video_call_page.dart';

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

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ring1Animation;
  late Animation<double> _ring2Animation;
  late Animation<double> _ring3Animation;

  late Timer _timeoutTimer;
  int _secondsLeft = 30;
  final _callService = CallService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimeout();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _timeoutTimer.cancel();
    super.dispose();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ring1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _ring2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController,
          curve: const Interval(0.2, 0.9, curve: Curves.easeOut)));
    _ring3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) { t.cancel(); _onMissed(); }
    });
  }

  Future<void> _onAccept() async {
    _timeoutTimer.cancel();
    HapticFeedback.mediumImpact();
    await _callService.acceptCall(widget.callId);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => VideoCallPage(
        channelId: widget.channelId,
        appId: widget.appId,
        isVoiceOnly: widget.type == 'audio',
      ),
    ));
  }

  Future<void> _onReject() async {
    _timeoutTimer.cancel();
    HapticFeedback.mediumImpact();
    await _callService.rejectCall(widget.callId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onMissed() async {
    await _callService.missedCall(widget.callId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(flex: 2),
              _buildCallerAvatar(),
              const SizedBox(height: 28),
              Text(widget.callerName,
                  style: const TextStyle(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.type == 'video' ? Icons.videocam : Icons.call,
                    color: Colors.white54, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.type == 'video'
                      ? 'Appel vidéo entrant...'
                      : 'Appel vocal entrant...',
                  style: const TextStyle(color: Colors.white54, fontSize: 15),
                ),
              ]),
              const SizedBox(height: 16),
              _buildTimeoutIndicator(),
              const Spacer(flex: 3),
              _buildActionButtons(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('SafeMind',
                style: TextStyle(color: Colors.white70, fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCallerAvatar() {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (_, __) => SizedBox(
        width: 220, height: 220,
        child: Stack(alignment: Alignment.center, children: [
          _buildRing(_ring3Animation, 210, 0.04),
          _buildRing(_ring2Animation, 170, 0.08),
          _buildRing(_ring1Animation, 130, 0.14),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 24, spreadRadius: 4)],
              ),
              child: ClipOval(child: widget.callerAvatar != null
                  ? Image.network(widget.callerAvatar!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultAvatar())
                  : _defaultAvatar()),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRing(Animation<double> anim, double size, double opacity) {
    return Opacity(
      opacity: (1 - anim.value) * opacity * 10,
      child: Container(
        width: size * anim.value, height: size * anim.value,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6C63FF), width: 1.5)),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF6C63FF).withOpacity(0.3),
      child: Center(child: Text(
        widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 40,
            fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _buildTimeoutIndicator() {
    return Column(children: [
      SizedBox(
        width: 140,
        child: LinearProgressIndicator(
          value: _secondsLeft / 30,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation(
              _secondsLeft > 10 ? const Color(0xFF6C63FF) : Colors.orange),
          borderRadius: BorderRadius.circular(4),
          minHeight: 3,
        ),
      ),
      const SizedBox(height: 8),
      Text('Expire dans $_secondsLeft s',
          style: TextStyle(
              color: _secondsLeft > 10
                  ? Colors.white38
                  : Colors.orange.withOpacity(0.8),
              fontSize: 12)),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _CallButton(icon: Icons.call_end, label: 'Refuser',
          color: Colors.red.shade600, onTap: _onReject),
      _CallButton(
          icon: widget.type == 'video' ? Icons.videocam : Icons.call,
          label: 'Accepter', color: const Color(0xFF4ADE80), onTap: _onAccept),
    ]);
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.45),
                  blurRadius: 20, spreadRadius: 2)]),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white60,
            fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
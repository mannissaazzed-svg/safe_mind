import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'call_service.dart';
import 'video_call_page.dart';
import 'package:safemind/services/sound_service.dart';

// ═══════════════════════════════════════════════════════════════
//  OutgoingCallPage  —  SafeMind
//  Affichée côté appelant pendant la sonnerie.
//  ✦ Animation de sonnerie (cercles pulsants)
//  ✦ Écoute automatique du statut (accepté / rejeté / timeout)
//  ✦ Annuler l'appel
//  ✦ Transition fluide vers VideoCallPage si accepté
// ═══════════════════════════════════════════════════════════════

class OutgoingCallPage extends StatefulWidget {
  final String callId;
  final String channelId;
  final String appId;
  final String type; // 'audio' | 'video'
  final String receiverName;
  final String? receiverAvatar;

  const OutgoingCallPage({
    super.key,
    required this.callId,
    required this.channelId,
    required this.appId,
    required this.type,
    required this.receiverName,
    this.receiverAvatar,
  });

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage>
    with TickerProviderStateMixin {
  // ── Service Instance ──────────────────────────────────────────
  final _callService = CallService(); // 💡 إنشاء نسخة موحدة لاستخدامها في الصفحة كاملة

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _ring3;

  // ── État ──────────────────────────────────────────────────────
  StreamSubscription<String?>? _statusSub;
  Timer? _timeoutTimer;
  int _secondsElapsed = 0;
  bool _navigating = false;

  static const int _timeoutSeconds = 45;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _initAnimations();
    _listenStatus();
    _startTimeout();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _statusSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  void _initAnimations() {
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _ring1 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _ringCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _ringCtrl,
            curve: const Interval(0.2, 0.85, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _ringCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  void _listenStatus() {
    _statusSub =
        _callService.listenCallStatus(widget.callId).listen((status) async {
      if (_navigating) return;

      switch (status) {
        case 'accepted':
          _navigating = true;
          _timeoutTimer?.cancel();
          HapticFeedback.mediumImpact();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => VideoCallPage(
                  channelId: widget.channelId,
                  appId: widget.appId,
                  callId: widget.callId,
                  isVoiceOnly: widget.type == 'audio',
                  remoteUserName: widget.receiverName,
                  remoteUserAvatar: widget.receiverAvatar,
                ),
                transitionDuration: const Duration(milliseconds: 400),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          }
          break;
        case 'rejected':
          _navigating = true;
          _timeoutTimer?.cancel();
          if (mounted) {
            _showResult('Appel refusé', Icons.call_end, Colors.red);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) Navigator.pop(context);
          }
          break;
        case 'missed':
        case 'cancelled':
          if (mounted && !_navigating) Navigator.pop(context);
          break;
      }
    });
  }

  void _startTimeout() {
    _timeoutTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      _secondsElapsed++;
      setState(() {});
      if (_secondsElapsed >= _timeoutSeconds) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  Future<void> _onTimeout() async {
    await _callService.missedCall(widget.callId);
    if (mounted) {
      _showResult('Pas de réponse', Icons.phone_missed, Colors.orange);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  // 💡 تم إصلاح الدالة هنا واستدعائها عبر الكائن الموحد لمنع تضارب النسخ المحلية
 Future<void> _cancelCall() async {
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    HapticFeedback.mediumImpact();
    
    try {
      await _callService.cancelCall(widget.callId);
    } catch (e) {
      debugPrint("Erreur lors de l'annulation: $e");
    }

    if (mounted) Navigator.pop(context);
  }

  void _showResult(String msg, IconData icon, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(flex: 2),
              _buildAvatar(),
              const SizedBox(height: 32),
              Text(
                widget.receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildStatusRow(),
              const SizedBox(height: 16),
              _buildProgressBar(),
              const Spacer(flex: 3),
              _buildCancelButton(),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('SafeMind',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              widget.type == 'video'
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
              color: Colors.white60,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              widget.type == 'video' ? 'Vidéo' : 'Vocal',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, __) => SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _ring(_ring3, 236, 0.04),
            _ring(_ring2, 188, 0.09),
            _ring(_ring1, 140, 0.16),
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 6,
                    )
                  ],
                ),
                child: ClipOval(
                  child: widget.receiverAvatar != null
                      ? Image.network(widget.receiverAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar())
                      : _defaultAvatar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(Animation<double> anim, double size, double opacityFactor) {
    return Opacity(
      opacity: ((1 - anim.value) * opacityFactor * 10).clamp(0.0, 1.0),
      child: Container(
        width: size * anim.value,
        height: size * anim.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF6C63FF).withOpacity(0.3),
      child: Center(
        child: Text(
          widget.receiverName.isNotEmpty
              ? widget.receiverName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    final dots = '.' * ((_secondsElapsed % 3) + 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingDot(),
        const SizedBox(width: 8),
        Text(
          'Appel en cours$dots',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _secondsElapsed / _timeoutSeconds,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(
              _secondsElapsed < 30
                  ? const Color(0xFF6C63FF)
                  : Colors.orange,
            ),
            borderRadius: BorderRadius.circular(4),
            minHeight: 3,
          ),
          const SizedBox(height: 8),
          Text(
            '${_timeoutSeconds - _secondsElapsed}s',
            style: TextStyle(
              color: _secondsElapsed < 30
                  ? Colors.white38
                  : Colors.orange.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancelCall,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                )
              ],
            ),
            child: const Icon(Icons.call_end,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'Annuler',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF4ADE80),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
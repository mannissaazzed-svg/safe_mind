import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/services/location_service.dart';

class _C {
  static const teal    = Color(0xFF1D9E75);
  static const tealL   = Color(0xFFE1F5EE);
  static const tealD   = Color(0xFF0F6E56);
  static const blue    = Color(0xFF185FA5);
  static const red     = Color(0xFFE24B4A);
  static const gray    = Color(0xFF888780);
  static const surface = Color(0xFFFFFFFF);
  static const border  = Color(0x1A000000);
}

class PatientMapScreen extends StatefulWidget {
  final String  patientId;
  final String? companionId;
  final String  patientName;

  const PatientMapScreen({
    super.key,
    required this.patientId,
    this.companionId,
    required this.patientName,
  });

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends State<PatientMapScreen>
    with TickerProviderStateMixin {
  final _map = MapController();
  final _db  = Supabase.instance.client;

  LatLng?  _pos;
  bool     _loading = true;
  bool     _outside = false;
  bool     _sosSent = false;
  bool     _bgOn    = false;
  double   _zoneR   = 200;
  LatLng?  _zoneC;

  StreamSubscription<Position>? _fgSub;
  StreamSubscription?           _bgSub;
  late AnimationController      _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    await _ensurePermission();

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('GPS init: $e');
    }

    if (mounted) {
      setState(() {
        if (pos != null) _pos = LatLng(pos!.latitude, pos.longitude);
        _loading = false;
      });
      if (pos != null) {
        _map.move(_pos!, 16);
        await _pushToDB(pos!.latitude, pos!.longitude, pos!.speed);
      }
    }

    await _loadZone();

    
    await _startBg();

    
    _fgSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((p) async {
      if (!mounted) return;
      await _applyPosition(p.latitude, p.longitude, p.speed);
    }, onError: (e) => debugPrint('FG stream: $e'));

   
    _bgSub = LocationService.positionStream.listen((d) {
      if (!mounted || d == null) return;
      _applyPosition(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
        (d['spd'] as num?)?.toDouble() ?? 0,
      );
    });
  }

  Future<void> _ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.whileInUse && mounted) _askBgPermission();
    } catch (_) {}
  }

  void _askBgPermission() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Permission requise',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Pour que votre accompagnateur vous localise même quand l\'app est fermée, '
            'autorisez "Toujours" dans les paramètres.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Plus tard',
                  style: GoogleFonts.poppins(color: _C.gray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: Text('Ouvrir paramètres',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startBg() async {
    try {
      await LocationService.start(widget.patientId);
      final running = await LocationService.isRunning;
      if (mounted) setState(() => _bgOn = running);
    } catch (e) {
      debugPrint('BG start: $e');
    }
  }

  Future<void> _loadZone() async {
    try {
      final rows = await _db
          .from('safe_zones')
          .select()
          .eq('patient_id', widget.patientId)
          .limit(1);

      if (rows != null && (rows as List).isNotEmpty && mounted) {
        final r = rows.first as Map<String, dynamic>;
        setState(() {
          _zoneR = (r['radius_meters'] as num).toDouble();
          _zoneC = LatLng(
            (r['center_lat'] as num).toDouble(),
            (r['center_lng'] as num).toDouble(),
          );
        });
      }
    } catch (e) {
      debugPrint('Load zone: $e');
    }
  }

  Future<void> _applyPosition(double lat, double lng, double speed) async {
    final wasOut = _outside;
    bool out = false;
    if (_zoneC != null) {
      out = Geolocator.distanceBetween(
              lat, lng, _zoneC!.latitude, _zoneC!.longitude) >
          _zoneR;
    }
    if (mounted) setState(() { _pos = LatLng(lat, lng); _outside = out; });

    
    await _pushToDB(lat, lng, speed);

    if (out && !wasOut)  _sendAlert('zone_exit');
    if (!out && wasOut)  _sendAlert('zone_enter');
  }

  Future<void> _pushToDB(double lat, double lng, double speed) async {
    try {
      await _db.from('locations').upsert({
        'user_id':    widget.patientId,
        'latitude':   lat,
        'longitude':  lng,
        'speed':      speed >= 0 ? speed : null,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('DB push: $e');
    }
  }

  Future<void> _sendAlert(String type) async {
    if (widget.companionId == null || _pos == null) return;
    try {
      await _db.from('alerts').insert({
        'patient_id':      widget.patientId,
        'companion_id':    widget.companionId,
        'type':            type,
        'is_read':         false,
        'distance_meters': _zoneC != null
            ? Geolocator.distanceBetween(
                _pos!.latitude, _pos!.longitude,
                _zoneC!.latitude, _zoneC!.longitude)
            : null,
      });
    } catch (e) {
      debugPrint('Alert: $e');
    }
  }

  
  Future<void> _sendSOS() async {
    if (widget.companionId == null) {
      _snack('Aucun accompagnateur associé');
      return;
    }
    try {
     
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 6));
        if (pos != null) {
          await _pushToDB(pos.latitude, pos.longitude, pos.speed);
          if (mounted) {
            setState(() => _pos = LatLng(pos!.latitude, pos.longitude));
          }
        }
      } catch (_) {}

      await _db.from('alerts').insert({
        'patient_id':      widget.patientId,
        'companion_id':    widget.companionId,
        'type':            'sos',
        'is_read':         false,
        'distance_meters': _zoneC != null && _pos != null
            ? Geolocator.distanceBetween(
                _pos!.latitude, _pos!.longitude,
                _zoneC!.latitude, _zoneC!.longitude)
            : null,
      });

      if (mounted) setState(() => _sosSent = true);
      HapticFeedback.heavyImpact();
      _snack('Appel envoyé à votre accompagnateur !', ok: true);
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => _sosSent = false);
    } catch (e) {
      _snack('Échec — réessayez');
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: ok ? _C.teal : _C.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    return Scaffold(body: Stack(children: [
      _buildMap(),
      _buildTopBar(),
      if (_outside) _buildWarnBanner(),
      _buildBgBadge(),
      _buildFabs(),
      _buildSOSButton(),
    ]));
  }

  Widget _buildLoading() => Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: _C.teal),
          const SizedBox(height: 16),
          Text('Localisation en cours...',
              style: GoogleFonts.poppins(color: _C.gray)),
        ])),
      );

  Widget _buildMap() => FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _pos ?? const LatLng(35.698, 0.633),
          initialZoom: 16,
          maxZoom: 19,
          minZoom: 4,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.safemind.app',
            maxZoom: 19,
          ),
          if (_zoneC != null)
            CircleLayer(circles: [
              CircleMarker(
                point: _zoneC!,
                radius: _zoneR,
                color: (_outside ? _C.red : _C.teal).withOpacity(0.08),
                borderColor:
                    (_outside ? _C.red : _C.teal).withOpacity(0.5),
                borderStrokeWidth: 2.5,
                useRadiusInMeter: true,
              ),
            ]),
          if (_pos != null)
            MarkerLayer(markers: [
              Marker(
                point: _pos!,
                width: 70,
                height: 70,
                child: _PulseMarker(
                    color: _outside ? _C.red : _C.teal, ctrl: _pulse),
              ),
            ]),
        ],
      );

  Widget _buildTopBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _C.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _C.tealD, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
                child: Row(children: [
                  _BlinkDot(color: _outside ? _C.red : _C.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _outside
                          ? 'Hors de la zone sécurisée'
                          : 'Dans la zone sécurisée',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _outside ? _C.red : _C.tealD),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ]).animate().fadeIn(duration: 300.ms),
        ),
      );

  Widget _buildWarnBanner() => Positioned(
        top: 0, left: 0, right: 0,
        child: Container(
          color: _C.red,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 16, right: 16, bottom: 12),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Vous êtes hors de la zone sécurisée !',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            )),
            GestureDetector(
              onTap: _sendSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('SOS',
                    style: GoogleFonts.poppins(
                        color: _C.red, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
          ]),
        ).animate().slideY(begin: -1, end: 0, duration: 300.ms),
      );

  Widget _buildBgBadge() => Positioned(
        bottom: 140, left: 14,
        child: GestureDetector(
          onTap: () async {
            if (_bgOn) {
              await LocationService.stop();
              if (mounted) setState(() => _bgOn = false);
            } else {
              await _startBg();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _bgOn ? _C.tealL : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _bgOn ? _C.teal : _C.gray),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: _bgOn ? _C.teal : _C.gray, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(_bgOn ? 'Partage actif' : 'Partage inactif',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _bgOn ? _C.tealD : _C.gray)),
            ]),
          ),
        ),
      );

  Widget _buildFabs() => Positioned(
        bottom: 140, right: 14,
        child: Column(children: [
          _Fab(icon: Icons.add,
              onTap: () => _map.move(_map.camera.center, _map.camera.zoom + 1)),
          const SizedBox(height: 8),
          _Fab(icon: Icons.remove,
              onTap: () => _map.move(_map.camera.center, _map.camera.zoom - 1)),
          const SizedBox(height: 8),
          _Fab(icon: Icons.my_location, color: _C.teal,
              onTap: () { if (_pos != null) _map.move(_pos!, 16); }),
        ]),
      );

  Widget _buildSOSButton() => Positioned(
        bottom: 0, left: 0, right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: _sosSent ? null : _sendSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: _sosSent ? _C.teal : _C.red,
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: _sosSent ? 0 : 4,
              ),
              icon: Icon(
                  _sosSent ? Icons.check_circle : Icons.sos_rounded,
                  size: 26, color: Colors.white),
              label: Text(
                _sosSent
                    ? 'Appel envoyé ✓'
                    : 'Appel de détresse à l\'accompagnateur',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _fgSub?.cancel();
    _bgSub?.cancel();
    _pulse.dispose();
    super.dispose();
  }
}


class _PulseMarker extends StatelessWidget {
  final Color color; final AnimationController ctrl;
  const _PulseMarker({required this.color, required this.ctrl});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => Transform.scale(
      scale: 0.85 + ctrl.value * 0.3,
      child: Container(
        width: 70, height: 70,
        decoration:
            BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(child: Container(
          width: 32, height: 32,
          decoration:
              BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
          child: Center(child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)],
            ),
          )),
        )),
      ),
    ),
  );
}

class _BlinkDot extends StatefulWidget {
  final Color color; const _BlinkDot({required this.color});
  @override State<_BlinkDot> createState() => _BlinkDotState();
}
class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
    child: Container(width: 9, height: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
}

class _Fab extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color? color;
  const _Fab({required this.icon, required this.onTap, this.color});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Icon(icon, size: 19, color: color ?? _C.gray),
    ),
  );
}

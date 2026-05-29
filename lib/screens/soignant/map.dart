import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class PatientLocation {
  final double lat, lng;
  final double? speed;
  final DateTime at;
  const PatientLocation({required this.lat, required this.lng, this.speed, required this.at});
  LatLng get latlng => LatLng(lat, lng);
  factory PatientLocation.fromJson(Map<String, dynamic> j) => PatientLocation(
    lat: (j['latitude'] as num).toDouble(),
    lng: (j['longitude'] as num).toDouble(),
    speed: j['speed'] != null ? (j['speed'] as num).toDouble() : null,
    at: DateTime.parse(j['updated_at']),
  );
}

class AlertItem {
  final int id; final String type; final double? dist; final DateTime at; bool read;
  AlertItem({required this.id, required this.type, this.dist, required this.at, required this.read});
  String get label => type == 'zone_exit'
      ? 'A quitté la zone'
      : type == 'sos'
          ? 'Appel de détresse !'
          : type == 'zone_enter'
              ? 'Retour en zone'
              : type;
  Color get color => (type == 'zone_exit' || type == 'sos')
      ? const Color(0xFFE24B4A)
      : const Color(0xFF1D9E75);
  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
    id: j['id'], type: j['type'],
    dist: j['distance_meters'] != null ? (j['distance_meters'] as num).toDouble() : null,
    at: DateTime.parse(j['created_at']),
    read: j['is_read'] ?? false,
  );
}



class _C {
  static const teal    = Color(0xFF1D9E75);
  static const tealL   = Color(0xFFE1F5EE);
  static const tealD   = Color(0xFF0F6E56);
  static const blue    = Color(0xFF185FA5);
  static const blueL   = Color(0xFFE6F1FB);
  static const red     = Color(0xFFE24B4A);
  static const redL    = Color(0xFFFCEBEB);
  static const amber   = Color(0xFFF5A623);
  static const gray    = Color(0xFF888780);
  static const surface = Color(0xFFFFFFFF);
  static const border  = Color(0x1A000000);
}



class CompanionMapScreen extends StatefulWidget {
  final String companionId, patientId, patientName;
  final String? patientDisease;
  const CompanionMapScreen({
    super.key,
    required this.companionId,
    required this.patientId,
    required this.patientName,
    this.patientDisease,
  });
  @override State<CompanionMapScreen> createState() => _CompanionMapScreenState();
}

class _CompanionMapScreenState extends State<CompanionMapScreen>
    with TickerProviderStateMixin {
  final _map    = MapController();
  final _db     = Supabase.instance.client;
  final _search = TextEditingController();


  LatLng?          _myPos;
  PatientLocation? _patient;
  double           _zoneR   = 200;
  LatLng?          _zoneC;
  List<AlertItem>  _alerts  = [];
  AlertItem?       _active;         
  bool             _follow  = true;
  bool             _outside = false;
  bool             _loading = true;
  bool             _searching         = false;
  bool             _isFetchingPatient = false;
  String           _pAddr  = '';
  DateTime?        _lastUp;
  LatLng?          _sDest;
  String           _sLabel = '';
  List<LatLng>     _route  = [];

  
  final Set<int> _shownAlertIds = {};

  StreamSubscription? _locSub, _alertSub;
  StreamSubscription<Position>? _mySub;
  late AnimationController _pPulse, _mPulse, _shake;

  @override
  void initState() {
    super.initState();
    _pPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _mPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _shake  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _init();
  }

  Future<void> _init() async {
    await _initMyPos();
    await _loadZone();
    await _loadPatient();
    if (mounted) setState(() => _loading = false);
    _listenPatient();
    _listenAlerts();
    await _loadAlerts();
    _mySub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((p) {
      if (!mounted) return;
      setState(() => _myPos = LatLng(p.latitude, p.longitude));
    });
  }

  Future<void> _initMyPos() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _myPos = LatLng(p.latitude, p.longitude));
    } catch (e) { debugPrint('My pos: $e'); }
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
          _zoneC = LatLng((r['center_lat'] as num).toDouble(), (r['center_lng'] as num).toDouble());
        });
      }
    } catch (e) { debugPrint('Zone: $e'); }
  }

  Future<void> _loadPatient() async {
    try {
      final rows = await _db
          .from('locations')
          .select()
          .eq('user_id', widget.patientId)
          .order('updated_at', ascending: false)
          .limit(1);
      if (rows != null && (rows as List).isNotEmpty) {
        _applyPatient(PatientLocation.fromJson(rows.first as Map<String, dynamic>));
      }
    } catch (e) { debugPrint('Load patient: $e'); }
  }

  void _listenPatient() {
    _locSub = _db
        .from('locations')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', widget.patientId)
        .order('updated_at')
        .listen((rows) {
          if (!mounted || rows.isEmpty) return;
          _applyPatient(PatientLocation.fromJson(rows.last));
          if (_follow && _patient != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _map.move(_patient!.latlng, _map.camera.zoom);
            });
          }
        });
  }

  void _applyPatient(PatientLocation loc) {
    final out = _zoneC != null &&
        Geolocator.distanceBetween(loc.lat, loc.lng, _zoneC!.latitude, _zoneC!.longitude) > _zoneR;
    setState(() { _patient = loc; _outside = out; _lastUp = loc.at; });
    _geocode(loc.lat, loc.lng);
  }

  
  void _listenAlerts() {
    _alertSub = _db
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('companion_id', widget.companionId)
        .order('created_at', ascending: false)
        .limit(5)
        .listen((rows) {
          if (!mounted || rows.isEmpty) return;

          for (final row in rows) {
            final a = AlertItem.fromJson(row);
            if (a.read) continue;
            if (_shownAlertIds.contains(a.id)) continue;

            _shownAlertIds.add(a.id);
            setState(() => _active = a);
            HapticFeedback.vibrate();
            _shake.forward().then((_) => _shake.reverse());

           
            if (a.type == 'sos') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showSosDialog(a);
              });
            }
          }
        });
  }

  
  void _showSosDialog(AlertItem alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.red,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Pulsing SOS icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.sos_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 20),
              Text('APPEL DE DÉTRESSE',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(widget.patientName,
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
              if (alert.dist != null) ...[
                const SizedBox(height: 4),
                Text('Distance: ${_fmtDist(alert.dist!)}',
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              // Locate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _goToPatient();
                    _dismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _C.red,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.location_searching, size: 22),
                  label: Text('Localiser maintenant',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _dismiss();
                },
                child: Text('Ignorer',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 13)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAlerts() async {
    try {
      final r = await _db
          .from('alerts')
          .select()
          .eq('companion_id', widget.companionId)
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() => _alerts = (r as List).map((x) => AlertItem.fromJson(x)).toList());
      }
    } catch (_) {}
  }

  Future<void> _geocode(double lat, double lng) async {
    try {
      final r = await placemarkFromCoordinates(lat, lng);
      if (r.isNotEmpty && mounted) {
        final p = r.first;
        setState(() => _pAddr = [p.street, p.locality]
            .where((e) => e != null && e!.isNotEmpty)
            .join(', '));
      }
    } catch (_) {}
  }

  Future<void> _updateZone(double r) async {
    setState(() => _zoneR = r);
    final c = _patient?.latlng ?? _zoneC;
    if (c == null) return;
    setState(() => _zoneC = c);
    try {
      await _db.from('safe_zones').upsert({
        'patient_id':    widget.patientId,
        'center_lat':    c.latitude,
        'center_lng':    c.longitude,
        'radius_meters': r.round(),
        'label':         'Zone sécurisée',
      }, onConflict: 'patient_id');
    } catch (_) {}
  }

  
  Future<void> _goToPatient() async {
    if (_isFetchingPatient) return;
    setState(() => _isFetchingPatient = true);
    try {
      final rows = await _db
          .from('locations')
          .select()
          .eq('user_id', widget.patientId)
          .order('updated_at', ascending: false)
          .limit(1);

      if (rows != null && (rows as List).isNotEmpty && mounted) {
        final loc = PatientLocation.fromJson(rows.first as Map<String, dynamic>);
        setState(() {
          _patient = loc;
          _lastUp  = loc.at;
          _outside = _zoneC != null &&
              Geolocator.distanceBetween(
                      loc.lat, loc.lng, _zoneC!.latitude, _zoneC!.longitude) >
                  _zoneR;
        });
        _map.move(loc.latlng, 17);
        setState(() => _follow = true);
        _showSuccessSnack('${widget.patientName} localisé');
      } else {
        _showWarningSnack('En attente de la première position de ${widget.patientName}...');
      }
    } catch (e) {
      debugPrint('goToPatient: $e');
      _showErrorSnack('Erreur de connexion — réessayez');
    } finally {
      if (mounted) setState(() => _isFetchingPatient = false);
    }
  }

  Future<void> _dismiss() async {
    if (_active == null) return;
    try { await _db.from('alerts').update({'is_read': true}).eq('id', _active!.id); } catch (_) {}
    setState(() => _active = null);
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final locs = await locationFromAddress(q);
      if (locs.isNotEmpty) {
        final d = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() { _sDest = d; _sLabel = q; _route = [if (_myPos != null) _myPos!, d]; _follow = false; });
        _map.move(d, 15);
      } else { _showWarningSnack('Lieu introuvable'); }
    } catch (_) { _showErrorSnack('Erreur recherche'); }
    finally { if (mounted) setState(() => _searching = false); }
  }

  void _clearRoute() => setState(() { _sDest = null; _sLabel = ''; _route = []; _search.clear(); });

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: _C.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: _C.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showWarningSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.hourglass_empty, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.poppins())),
      ]),
      backgroundColor: _C.amber,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  double get _dist {
    if (_myPos == null || _patient == null) return 0;
    return Geolocator.distanceBetween(_myPos!.latitude, _myPos!.longitude, _patient!.lat, _patient!.lng);
  }

  double get _sDist {
    if (_myPos == null || _sDest == null) return 0;
    return Geolocator.distanceBetween(_myPos!.latitude, _myPos!.longitude, _sDest!.latitude, _sDest!.longitude);
  }

  String _fmt(double m) => m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  String _fmtDist(double m) => _fmt(m);

  String _time(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'À l\'instant';
    if (d.inMinutes < 60) return 'Il y a ${d.inMinutes} min';
    return 'Il y a ${d.inHours} h';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoad();
    return Scaffold(body: Stack(children: [
      _buildMap(),
      if (_active != null) _buildAlert(),
      _buildInfoCard(),
      _buildSearchBar(),
      _buildBack(),
      _buildFabs(),
      _buildPanel(),
    ]));
  }

  Widget _buildLoad() => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(color: _C.teal), const SizedBox(height: 16),
    Text('Connexion...', style: GoogleFonts.poppins(color: _C.gray)),
  ])));

  Widget _buildBack() => Positioned(
    top: MediaQuery.of(context).padding.top + 10, left: 12,
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: _C.surface, shape: BoxShape.circle,
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.tealD, size: 18),
      ),
    ).animate().fadeIn(duration: 300.ms),
  );

  Widget _buildSearchBar() {
    final top = _active != null
        ? MediaQuery.of(context).padding.top + 130.0
        : MediaQuery.of(context).padding.top + 80.0;
    return Positioned(
      top: top, left: 12, right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
                color: _C.surface, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _C.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)]),
            child: Row(children: [
              const SizedBox(width: 12),
              _searching
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _C.blue))
                  : const Icon(Icons.search_rounded, color: _C.gray, size: 20),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _search,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: GoogleFonts.poppins(color: _C.gray, fontSize: 12),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _doSearch(),
              )),
              if (_search.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearRoute,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.close_rounded, color: _C.gray, size: 18),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: ElevatedButton(
                  onPressed: _doSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.blue,
                    minimumSize: const Size(38, 36), padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          if (_sDest != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: _C.blueL,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _C.blue.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.navigation_rounded, color: _C.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dest : $_sLabel',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_myPos != null)
                    Text(_fmt(_sDist),
                        style: GoogleFonts.poppins(fontSize: 10, color: _C.blue)),
                ])),
                GestureDetector(onTap: _clearRoute,
                    child: const Icon(Icons.close_rounded, color: _C.blue, size: 18)),
              ]),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 250.ms),
    );
  }

  Widget _buildMap() => FlutterMap(
    mapController: _map,
    options: MapOptions(
      initialCenter: _patient?.latlng ?? _myPos ?? const LatLng(35.698, 0.633),
      initialZoom: 15, maxZoom: 19, minZoom: 5,
      onTap: (_, __) => setState(() => _follow = false),
    ),
    children: [
      TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safemind.app', maxZoom: 19),
      if (_zoneC != null)
        CircleLayer(circles: [CircleMarker(
          point: _zoneC!, radius: _zoneR,
          color: (_outside ? _C.red : _C.teal).withOpacity(0.07),
          borderColor: (_outside ? _C.red : _C.teal).withOpacity(0.45),
          borderStrokeWidth: 2, useRadiusInMeter: true,
        )]),
      if (_route.length >= 2)
        PolylineLayer(polylines: [Polyline(
          points: _route, color: _C.blue, strokeWidth: 3.5,
          borderColor: _C.blue.withOpacity(0.2), borderStrokeWidth: 7,
        )]),
      if (_sDest != null)
        MarkerLayer(markers: [Marker(
          point: _sDest!, width: 44, height: 54,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: _C.blue, borderRadius: BorderRadius.circular(8)),
              child: Text(
                _sLabel.length > 12 ? '${_sLabel.substring(0, 12)}…' : _sLabel,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.location_pin, color: _C.blue, size: 32),
          ]),
        )]),
      if (_myPos != null && _patient != null)
        PolylineLayer(polylines: [Polyline(
          points: [_myPos!, _patient!.latlng],
          color: _C.blue.withOpacity(0.45), strokeWidth: 1.8,
          pattern: StrokePattern.dotted(),
        )]),
      if (_patient != null)
        MarkerLayer(markers: [Marker(
          point: _patient!.latlng, width: 80, height: 80,
          child: _PatientMarker(name: widget.patientName, out: _outside, ctrl: _pPulse),
        )]),
      if (_myPos != null)
        MarkerLayer(markers: [Marker(
          point: _myPos!, width: 54, height: 54,
          child: _CompanionMarker(ctrl: _mPulse),
        )]),
      if (_myPos != null && _patient != null && _dist > 0)
        MarkerLayer(markers: [Marker(
          point: LatLng(
            (_myPos!.latitude + _patient!.lat) / 2,
            (_myPos!.longitude + _patient!.lng) / 2,
          ),
          width: 70, height: 22,
          child: Container(
            decoration: BoxDecoration(
                color: _C.surface, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.blue.withOpacity(0.4))),
            child: Center(child: Text(_fmt(_dist),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: _C.blue, fontWeight: FontWeight.w600))),
          ),
        )]),
    ],
  );

  Widget _buildAlert() {
    final a = _active!;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (_, c) => Transform.translate(
          offset: Offset(_shake.value * 6 * ((_shake.value * 10).toInt().isEven ? 1 : -1), 0),
          child: c,
        ),
        child: Container(
          color: a.color,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 14, right: 14, bottom: 12),
          child: Row(children: [
            Icon(a.type == 'sos' ? Icons.sos : Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.label,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                if (a.dist != null)
                  Text('${_fmt(a.dist!)} • ${widget.patientName}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
              ],
            )),
            GestureDetector(
              onTap: () { _goToPatient(); _dismiss(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4))),
                child: Text('Suivre →',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(onTap: _dismiss,
                child: const Icon(Icons.close, color: Colors.white70, size: 18)),
          ]),
        ).animate().slideY(begin: -1, end: 0, duration: 300.ms),
      ),
    );
  }

  Widget _buildInfoCard() {
    final top = _active != null
        ? MediaQuery.of(context).padding.top + 70.0
        : MediaQuery.of(context).padding.top + 10.0;
    return Positioned(
      top: top, left: 62, right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _C.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)]),
        child: Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: _C.tealL,
            child: Text(
              widget.patientName.isNotEmpty ? widget.patientName[0] : 'P',
              style: GoogleFonts.poppins(color: _C.tealD, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patientName,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
            if (_pAddr.isNotEmpty)
              Text(_pAddr,
                  style: GoogleFonts.poppins(fontSize: 11, color: _C.gray),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_lastUp != null)
              Text('Màj : ${_time(_lastUp!)}',
                  style: GoogleFonts.poppins(fontSize: 10, color: _C.gray)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _Pill(out: _outside),
            if (_dist > 0) ...[
              const SizedBox(height: 4),
              Text(_fmt(_dist), style: GoogleFonts.poppins(fontSize: 11, color: _C.gray)),
            ],
          ]),
        ]),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildFabs() => Positioned(
    bottom: _alerts.isEmpty ? 200 : 250, right: 12,
    child: Column(children: [
      _Fab(icon: Icons.add,
          onTap: () => _map.move(_map.camera.center, _map.camera.zoom + 1)),
      const SizedBox(height: 8),
      _Fab(icon: Icons.remove,
          onTap: () => _map.move(_map.camera.center, _map.camera.zoom - 1)),
      const SizedBox(height: 8),
      _Fab(icon: Icons.my_location, color: _C.blue,
          onTap: () { if (_myPos != null) { _map.move(_myPos!, 16); setState(() => _follow = false); } }),
      const SizedBox(height: 8),
      _Fab(
        icon: Icons.gps_fixed,
        color: _follow ? _C.teal : _C.gray,
        onTap: () {
          setState(() => _follow = !_follow);
          if (_follow && _patient != null) _map.move(_patient!.latlng, 17);
        },
      ),
    ]),
  );

  Widget _buildPanel() => Positioned(
    bottom: 0, left: 0, right: 0,
    child: SafeArea(child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
          color: _C.surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 18)]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
            width: 36, height: 3.5,
            decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 10),
        Row(children: [
          _Card(label: 'Distance', value: _fmt(_dist)),
          const SizedBox(width: 8),
          _Card(
            label: 'Vitesse',
            value: _patient?.speed != null
                ? '${(_patient!.speed! * 3.6).toStringAsFixed(1)} km/h'
                : '—',
          ),
          const SizedBox(width: 8),
          _Card(label: 'Arrivée', value: _dist > 0 ? '${(_dist / 80).ceil()} min' : '—'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.shield_outlined, color: _C.blue, size: 16),
          const SizedBox(width: 6),
          Text('Zone sécurisée',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue)),
          const Spacer(),
          Text('${_zoneR.round()} m',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.blue)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _C.blue, inactiveTrackColor: _C.blueL,
            thumbColor: _C.blue, overlayColor: _C.blue.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _zoneR, min: 50, max: 1000, divisions: 19,
            onChanged: (v) => setState(() => _zoneR = v),
            onChangeEnd: _updateZone,
          ),
        ),
        if (_alerts.isNotEmpty) ...[
          const Divider(height: 16, thickness: 0.5),
          Text('Dernières alertes', style: GoogleFonts.poppins(fontSize: 11, color: _C.gray)),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _alerts.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final a = _alerts[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: a.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: a.color.withOpacity(0.25))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.label,
                        style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w600, color: a.color)),
                    Text('${a.at.hour}:${a.at.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(fontSize: 9, color: _C.gray)),
                  ]),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isFetchingPatient ? null : _goToPatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.teal,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: _isFetchingPatient
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.location_searching, size: 20),
          label: Text(
            _isFetchingPatient ? 'Recherche...' : 'Voir la position du patient',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    )),
  );

  @override
  void dispose() {
    _locSub?.cancel(); _alertSub?.cancel(); _mySub?.cancel();
    _pPulse.dispose(); _mPulse.dispose(); _shake.dispose(); _search.dispose();
    super.dispose();
  }
}



class _PatientMarker extends StatelessWidget {
  final String name; final bool out; final AnimationController ctrl;
  const _PatientMarker({required this.name, required this.out, required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final c = out ? _C.red : _C.teal;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
        child: Text(name.split(' ').first,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 2),
      AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Transform.scale(
          scale: 0.85 + ctrl.value * 0.25,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: c.withOpacity(0.18), shape: BoxShape.circle),
            child: Center(child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: c.withOpacity(0.35), shape: BoxShape.circle),
              child: Center(child: Container(
                width: 13, height: 13,
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)],
                ),
              )),
            )),
          ),
        ),
      ),
    ]);
  }
}

class _CompanionMarker extends StatelessWidget {
  final AnimationController ctrl;
  const _CompanionMarker({required this.ctrl});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => Transform.scale(
      scale: 0.9 + ctrl.value * 0.1,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(color: _C.blue.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: _C.blue, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.5), blurRadius: 8)],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 13),
        )),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  final bool out; const _Pill({required this.out});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: out ? _C.redL : _C.tealL, borderRadius: BorderRadius.circular(20)),
    child: Text(out ? 'Hors zone' : 'En sécurité',
        style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: out ? _C.red : _C.tealD)),
  );
}

class _Card extends StatelessWidget {
  final String label, value; const _Card({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFF1EFE8), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _C.gray)),
    ]),
  ));
}

class _Fab extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color? color;
  const _Fab({required this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: _C.surface, shape: BoxShape.circle,
          border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Icon(icon, size: 18, color: color ?? _C.gray),
    ),
  );
}


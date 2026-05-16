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
  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime updatedAt;

  const PatientLocation({
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.updatedAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory PatientLocation.fromJson(Map<String, dynamic> j) => PatientLocation(
        latitude:  (j['latitude']  as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        speed:     j['speed'] != null ? (j['speed'] as num).toDouble() : null,
        updatedAt: DateTime.parse(j['updated_at']),
      );
}

class AlertItem {
  final int id;
  final String type;
  final double? distanceMeters;
  final DateTime createdAt;
  bool isRead;

  AlertItem({
    required this.id,
    required this.type,
    this.distanceMeters,
    required this.createdAt,
    required this.isRead,
  });

  String get label {
    switch (type) {
      case 'zone_exit':  return 'A quitté la zone sécurisée';
      case 'sos':        return 'Appel de détresse !';
      case 'zone_enter': return 'Est retourné dans la zone sécurisée';
      default:           return type;
    }
  }

  Color get color {
    switch (type) {
      case 'zone_exit': return const Color(0xFFE24B4A);
      case 'sos':       return const Color(0xFFE24B4A);
      default:          return const Color(0xFF1D9E75);
    }
  }

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id:             j['id'],
        type:           j['type'],
        distanceMeters: j['distance_meters'] != null ? (j['distance_meters'] as num).toDouble() : null,
        createdAt:      DateTime.parse(j['created_at']),
        isRead:         j['is_read'] ?? false,
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
  static const amber   = Color(0xFFBA7517);
  static const amberL  = Color(0xFFFAEEDA);
  static const gray    = Color(0xFF888780);
  static const grayL   = Color(0xFFF1EFE8);
  static const surface = Color(0xFFFFFFFF);
  static const border  = Color(0x1A000000);
}



class CompanionMapScreen extends StatefulWidget {
  
  final String companionId;

  
  final String patientId;

  
  final String patientName;

 
  final String? patientDisease;

  const CompanionMapScreen({
    super.key,
    required this.companionId,
    required this.patientId,
    required this.patientName,
    this.patientDisease,
  });

  @override
  State<CompanionMapScreen> createState() => _CompanionMapScreenState();
}

class _CompanionMapScreenState extends State<CompanionMapScreen>
    with TickerProviderStateMixin {

  final _mapCtrl    = MapController();
  final _supabase   = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  
  LatLng?          _myPos;
  PatientLocation? _patientLoc;
  double           _safeZoneRadius = 200;
  LatLng?          _safeZoneCenter;
  List<AlertItem>  _alerts = [];
  AlertItem?       _activeAlert;
  bool             _followPatient   = true;
  bool             _patientOutside  = false;
  bool             _isLoading       = true;
  bool             _isSearching     = false;
  String           _patientAddress  = '';
  String           _myAddress       = '';
  DateTime?        _lastUpdate;

  
  LatLng?          _searchDest;
  String           _searchDestLabel = '';
  List<LatLng>     _routePoints     = [];

  
  StreamSubscription? _locationSub;
  StreamSubscription? _alertSub;
  StreamSubscription<Position>? _myPosSub;

 
  late AnimationController _patientPulse;
  late AnimationController _myPulse;
  late AnimationController _alertShake;

  @override
  void initState() {
    super.initState();
    _patientPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _myPulse      = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _alertShake   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _init();
  }

 
  Future<void> _init() async {
    
    await _initMyLocation();

   
    await _loadSafeZone();

   
    await _loadPatientLocation();

    setState(() => _isLoading = false);

    
    _listenPatientLocation();

    
    _listenAlerts();

   
    await _loadRecentAlerts();

    
    _myPosSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
      _reverseGeocode(pos.latitude, pos.longitude, isPatient: false);
    });
  }

  Future<void> _initMyLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  Future<void> _loadSafeZone() async {
    try {
      final row = await _supabase
          .from('safe_zones')
          .select()
          .eq('patient_id', widget.patientId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _safeZoneRadius = (row['radius_meters'] as num).toDouble();
          _safeZoneCenter = LatLng(
            (row['center_lat'] as num).toDouble(),
            (row['center_lng'] as num).toDouble(),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPatientLocation() async {
    try {
      final row = await _supabase
          .from('locations')
          .select()
          .eq('user_id', widget.patientId)
          .maybeSingle();
      if (row != null && mounted) {
        final loc = PatientLocation.fromJson(row);
        _updatePatientPos(loc);
      }
    } catch (_) {}
  }

  void _listenPatientLocation() {
    _locationSub = _supabase
        .from('locations')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', widget.patientId)
        .listen((rows) {
          if (!mounted || rows.isEmpty) return;
          final loc = PatientLocation.fromJson(rows.first);
          _updatePatientPos(loc);
        });
  }

  void _updatePatientPos(PatientLocation loc) {
    final outside = _safeZoneCenter != null &&
        Geolocator.distanceBetween(
              loc.latitude, loc.longitude,
              _safeZoneCenter!.latitude, _safeZoneCenter!.longitude,
            ) >
            _safeZoneRadius;

    setState(() {
      _patientLoc     = loc;
      _patientOutside = outside;
      _lastUpdate     = loc.updatedAt;
    });

    if (_followPatient) {
      _mapCtrl.move(loc.latLng, _mapCtrl.camera.zoom);
    }

    _reverseGeocode(loc.latitude, loc.longitude, isPatient: true);
  }

  void _listenAlerts() {
    _alertSub = _supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('companion_id', widget.companionId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((rows) {
          if (!mounted || rows.isEmpty) return;
          final alert = AlertItem.fromJson(rows.first);
          if (!alert.isRead) {
            setState(() => _activeAlert = alert);
            HapticFeedback.vibrate();
            _alertShake.forward().then((_) => _alertShake.reverse());
          }
        });
  }

  Future<void> _loadRecentAlerts() async {
    try {
      final rows = await _supabase
          .from('alerts')
          .select()
          .eq('companion_id', widget.companionId)
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _alerts = (rows as List)
              .map((r) => AlertItem.fromJson(r as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
  }

  

  Future<void> _reverseGeocode(double lat, double lng, {required bool isPatient}) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty && mounted) {
        final p = places.first;
        final addr = [p.street, p.locality]
            .where((e) => e != null && e!.isNotEmpty)
            .join(', ');
        setState(() {
          if (isPatient) _patientAddress = addr;
          else           _myAddress      = addr;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateSafeZone(double radius) async {
    setState(() => _safeZoneRadius = radius);

    final center = _patientLoc?.latLng ?? _safeZoneCenter;
    if (center == null) return;

    setState(() => _safeZoneCenter = center);

    try {
      await _supabase.from('safe_zones').upsert({
        'patient_id':     widget.patientId,
        'center_lat':     center.latitude,
        'center_lng':     center.longitude,
        'radius_meters':  radius.round(),
        'label':          'Zone sécurisée',
      }, onConflict: 'patient_id');
    } catch (_) {}
  }

  void _goToPatient() {
    if (_patientLoc != null) {
      _mapCtrl.move(_patientLoc!.latLng, 17);
      setState(() => _followPatient = true);
    }
  }

  Future<void> _dismissAlert() async {
    if (_activeAlert == null) return;
    try {
      await _supabase
          .from('alerts')
          .update({'is_read': true})
          .eq('id', _activeAlert!.id);
    } catch (_) {}
    setState(() => _activeAlert = null);
  }

  double get _distanceToPatient {
    if (_myPos == null || _patientLoc == null) return 0;
    return Geolocator.distanceBetween(
      _myPos!.latitude, _myPos!.longitude,
      _patientLoc!.latitude, _patientLoc!.longitude,
    );
  }

  
  Future<void> _searchPlace() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locs = await locationFromAddress(q);
      if (locs.isNotEmpty) {
        final dest = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() {
          _searchDest      = dest;
          _searchDestLabel = q;
          _routePoints     = [if (_myPos != null) _myPos!, dest];
          _followPatient   = false;
        });
        _mapCtrl.move(dest, 15);
      } else {
        _showSnack('Lieu introuvable');
      }
    } catch (_) {
      _showSnack('Erreur de recherche, vérifiez votre connexion');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearRoute() => setState(() {
        _searchDest      = null;
        _searchDestLabel = '';
        _routePoints     = [];
        _searchCtrl.clear();
      });

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: _C.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _fmtDist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return 'Il y a ${diff.inHours} h';
  }

  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          if (_activeAlert != null) _buildAlertBanner(),
          _buildPatientInfoCard(),
          _buildSearchBar(),
          _buildBackButton(),
          _buildFabs(),
          _buildBottomPanel(),
        ],
      ),
    );
  }

 

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 12,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _C.tealD,
            size: 18,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  

  Widget _buildSearchBar() {
    final topOffset = _activeAlert != null
        ? MediaQuery.of(context).padding.top + 130.0
        : MediaQuery.of(context).padding.top + 80.0;

    return Positioned(
      top: topOffset,
      left: 12,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _C.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                _isSearching
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _C.blue),
                      )
                    : const Icon(Icons.search_rounded, color: _C.gray, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un lieu sur la carte...',
                      hintStyle: GoogleFonts.poppins(color: _C.gray, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _searchPlace(),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
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
                    onPressed: _searchPlace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.blue,
                      minimumSize: const Size(38, 36),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          if (_searchDest != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.blueL,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _C.blue.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: _C.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination : $_searchDestLabel',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_myPos != null)
                          Text(
                            'Distance : ${_fmtDist(_distanceToSearch)}',
                            style: GoogleFonts.poppins(fontSize: 10, color: _C.blue),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearRoute,
                    child: const Icon(Icons.close_rounded, color: _C.blue, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 250.ms),
    );
  }

  double get _distanceToSearch {
    if (_myPos == null || _searchDest == null) return 0;
    return Geolocator.distanceBetween(
      _myPos!.latitude, _myPos!.longitude,
      _searchDest!.latitude, _searchDest!.longitude,
    );
  }


  Widget _buildLoading() => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: _C.teal),
            const SizedBox(height: 16),
            Text('Connexion à la position du patient...', style: GoogleFonts.poppins(color: _C.gray)),
          ]),
        ),
      );

 

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _patientLoc?.latLng ?? _myPos ?? const LatLng(35.698, 0.633),
        initialZoom: 15,
        maxZoom: 19,
        minZoom: 5,
        onTap: (_, __) => setState(() => _followPatient = false),
      ),
      children: [
        
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safetrack.app',
          maxZoom: 19,
        ),

        
        if (_safeZoneCenter != null)
          CircleLayer(circles: [
            CircleMarker(
              point: _safeZoneCenter!,
              radius: _safeZoneRadius,
              color: (_patientOutside ? _C.red : _C.teal).withOpacity(0.07),
              borderColor: (_patientOutside ? _C.red : _C.teal).withOpacity(0.45),
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
            ),
          ]),

       
        if (_routePoints.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: _routePoints,
              color: _C.blue,
              strokeWidth: 3.5,
              borderColor: _C.blue.withOpacity(0.2),
              borderStrokeWidth: 7,
            ),
          ]),

        
        if (_searchDest != null)
          MarkerLayer(markers: [
            Marker(
              point: _searchDest!,
              width: 44, height: 54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _searchDestLabel.length > 14
                          ? '${_searchDestLabel.substring(0, 14)}…'
                          : _searchDestLabel,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.location_pin, color: _C.blue, size: 32),
                ],
              ),
            ),
          ]),

        
        if (_myPos != null && _patientLoc != null)
          PolylineLayer(polylines: [
            Polyline(
              points: [_myPos!, _patientLoc!.latLng],
              color: _C.blue.withOpacity(0.45),
              strokeWidth: 1.8,
              pattern: StrokePattern.dotted(),
            ),
          ]),

        // Marqueur du patient
        if (_patientLoc != null)
          MarkerLayer(markers: [
            Marker(
              point: _patientLoc!.latLng,
              width: 80, height: 80,
              child: _PatientMapMarker(
                name: widget.patientName,
                isOutside: _patientOutside,
                controller: _patientPulse,
              ),
            ),
          ]),

        // Marqueur de l'accompagnateur (moi)
        if (_myPos != null)
          MarkerLayer(markers: [
            Marker(
              point: _myPos!,
              width: 54, height: 54,
              child: _CompanionMarker(controller: _myPulse),
            ),
          ]),

        // Étiquette de distance sur la ligne
        if (_myPos != null && _patientLoc != null && _distanceToPatient > 0)
          MarkerLayer(markers: [
            Marker(
              point: LatLng(
                (_myPos!.latitude + _patientLoc!.latitude) / 2,
                (_myPos!.longitude + _patientLoc!.longitude) / 2,
              ),
              width: 70, height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.blue.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    _fmtDist(_distanceToPatient),
                    style: GoogleFonts.poppins(fontSize: 11, color: _C.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ]),
      ],
    );
  }

  

  Widget _buildAlertBanner() {
    final alert = _activeAlert!;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _alertShake,
        builder: (_, child) => Transform.translate(
          offset: Offset(_alertShake.value * 6 * ((_alertShake.value * 10).toInt().isEven ? 1 : -1), 0),
          child: child,
        ),
        child: Container(
          color: alert.color,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            left: 14, right: 14, bottom: 12,
          ),
          child: Row(
            children: [
              Icon(
                alert.type == 'sos' ? Icons.sos : Icons.warning_amber_rounded,
                color: Colors.white, size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.label,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (alert.distanceMeters != null)
                      Text(
                        'Distance : ${_fmtDist(alert.distanceMeters!)} • ${widget.patientName}',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () { _goToPatient(); _dismissAlert(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text('Suivre →', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismissAlert,
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ).animate().slideY(begin: -1, end: 0, duration: 300.ms),
      ),
    );
  }

  

  Widget _buildPatientInfoCard() {
    final topOffset = _activeAlert != null
        ? MediaQuery.of(context).padding.top + 70.0
        : MediaQuery.of(context).padding.top + 10.0;

    return Positioned(
      top: topOffset,
      // Décalage à droite pour laisser place au bouton retour (gauche)
      left: 62,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _C.tealL,
              child: Text(
                widget.patientName.isNotEmpty ? widget.patientName[0] : 'P',
                style: GoogleFonts.poppins(color: _C.tealD, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patientName,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  if (_patientAddress.isNotEmpty)
                    Text(_patientAddress,
                        style: GoogleFonts.poppins(fontSize: 11, color: _C.gray),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_lastUpdate != null)
                    Text('Màj : ${_fmtTime(_lastUpdate!)}',
                        style: GoogleFonts.poppins(fontSize: 10, color: _C.gray)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge de statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(isOutside: _patientOutside),
                const SizedBox(height: 4),
                if (_distanceToPatient > 0)
                  Text(
                    _fmtDist(_distanceToPatient),
                    style: GoogleFonts.poppins(fontSize: 11, color: _C.gray),
                  ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  

  Widget _buildFabs() {
    return Positioned(
      bottom: _alerts.isEmpty ? 200 : 250, right: 12,
      child: Column(
        children: [
          _MapFabBtn(
            icon: Icons.add,
            onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
          ),
          const SizedBox(height: 8),
          _MapFabBtn(
            icon: Icons.remove,
            onTap: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
          ),
          const SizedBox(height: 8),
          _MapFabBtn(
            icon: Icons.my_location,
            color: _C.blue,
            tooltip: 'Ma position',
            onTap: () {
              if (_myPos != null) {
                _mapCtrl.move(_myPos!, 16);
                setState(() => _followPatient = false);
              }
            },
          ),
          const SizedBox(height: 8),
          _MapFabBtn(
            icon: Icons.gps_fixed,
            color: _followPatient ? _C.teal : _C.gray,
            tooltip: 'Suivre le patient',
            onTap: () {
              setState(() => _followPatient = !_followPatient);
              if (_followPatient) _goToPatient();
            },
          ),
        ],
      ),
    );
  }

  
  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 18)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 36, height: 3.5,
                  decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 10),

              // Statistiques
              Row(
                children: [
                  _StatCard(label: 'Distance', value: _fmtDist(_distanceToPatient)),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Vitesse',
                    value: _patientLoc?.speed != null
                        ? '${((_patientLoc!.speed! * 3.6)).toStringAsFixed(1)} km/h'
                        : '—',
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: 'Arrivée',
                    value: _distanceToPatient > 0
                        ? '${(_distanceToPatient / 80).ceil()} min'
                        : '—',
                  ),
                ],
              ),

              // Réglage de la zone sécurisée
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: _C.blue, size: 16),
                  const SizedBox(width: 6),
                  Text('Zone sécurisée',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.blue)),
                  const Spacer(),
                  Text('${_safeZoneRadius.round()} m',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.blue)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _C.blue,
                  inactiveTrackColor: _C.blueL,
                  thumbColor: _C.blue,
                  overlayColor: _C.blue.withOpacity(0.1),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: _safeZoneRadius,
                  min: 50, max: 1000,
                  divisions: 19,
                  onChanged: (v) => setState(() => _safeZoneRadius = v),
                  onChangeEnd: _updateSafeZone,
                ),
              ),

              // Alertes récentes
              if (_alerts.isNotEmpty) ...[
                const Divider(height: 16, thickness: 0.5),
                Text('Dernières alertes',
                    style: GoogleFonts.poppins(fontSize: 11, color: _C.gray)),
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
                          border: Border.all(color: a.color.withOpacity(0.25)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, fontWeight: FontWeight.w600, color: a.color)),
                            Text(
                              '${a.createdAt.hour}:${a.createdAt.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(fontSize: 9, color: _C.gray),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Bouton de suivi principal
              ElevatedButton.icon(
                onPressed: _goToPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _patientOutside ? _C.red : _C.teal,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: Text(
                  _patientOutside ? 'Localiser le patient maintenant !' : 'Voir la position du patient',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _alertSub?.cancel();
    _myPosSub?.cancel();
    _patientPulse.dispose();
    _myPulse.dispose();
    _alertShake.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}



class _PatientMapMarker extends StatelessWidget {
  final String name;
  final bool isOutside;
  final AnimationController controller;

  const _PatientMapMarker({
    required this.name,
    required this.isOutside,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOutside ? _C.red : _C.teal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nom du patient
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name.split(' ').first,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        // Pulsation
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final s = 0.85 + controller.value * 0.25;
            return Transform.scale(
              scale: s,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: color.withOpacity(0.35), shape: BoxShape.circle),
                    child: Center(
                      child: Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompanionMarker extends StatelessWidget {
  final AnimationController controller;
  const _CompanionMarker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final s = 0.9 + controller.value * 0.1;
        return Transform.scale(
          scale: s,
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _C.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _C.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.5), blurRadius: 8)],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 13),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOutside;
  const _StatusPill({required this.isOutside});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutside ? _C.redL : _C.tealL,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOutside ? '⚠ Hors zone' : '✓ En sécurité',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOutside ? _C.red : _C.tealD,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: _C.gray)),
          ],
        ),
      ),
    );
  }
}

class _MapFabBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  const _MapFabBtn({required this.icon, required this.onTap, this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _C.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _C.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
          ),
          child: Icon(icon, size: 18, color: color ?? _C.gray),
        ),
      ),
    );
  }
}



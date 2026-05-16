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



class SafeZone {
  final String patientId;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;

  const SafeZone({
    required this.patientId,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
  });

  LatLng get center => LatLng(centerLat, centerLng);

  factory SafeZone.fromJson(Map<String, dynamic> j) => SafeZone(
        patientId: j['patient_id'],
        centerLat: (j['center_lat'] as num).toDouble(),
        centerLng: (j['center_lng'] as num).toDouble(),
        radiusMeters: (j['radius_meters'] as num).toDouble(),
      );
}

class SavedPlace {
  final int id;
  final String label;
  final double latitude;
  final double longitude;
  final String icon;

  const SavedPlace({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory SavedPlace.fromJson(Map<String, dynamic> j) => SavedPlace(
        id: j['id'],
        label: j['label'],
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        icon: j['icon'] ?? '📍',
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
  static const gray    = Color(0xFF888780);
  static const grayL   = Color(0xFFF1EFE8);
  static const surface = Color(0xFFFFFFFF);
  static const border  = Color(0x1A000000);
}



class PatientMapScreen extends StatefulWidget {
  
  final String patientId;

 
  final String? companionId;

  
  final String patientName;

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

  
  final _mapCtrl    = MapController();
  final _searchCtrl = TextEditingController();
  final _supabase   = Supabase.instance.client;

  
  LatLng?          _myPos;
  SafeZone?        _safeZone;
  List<SavedPlace> _savedPlaces = [];
  List<LatLng>     _routePoints = [];
  SavedPlace?      _selectedDest;
  String           _addressLabel = 'Localisation en cours...';
  bool             _isOutside    = false;
  bool             _isLoading    = true;
  bool             _isSearching  = false;
  bool             _sosSent      = false;

 
  StreamSubscription<Position>? _posSub;

  
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _init();
  }

  

  Future<void> _init() async {
    
    final ok = await _requestPermission();
    if (!ok && mounted) {
      _showSnack('Veuillez autoriser l\'accès à la localisation', isError: true);
    }

    
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).catchError((_) => null);

    if (pos != null && mounted) {
      setState(() {
        _myPos     = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      _mapCtrl.move(_myPos!, 16);
      _reverseGeocode(pos.latitude, pos.longitude);
    }

    
    await Future.wait([_loadSafeZone(), _loadSavedPlaces()]);

   
    _startTracking();
  }

  Future<bool> _requestPermission() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }

  Future<void> _loadSafeZone() async {
    try {
      final row = await _supabase
          .from('safe_zones')
          .select()
          .eq('patient_id', widget.patientId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => _safeZone = SafeZone.fromJson(row));
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final rows = await _supabase
          .from('saved_places')
          .select()
          .eq('user_id', widget.patientId)
          .order('label');
      if (mounted) {
        setState(() =>
            _savedPlaces = (rows as List).map((r) => SavedPlace.fromJson(r)).toList());
      }
    } catch (_) {}
  }

  void _startTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
    );

    _posSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) async {
      if (!mounted) return;
      final newPos = LatLng(pos.latitude, pos.longitude);

      // Calcul de sortie de zone sécurisée
      bool outside = false;
      if (_safeZone != null) {
        final dist = Geolocator.distanceBetween(
          newPos.latitude, newPos.longitude,
          _safeZone!.center.latitude, _safeZone!.center.longitude,
        );
        outside = dist > _safeZone!.radiusMeters;
      }

      setState(() {
        _myPos     = newPos;
        _isOutside = outside;
      });

      
      _pushLocation(pos);

     
      if (outside && !_isOutside) _sendZoneAlert('zone_exit', _safeZone!);
      if (!outside && _isOutside) _sendZoneAlert('zone_enter', _safeZone!);

      _reverseGeocode(pos.latitude, pos.longitude);
    });
  }

  Future<void> _pushLocation(Position pos) async {
    try {
      await _supabase.from('locations').upsert({
        'user_id':    widget.patientId,
        'latitude':   pos.latitude,
        'longitude':  pos.longitude,
        'speed':      pos.speed,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  Future<void> _sendZoneAlert(String type, SafeZone zone) async {
    if (widget.companionId == null || _myPos == null) return;
    try {
      final dist = Geolocator.distanceBetween(
        _myPos!.latitude, _myPos!.longitude,
        zone.center.latitude, zone.center.longitude,
      );
      await _supabase.from('alerts').insert({
        'patient_id':      widget.patientId,
        'companion_id':    widget.companionId,
        'type':            type,
        'distance_meters': dist,
      });
    } catch (_) {}
  }

  

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty && mounted) {
        final p = places.first;
        setState(() {
          _addressLabel = [p.street, p.locality]
              .where((e) => e != null && e!.isNotEmpty)
              .join(', ');
        });
      }
    } catch (_) {}
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
          _routePoints  = [if (_myPos != null) _myPos!, dest];
          _selectedDest = SavedPlace(
            id: -1, label: q,
            latitude: dest.latitude,
            longitude: dest.longitude,
            icon: '📍',
          );
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

  void _goToSavedPlace(SavedPlace place) {
    setState(() {
      _selectedDest = place;
      _routePoints  = [if (_myPos != null) _myPos!, place.latLng];
    });
    _mapCtrl.move(place.latLng, 15);
  }

  void _clearRoute() => setState(() {
        _selectedDest = null;
        _routePoints  = [];
        _searchCtrl.clear();
      });

  Future<void> _sendSOS() async {
    if (widget.companionId == null) {
      _showSnack('Aucun accompagnateur associé à votre compte');
      return;
    }
    try {
      await _supabase.from('alerts').insert({
        'patient_id':   widget.patientId,
        'companion_id': widget.companionId,
        'type':         'sos',
      });
      setState(() => _sosSent = true);
      HapticFeedback.heavyImpact();
      _showSnack(' Appel de détresse envoyé à l\'accompagnateur', isError: false);
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() => _sosSent = false);
    } catch (_) {
      _showSnack('Échec de l\'envoi, veuillez réessayer', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: isError ? _C.red : _C.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  double _distToDest() {
    if (_myPos == null || _selectedDest == null) return 0;
    return Geolocator.distanceBetween(
      _myPos!.latitude, _myPos!.longitude,
      _selectedDest!.latitude, _selectedDest!.longitude,
    );
  }

  String _fmtDist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoading()
          : Stack(children: [
              _buildMap(),
              _buildTopBar(),
              if (_isOutside) _buildOutsideBanner(),
              _buildFabs(),
              _buildBottomPanel(),
            ]),
    );
  }

  

  Widget _buildLoading() => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: _C.teal),
            const SizedBox(height: 16),
            Text('Localisation en cours...', style: GoogleFonts.poppins(color: _C.gray)),
          ]),
        ),
      );

  

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _myPos ?? const LatLng(35.698, 0.633),
        initialZoom: 16,
        maxZoom: 19,
        minZoom: 5,
      ),
      children: [
        // Couche OpenStreetMap (gratuite)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safetrack.app',
          maxZoom: 19,
        ),

       
        if (_safeZone != null)
          CircleLayer(circles: [
            CircleMarker(
              point: _safeZone!.center,
              radius: _safeZone!.radiusMeters,
              color: (_isOutside ? _C.red : _C.teal).withOpacity(0.08),
              borderColor: (_isOutside ? _C.red : _C.teal).withOpacity(0.5),
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
            ),
          ]),

       
        if (_routePoints.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: _routePoints,
              color: _C.blue,
              strokeWidth: 4,
              borderColor: _C.blue.withOpacity(0.2),
              borderStrokeWidth: 8,
            ),
          ]),

        
        MarkerLayer(
          markers: _savedPlaces.map((p) => Marker(
            point: p.latLng,
            width: 44, height: 44,
            child: GestureDetector(
              onTap: () => _goToSavedPlace(p),
              child: _SavedPlaceMarker(place: p),
            ),
          )).toList(),
        ),

     
        if (_selectedDest != null && _selectedDest!.id == -1)
          MarkerLayer(markers: [
            Marker(
              point: _selectedDest!.latLng,
              width: 40, height: 50,
              child: const Icon(Icons.location_pin, color: _C.red, size: 42),
            ),
          ]),

       
        if (_myPos != null)
          MarkerLayer(markers: [
            Marker(
              point: _myPos!,
              width: 64, height: 64,
              child: _PulsingMarker(
                color: _isOutside ? _C.red : _C.teal,
                controller: _pulseCtrl,
              ),
            ),
          ]),
      ],
    );
  }

  

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bouton Retour
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.tealD, size: 18),
                  ),
                ),

                const SizedBox(width: 8),

                // Champ de recherche
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un lieu...',
                              hintStyle: GoogleFonts.poppins(color: _C.gray, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              prefixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: _C.teal),
                                    )
                                  : const Icon(Icons.search, color: _C.gray, size: 18),
                            ),
                            onSubmitted: (_) => _searchPlace(),
                          ),
                        ),
                        // Bouton de navigation (vert)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: ElevatedButton(
                            onPressed: _searchPlace,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.teal,
                              minimumSize: const Size(40, 37),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 8),
            // Badge de statut sous la barre
            _StatusBadge(isOutside: _isOutside, address: _addressLabel),
          ],
        ),
      ),
    );
  }

 

  Widget _buildOutsideBanner() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: _C.red,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: 16, right: 16, bottom: 10,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vous êtes hors de la zone sécurisée ! Contactez votre accompagnateur',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: _sendSOS,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Text('SOS', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: -1, end: 0, duration: 300.ms),
    );
  }

  

  Widget _buildFabs() {
    return Positioned(
      bottom: 220, right: 14,
      child: Column(
        children: [
          _MapFab(
            icon: Icons.add,
            onTap: () => _mapCtrl.move(_myPos ?? _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
          ),
          const SizedBox(height: 8),
          _MapFab(
            icon: Icons.remove,
            onTap: () => _mapCtrl.move(_myPos ?? _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
          ),
          const SizedBox(height: 8),
          _MapFab(
            icon: Icons.my_location,
            color: _C.teal,
            onTap: () {
              if (_myPos != null) _mapCtrl.move(_myPos!, 16);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée de glissement
              Center(
                child: Container(
                  width: 36, height: 3.5,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Position actuelle
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _isOutside ? _C.red : _C.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _addressLabel,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              
              if (_selectedDest != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.blueL,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: _C.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Itinéraire vers : ${_selectedDest!.label}',
                              style: GoogleFonts.poppins(color: _C.blue, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Distance : ${_fmtDist(_distToDest())}',
                              style: GoogleFonts.poppins(color: _C.blue, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearRoute,
                        child: const Icon(Icons.close, color: _C.blue, size: 18),
                      ),
                    ],
                  ),
                ),
              ],

              
              if (_savedPlaces.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Lieux enregistrés',
                    style: GoogleFonts.poppins(fontSize: 11, color: _C.gray)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedPlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final p = _savedPlaces[i];
                      final isSelected = _selectedDest?.id == p.id;
                      return GestureDetector(
                        onTap: () => _goToSavedPlace(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? _C.tealL : const Color(0xFFF1EFE8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? _C.teal : _C.border,
                              width: isSelected ? 1 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(p.icon, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(p.label,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isSelected ? _C.tealD : const Color(0xFF444441))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Bouton appel de détresse
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sosSent ? null : _sendSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sosSent ? _C.teal : _C.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: Icon(_sosSent ? Icons.check : Icons.sos_rounded, size: 22),
                  label: Text(
                    _sosSent ? 'Appel de détresse envoyé' : 'Appel de détresse à l\'accompagnateur',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
    _posSub?.cancel();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}



class _PulsingMarker extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _PulsingMarker({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final scale = 0.9 + controller.value * 0.2;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedPlaceMarker extends StatelessWidget {
  final SavedPlace place;
  const _SavedPlaceMarker({required this.place});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: place.label,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAEEDA),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBA7517), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
        ),
        child: Center(
          child: Text(place.icon, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOutside;
  final String address;

  const _StatusBadge({required this.isOutside, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkDot(color: isOutside ? _C.red : _C.teal),
          const SizedBox(width: 6),
          Text(
            isOutside ? 'Hors de la zone sécurisée' : 'Dans la zone sécurisée',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOutside ? _C.red : _C.tealD,
            ),
          ),
          if (address.isNotEmpty) ...[
            Container(width: 1, height: 12, color: _C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
            Flexible(
              child: Text(
                address,
                style: GoogleFonts.poppins(fontSize: 11, color: _C.gray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  final Color color;
  const _BlinkDot({required this.color});

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      );
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapFab({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

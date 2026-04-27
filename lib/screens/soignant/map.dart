import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class CaregiverMap extends StatefulWidget {
  final double safeRadius; 
  const CaregiverMap({super.key, required this.safeRadius});

  @override
  State<CaregiverMap> createState() => _CaregiverMapState();
}

class _CaregiverMapState extends State<CaregiverMap> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

 
  LatLng caregiverLoc = const LatLng(35.1850, -0.6350); 
  LatLng patientLoc = const LatLng(35.1891, -0.6309);   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Suivi du Patient"), backgroundColor: const Color(0xFF419AFF)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: caregiverLoc, initialZoom: 15),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              
              PolylineLayer(
                polylines: [
                 Polyline( points: [caregiverLoc, patientLoc],
                  color: Colors.blueAccent,
                  strokeWidth: 5.0,
                  strokeCap: StrokeCap.round, 
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                 
                  Marker(
                    point: caregiverLoc,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
               
                  Marker(
                    point: patientLoc,
                    child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 45),
                  ),
                ],
              ),
            ],
          ),

         
          Positioned(
            top: 15, left: 15, right: 15,
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(hintText: "Rechercher une adresse...", border: InputBorder.none, prefixIcon: Icon(Icons.search)),
        onSubmitted: (val) async {
          try {
            List<Location> locations = await locationFromAddress(val);
            if (locations.isNotEmpty) _mapController.move(LatLng(locations.first.latitude, locations.first.longitude), 15);
          } catch (e) { /* معالجة الخطأ */ }
        },
      ),
    );
  }
}
/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverMapScreen extends StatefulWidget {
  final String patientId;

  const CaregiverMapScreen({super.key, required this.patientId});

  @override
  State<CaregiverMapScreen> createState() => _CaregiverMapScreenState();
}

class _CaregiverMapScreenState extends State<CaregiverMapScreen> {
  final MapController mapController = MapController();
  final Location location = Location();

  LatLng? caregiverLocation;  // 👨‍⚕️ المرافق
  LatLng? patientLocation;    // 🧑‍⚕️ المريض

  bool followMode = false;

  StreamSubscription? caregiverSub;
  StreamSubscription? patientSub;

  @override
  void initState() {
    super.initState();
    initTracking();
  }

  // 🚀 تشغيل التتبع
  Future<void> initTracking() async {
    await trackCaregiver();
    listenPatientLocation();
    listenAlerts(); // 🔥 أهم جزء
  }

  // 👨‍⚕️ تتبع المرافق
  Future<void> trackCaregiver() async {
    await location.requestPermission();

    caregiverSub = location.onLocationChanged.listen((loc) {
      setState(() {
        caregiverLocation = LatLng(loc.latitude!, loc.longitude!);
      });
    });
  }

  // 🧑‍⚕️ تتبع المريض LIVE
  void listenPatientLocation() {
    patientSub = Supabase.instance.client
        .from('patient_location')
        .stream(primaryKey: ['patient_id'])
        .eq('patient_id', widget.patientId)
        .listen((data) {
      if (data.isEmpty) return;

      final d = data.first;

      setState(() {
        patientLocation = LatLng(d['latitude'], d['longitude']);
      });

      // 🔥 إذا وضع follow شغال
      if (followMode && patientLocation != null) {
        mapController.move(patientLocation!, 16);
      }
    });
  }

  // 🚨 استقبال الإنذار (الخروج من المنطقة)
  void listenAlerts() {
    Supabase.instance.client
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('patient_id', widget.patientId)
        .listen((data) {
      if (data.isEmpty) return;

      final alert = data.last;

      if (alert['type'] == 'OUT_OF_ZONE') {
        setState(() {
          followMode = true;
        });

        // 🔥 التركيز مباشرة على المريض
        if (patientLocation != null) {
          mapController.move(patientLocation!, 17);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 المريض خرج من منطقة الأمان!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    caregiverSub?.cancel();
    patientSub?.cancel();
    super.dispose();
  }

  // 📍 رسم الخط بين المرافق والمريض
  List<Polyline> buildRoute() {
    if (caregiverLocation == null || patientLocation == null) {
      return [];
    }

    return [
      Polyline(
        points: [caregiverLocation!, patientLocation!],
        strokeWidth: 4,
        color: Colors.red,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final center = caregiverLocation ?? const LatLng(35.7, -0.63);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => followMode = !followMode);
        },
        child: Icon(followMode ? Icons.lock : Icons.lock_open),
      ),

      body: Stack(
        children: [

          // 🗺️ MAP
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [

              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              // 👨‍⚕️ المرافق
              MarkerLayer(
                markers: [
                  if (caregiverLocation != null)
                    Marker(
                      point: caregiverLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),

              // 🧑‍⚕️ المريض
              MarkerLayer(
                markers: [
                  if (patientLocation != null)
                    Marker(
                      point: patientLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                ],
              ),

              // 🔴 الخط بين المرافق والمريض
              PolylineLayer(
                polylines: buildRoute(),
              ),
            ],
          ),

          // 📍 UI حالة التتبع
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                followMode
                    ? "👁 Tracking ACTIVE - Following Patient"
                    : "✋ Manual Mode",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/


/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class CaregiverMapScreen extends StatefulWidget {
  const CaregiverMapScreen({super.key});

  @override
  State<CaregiverMapScreen> createState() => _CaregiverMapScreenState();
}

class _CaregiverMapScreenState extends State<CaregiverMapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();

  LatLng? caregiverLocation;   // 👨‍⚕️ المرافق
  LatLng? patientLocation;     // 🧑‍⚕️ المريض

  double safeRadius = 200; // 🚨 منطقة الأمان بالمتر

  StreamSubscription<LocationData>? _caregiverSub;
  Timer? _patientSimulationTimer;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  // 🚀 تشغيل التتبع
  Future<void> _initTracking() async {
    await _trackCaregiver();
    _simulatePatientMovement(); // 🔴 محاكاة المريض (بدون Firebase)
  }

  // 👨‍⚕️ تتبع المرافق
  Future<void> _trackCaregiver() async {
    _caregiverSub = _location.onLocationChanged.listen((loc) {
      setState(() {
        caregiverLocation = LatLng(loc.latitude!, loc.longitude!);
      });
    });
  }

  // 🧑‍⚕️ محاكاة حركة المريض (بديل Firebase مؤقت)
  void _simulatePatientMovement() {
    patientLocation = const LatLng(35.7, -0.63);

    _patientSimulationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        setState(() {
          patientLocation = LatLng(
            patientLocation!.latitude + 0.0006,
            patientLocation!.longitude + 0.0006,
          );
        });

        _checkSafetyZone();
      },
    );
  }

  // 🚨 التحقق من خروج المريض من المنطقة الآمنة
  void _checkSafetyZone() {
    if (caregiverLocation == null || patientLocation == null) return;

    final Distance distance = Distance();

    double d = distance.as(
      LengthUnit.Meter,
      caregiverLocation!,
      patientLocation!,
    );

    if (d > safeRadius) {
      _showAlert();
    }
  }

  // 🚨 تنبيه المرافق
  void _showAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ المريض خرج من منطقة الأمان!"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 📍 العودة للموقع
  void _goToCaregiver() {
    if (caregiverLocation != null) {
      _mapController.move(caregiverLocation!, 16);
    }
  }

  @override
  void dispose() {
    _caregiverSub?.cancel();
    _patientSimulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🗺️ الخريطة
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: caregiverLocation ?? const LatLng(35.7, -0.63),
              initialZoom: 14,
            ),
            children: [

              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              // 👨‍⚕️ المرافق
              if (caregiverLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: caregiverLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              // 🧑‍⚕️ المريض
              if (patientLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: patientLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              // 🔵 منطقة الأمان حول المريض
              if (patientLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: patientLocation!,
                      radius: safeRadius,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),

          // 📍 زر الرجوع لموقع المرافق
          Positioned(
            right: 15,
            bottom: 60,
            child: FloatingActionButton(
              onPressed: _goToCaregiver,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}*/

/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class CaregiverMapScreen extends StatefulWidget {
  const CaregiverMapScreen({super.key});

  @override
  State<CaregiverMapScreen> createState() => _CaregiverMapScreenState();
}

class _CaregiverMapScreenState extends State<CaregiverMapScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  final Location location = Location();

  LatLng? currentLocation;
  LatLng? destination;
  List<LatLng> route = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 الحصول على موقع المرافق
  Future<void> _getCurrentLocation() async {
    final loc = await location.getLocation();
    setState(() {
      currentLocation = LatLng(loc.latitude!, loc.longitude!);
    });
  }

  // 🔍 البحث عن مكان
  Future<void> searchPlace(String query) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1",
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'safemind-app',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);

        setState(() {
          destination = LatLng(lat, lon);
        });

        mapController.move(destination!, 15);
        _getRoute();
      }
    }
  }

  // 🟥 رسم الطريق (OSRM)
  Future<void> _getRoute() async {
    if (currentLocation == null || destination == null) return;

    final url = Uri.parse(
      "http://router.project-osrm.org/route/v1/driving/"
      "${currentLocation!.longitude},${currentLocation!.latitude};"
      "${destination!.longitude},${destination!.latitude}"
      "?overview=full&geometries=polyline",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final geometry = data['routes'][0]['geometry'];

      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(geometry);

      setState(() {
        route = result
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();
      });
    }
  }

  // 📍 اختيار مكان من الخريطة
  void _onMapTap(LatLng point) {
    setState(() {
      destination = point;
    });
    _getRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🗺️ الخريطة
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter:
                  currentLocation ?? const LatLng(35.7, -0.63),
              initialZoom: 13,

              minZoom: 3,
              maxZoom: 18,

              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [

              // 🟦 tiles
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              // 📍 موقع المرافق
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 35,
                      ),
                    ),
                  ],
                ),

              // 🔴 الوجهة
              if (destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),

              // 🟥 الخط بين النقطتين
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 5,
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),

          // 🔍 Search bar
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Search place...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      searchPlace(searchController.text);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔍 Zoom buttons
          Positioned(
            right: 10,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  onPressed: () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  onPressed: () {
                    mapController.move(
                      mapController.camera.center,
                      mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/

/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safemind/services/supabase_service.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Location")),
      body: StreamBuilder(
        stream: SupabaseService.getPatientStream("patient_1"),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.last;

          final lat = data['latitude'];
          final lng = data['longitude'];

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

*/








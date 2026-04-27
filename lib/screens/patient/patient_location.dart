import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmartMapScreen extends StatefulWidget {
  const SmartMapScreen({super.key});

  @override
  State<SmartMapScreen> createState() => _SmartMapScreenState();
}

class _SmartMapScreenState extends State<SmartMapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _searchController = TextEditingController();

  LatLng? currentLocation;
  LatLng? destination;
  List<LatLng> route = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

 
  Future<void> _getLocation() async {
    final loc = await _location.getLocation();
    setState(() {
      currentLocation = LatLng(loc.latitude!, loc.longitude!);
    });
  }

 
  Future<void> searchPlace(String place) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1");

    final response = await http.get(url, headers: {
      'User-Agent': 'flutter-app',
    });

    final data = json.decode(response.body);

    if (data.isNotEmpty) {
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);

      setState(() {
        destination = LatLng(lat, lon);
      });

      _getRoute();
      _mapController.move(destination!, 15);
    }
  }

 
  Future<void> _getRoute() async {
    if (currentLocation == null || destination == null) return;

    final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/"
        "${currentLocation!.longitude},${currentLocation!.latitude};"
        "${destination!.longitude},${destination!.latitude}"
        "?overview=full&geometries=geojson");

    final response = await http.get(url);
    final data = json.decode(response.body);

    final coords =
        data['routes'][0]['geometry']['coordinates'] as List;

    setState(() {
      route = coords
          .map((e) => LatLng(e[1], e[0]))
          .toList();
    });
  }

 
  void onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      destination = latlng;
    });
    _getRoute();
  }

 
  void goToMyLocation() {
    if (currentLocation != null) {
      _mapController.move(currentLocation!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [

               
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation!,
                    initialZoom: 15,
                    onTap: onMapTap,
                  ),
                  children: [

                   
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.example.app",
                    ),

                   
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 35),
                        ),
                      ],
                    ),

                   
                    if (destination != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: destination!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),

                  
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

              
                Positioned(
                  top: 50,
                  left: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: "أين تريد الذهاب؟",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            searchPlace(_searchController.text);
                          },
                        )
                      ],
                    ),
                  ),
                ),

               
                Positioned(
                  right: 15,
                  bottom: 120,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: goToMyLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),

               
                Positioned(
                  right: 15,
                  bottom: 60,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () {
                     
                    },
                    child: const Icon(Icons.mic),
                  ),
                ),
              ],
            ),
    );
  }
}




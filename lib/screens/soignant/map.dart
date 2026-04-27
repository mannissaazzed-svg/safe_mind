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
          } catch (e) {  }
        },
      ),
    );
  }
}

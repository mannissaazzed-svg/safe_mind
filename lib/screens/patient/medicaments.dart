import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinesPage extends StatefulWidget {
  final String diseaseType;
  const MedicinesPage({super.key, required this.diseaseType});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  final supabase = Supabase.instance.client;

  
  String _getMedImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return supabase.storage
        .from('medicines_bucket')
        .getPublicUrl(imageUrl);
  }

  
  Future<String?> _getPatientId() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await supabase
        .from('users')
        .select('linked_to, role')
        .eq('id', userId)
        .maybeSingle();

    final role = data?['role'] as String?;
    if (role == 'patient') return userId;
    return data?['linked_to'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setState(() => searchQuery = value.toLowerCase()),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          hintText: "Rechercher médicament",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Image.asset(
                    "assets/pharmacy.png",
                    height: 100,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.local_pharmacy, size: 80),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    widget.diseaseType,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            
            Expanded(
              child: FutureBuilder<String?>(
                future: _getPatientId(),
                builder: (context, patientSnapshot) {
                  if (patientSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patientId = patientSnapshot.data;
                  if (patientId == null) {
                    return const Center(
                      child: Text("Aucun patient lié",
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('patient_medicines')
                        .stream(primaryKey: ['id'])
                        .eq('patient_id', patientId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text("Erreur: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_outlined,
                                  size: 60, color: Colors.white54),
                              SizedBox(height: 10),
                              Text(
                                "Aucun médicament ajouté",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      final filtered = snapshot.data!.where((m) {
                        return m['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery);
                      }).toList();

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final med = filtered[index];

                         
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: supabase
                                .from('medicines')
                                .select('image_url')
                                .eq('name', med['name'] ?? '')
                                .maybeSingle(),
                            builder: (context, imgSnapshot) {
                              
                              final patientImg =
                                  med['image_url'] as String?;
                              final libImg =
                                  imgSnapshot.data?['image_url'] as String?;

                              final imageUrl = _getMedImageUrl(
                                (patientImg != null &&
                                        patientImg.isNotEmpty)
                                    ? patientImg
                                    : libImg,
                              );

                              return medicineCard(
                                imageUrl,
                                med['name'] ?? "Sans nom",
                                med['dose'] ?? "",
                                med['frequency'] ?? 0,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget medicineCard(
      String imageUrl, String name, String dose, int freq) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
           
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.medication,
                            size: 45, color: Colors.blue),
                      ),
                    )
                  : Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.medication,
                          size: 45, color: Colors.blue),
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.scale_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Dose: $dose",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      "$freq fois par jour",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.blueGrey),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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

  
  Future<String> _getMedImage(String? capturedUrl, String medName) async {
    if (capturedUrl != null && capturedUrl.isNotEmpty) {
      return supabase.storage.from('medicines_bucket').getPublicUrl(capturedUrl);
    }

    try {
      final data = await supabase
          .from('medication_library')
          .select('image_url')
          .ilike('med_name', medName.trim())
          .maybeSingle();

      if (data != null && data['image_url'] != null) {
        return data['image_url'] as String;
      }
    } catch (e) {
      print("Erreur Library: $e");
    }
    return ""; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8EA7BF),
      body: SafeArea(
        child: Column(
          children: [
           
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
                        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
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
                    errorBuilder: (c, e, s) => const Icon(Icons.local_pharmacy, size: 80),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    widget.diseaseType,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),

           
            const SizedBox(height: 10),

            
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('medicines')
                    .stream(primaryKey: ['id'])
                    .eq('disease_type', widget.diseaseType),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucun médicament trouvé"));
                  }

                  final filtered = snapshot.data!.where((m) {
                    return m['name'].toString().toLowerCase().contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final med = filtered[index];
                    
                      return FutureBuilder<String>(
                        future: _getMedImage(med['image_url'], med['name'] ?? ""),
                        builder: (context, imageSnapshot) {
                          return medicineCard(
                            imageSnapshot.data ?? "", 
                            med['name'] ?? "Sans nom",
                            med['dose'] ?? "",
                            med['frequency'] ?? 0,
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

  Widget medicineCard(String finalImageUrl, String name, String dose, int freq) {
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
              child: finalImageUrl.isNotEmpty
                  ? Image.network(
                      finalImageUrl,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.medication, size: 50, color: Colors.grey),
                    )
                  : const Icon(Icons.medication, size: 50, color: Colors.grey),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Médicament: $name", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Dose: $dose", style: const TextStyle(fontSize: 14)),
                  Text("Fréquence: $freq fois par jour", style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}




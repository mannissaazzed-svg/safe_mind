import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineForm extends StatefulWidget {
  final String diseaseType; 

  const MedicineForm({super.key, required this.diseaseType});

  @override
  State<MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<MedicineForm> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  int frequence = 1;
  File? _capturedImage;
  File? _tempImage; 
  bool _isUploading = false;
  bool _showPreview = false; 

  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) {
      setState(() {
        _tempImage = File(photo.path);
        _showPreview = true;
      });
    }
  }

  
  Future<void> _handleSave({required bool stayInPage}) async {
    if (nomController.text.isEmpty && _capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un nom ou prendre une photo")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      
      if (_capturedImage != null) {
        final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('medicines_bucket').upload(fileName, _capturedImage!);
        imageUrl = fileName;
      }

      await supabase.from('medicines').insert({
        'name': nomController.text.isEmpty ? "Médicament sans nom" : nomController.text,
        'dose': doseController.text,
        'frequency': frequence,
        'image_url': imageUrl,
        'disease_type': widget.diseaseType,
      });

      if (stayInPage) {
        setState(() {
          nomController.clear();
          doseController.clear();
          _capturedImage = null;
          frequence = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ajouté !")),
        );
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFF),
      body: Stack(
        children: [
        
          Column(
            children: [
             
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xffE1E9F5),
                      image: DecorationImage(
                        image: AssetImage("assets/medicines.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 45, left: 15,
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                 
                  if (_capturedImage != null)
                    Positioned(
                      bottom: 40, left: 20,
                      child: Container(
                        height: 70, width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(image: FileImage(_capturedImage!), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                 
                  Positioned(
                    bottom: 20, right: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _takePhoto,
                      child: const Icon(Icons.camera_alt, color: Color(0xff00A3FF)),
                    ),
                  ),
                ],
              ),

            
              Expanded(
                child: Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Saisie pour ${widget.diseaseType}", 
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 25),
                        _buildField("Nom du médicament", nomController, Icons.edit_note),
                        const SizedBox(height: 20),
                        _buildField("Dose", doseController, Icons.scale),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Nombre de fois / jour", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)),
                            _buildCounter(),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          
          if (_showPreview)
            Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Aperçu de la photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_tempImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // زر الحذف
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], elevation: 0),
                            onPressed: () => setState(() { _showPreview = false; _tempImage = null; }),
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            label: const Text("Effacer", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // زر الحفظ التأكيدي
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00A3FF), elevation: 0),
                            onPressed: () => setState(() { 
                              _capturedImage = _tempImage; 
                              _showPreview = false; 
                            }),
                            icon: const Icon(Icons.check, color: Colors.white, size: 18),
                            label: const Text("Garder", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

 
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Color(0xff00A3FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _isUploading ? null : () => _handleSave(stayInPage: true),
            child: const Text("Ajouter un autre", style: TextStyle(color: Color(0xff00A3FF), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xff00A3FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _isUploading ? null : () => _handleSave(stayInPage: false),
            child: _isUploading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Terminer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  
  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: const Color(0xffF5F8FF), borderRadius: BorderRadius.circular(15)),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue[200]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xffF5F8FF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.blue),
          onPressed: () {
            setState(() {
              if (frequence > 1) frequence--;
            });
          },
        ),

        Text(
          "$frequence",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        IconButton(
          icon: const Icon(Icons.add, color: Colors.blue),
          onPressed: () {
            setState(() {
              if (frequence < 3) frequence++; // ⭐ الحد الأقصى = 3
            });
          },
        ),
      ],
    ),
  );
}
}





















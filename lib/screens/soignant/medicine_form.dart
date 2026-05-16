import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  
  Future<void> _loadSuggestions() async {
    setState(() => _loadingSuggestions = true);
    try {
      final data = await supabase
          .from('medicines')
          .select('name, dose, frequency')
          .eq('disease_type', widget.diseaseType)
          .order('name');
      setState(() => _suggestions = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  
  void _selectSuggestion(Map<String, dynamic> med) {
    setState(() {
      nomController.text = med['name'] ?? '';
      doseController.text = med['dose'] ?? '';
      frequence = med['frequency'] ?? 1;
    });
    Navigator.pop(context); 
  }

  
  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Médicaments ${widget.diseaseType}',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: _loadingSuggestions
                  ? const Center(child: CircularProgressIndicator())
                  : _suggestions.isEmpty
                      ? const Center(child: Text('Aucun médicament trouvé'))
                      : ListView.builder(
                          controller: controller,
                          itemCount: _suggestions.length,
                          itemBuilder: (_, i) {
                            final med = _suggestions[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xffE8F4FD),
                                child: Icon(Icons.medication,
                                    color: Color(0xff00A3FF)),
                              ),
                              title: Text(med['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${med['dose'] ?? ''} · ${med['frequency']}x/jour'),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.grey),
                              onTap: () => _selectSuggestion(med),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  
  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scanner Barcode")),
          body: MobileScanner(
            onDetect: (capture) async {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context);
                  await _searchMedicine(code);
                }
              }
            },
          ),
        ),
      ),
    );
  }

  
  Future<void> _searchMedicine(String barcode) async {
    try {
      final data = await supabase
          .from('medicines')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (data != null) {
        
        setState(() {
          nomController.text = data['name'] ?? '';
          doseController.text = data['dose'] ?? '';
          frequence = data['frequency'] ?? 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(" Médicament trouvé et rempli automatiquement"),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        
        if (mounted) {
          setState(() {
            nomController.clear();
            doseController.clear();
            frequence = 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  " Code barre non trouvé → Choisissez dans la liste ou saisissez manuellement"),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Liste',
                textColor: Colors.white,
                onPressed: _showSuggestions,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  
  Future<void> _handleSave({required bool stayInPage}) async {
    if (nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un médicament")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_capturedImage != null) {
        final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage
            .from('medicines_bucket')
            .upload(fileName, _capturedImage!);
        imageUrl = fileName;
      }

    
final userId = supabase.auth.currentUser?.id;
final userData = await supabase
    .from('users')
    .select('linked_to')
    .eq('id', userId!)
    .maybeSingle();

await supabase.from('patient_medicines').insert({
  'caregiver_id': userId,
  'patient_id':   userData?['linked_to'],
  'name':         nomController.text,
  'dose':         doseController.text,
  'frequency':    frequence,
  'image_url':    imageUrl,
  'disease_type': widget.diseaseType,
});

      if (stayInPage) {
        setState(() {
          nomController.clear();
          doseController.clear();
          _capturedImage = null;
          frequence = 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(" Ajouté avec succès !"),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
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
                          image: DecorationImage(
                              image: FileImage(_capturedImage!),
                              fit: BoxFit.cover),
                        ),
                      ),
                    ),
                 
                  Positioned(
                    bottom: 20, right: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _scanBarcode,
                      child: const Icon(Icons.qr_code_scanner,
                          color: Color(0xff00A3FF)),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 20, right: 70,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _showSuggestions,
                      tooltip: 'Liste des médicaments',
                      child: const Icon(Icons.list_alt,
                          color: Color(0xff00A3FF)),
                    ),
                  ),
                ],
              ),

             
              Expanded(
                child: Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 25, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Saisie pour ${widget.diseaseType}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            
                            TextButton.icon(
                              onPressed: _showSuggestions,
                              icon: const Icon(Icons.medical_services,
                                  size: 16, color: Color(0xff00A3FF)),
                              label: const Text('Liste',
                                  style: TextStyle(
                                      color: Color(0xff00A3FF),
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildField("Nom du médicament",
                            nomController, Icons.edit_note),
                        const SizedBox(height: 20),
                        _buildField("Dose", doseController, Icons.scale),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Nombre de fois / jour",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                              ),
                            ),
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
                    const Text("Aperçu de la photo",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_tempImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50], elevation: 0),
                            onPressed: () => setState(() {
                              _showPreview = false;
                              _tempImage = null;
                            }),
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                            label: const Text("Effacer",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff00A3FF),
                                elevation: 0),
                            onPressed: () => setState(() {
                              _capturedImage = _tempImage;
                              _showPreview = false;
                            }),
                            icon: const Icon(Icons.check,
                                color: Colors.white, size: 18),
                            label: const Text("Garder",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed:
                _isUploading ? null : () => _handleSave(stayInPage: true),
            child: const Text("Ajouter un autre",
                style: TextStyle(
                    color: Color(0xff00A3FF), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xff00A3FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed:
                _isUploading ? null : () => _handleSave(stayInPage: false),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text("Terminer",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black45)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF5F8FF),
            borderRadius: BorderRadius.circular(15),
          ),
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
              if (frequence > 1) setState(() => frequence--);
            },
          ),
          Text("$frequence",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () {
              if (frequence < 4) setState(() => frequence++);
            },
          ),
        ],
      ),
    );
  }
}


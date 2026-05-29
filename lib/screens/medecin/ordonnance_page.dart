import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedItem {
  String name = '';
  String dose = '';
  String duration = '';
  Map<String, String> toMap() => {'name': name, 'dose': dose, 'duration': duration};
}

class OrdonnancePage extends StatefulWidget {
  final Map<String, dynamic>? patient;
  const OrdonnancePage({super.key, this.patient});

  @override
  State<OrdonnancePage> createState() => _OrdonnancePageState();
}

class _OrdonnancePageState extends State<OrdonnancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  String? _doctorName;
  String? _doctorSpec;
  String? _doctorPhone;
  String? _doctorHospital;

  // الـ Getter المضاف لإضافة Dr. تلقائياً
  String get _doctorDisplayName => (_doctorName != null && _doctorName!.isNotEmpty)
      ? (_doctorName!.toLowerCase().startsWith("dr") ? _doctorName! : 'Dr. $_doctorName')
      : 'Dr. Médecin';

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _patientAgeCtrl = TextEditingController();
  final TextEditingController _analysisCtrl = TextEditingController();

  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  List<MedItem> _meds = [MedItem()];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDoctorData();
    if (widget.patient != null) {
      _patientNameCtrl.text = widget.patient!['name'] ?? '';
      _patientAgeCtrl.text = widget.patient!['age']?.toString() ?? '';
    }
  }

  Future<void> _fetchDoctorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('doctors')
            .select('full_name, speciality, phone, hospital')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _doctorName = data['full_name'];
          _doctorSpec = data['speciality'];
          _doctorPhone = data['phone'];
          _doctorHospital = data['hospital'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  Future<pw.Document> _generateBlackPdf(Map<String, dynamic> data, bool isAnalysis, Uint8List? signature) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              color: PdfColors.black,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // تم استخدام _doctorDisplayName هنا
                      pw.Text(_doctorDisplayName.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text((_doctorSpec ?? "SPÉCIALISTE").toUpperCase(), style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                    ],
                  ),
                  pw.Text(isAnalysis ? "ANALYSES" : "ORDONNANCE", style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                ],
              ),
            ),
            
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (!isAnalysis) ...[
                      pw.Center(
                        child: pw.Text("ORDONNANCE", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                      ),
                      pw.SizedBox(height: 25),
                    ],
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Patient: ${_patientNameCtrl.text}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            if (_patientAgeCtrl.text.isNotEmpty)
                              pw.Text("Age: ${_patientAgeCtrl.text} ans", style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.Text("Le: $dateStr", style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 30),
                    
                    if (!isAnalysis)
                      pw.TableHelper.fromTextArray(
                        border: null,
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                        headers: ['Médicament', 'Dosage', 'Durée'],
                        data: (data['medications'] as List).map((m) => [m['name'], m['dose'], m['duration']]).toList(),
                      )
                    else
                      pw.Text(_analysisCtrl.text, style: const pw.TextStyle(fontSize: 13)),

                    pw.Spacer(),
                    
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        children: [
                          if (signature != null) pw.Image(pw.MemoryImage(signature), width: 110),
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 5),
                          pw.Text("Cachet et Signature", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 15),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Text("${_doctorHospital ?? 'Lieu de travail non spécifié'}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text("Contact: ${_doctorPhone ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  Future<void> _handleSaveAndPrint(bool isAnalysis) async {
    if (_patientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez saisir le nom du patient")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sigBytes = await _sigController.toPngBytes();
      final medicationsList = isAnalysis ? null : _meds.where((m) => m.name.isNotEmpty).map((m) => m.toMap()).toList();

      final recordData = {
        'medecin_id': supabase.auth.currentUser!.id,
        'doctor_name': _doctorName,
        'patient_name': _patientNameCtrl.text,
        'type': isAnalysis ? 'ANALYSIS' : 'PRESCRIPTION',
        'content': isAnalysis ? _analysisCtrl.text : null,
        'medications': medicationsList,
        'created_at': DateTime.now().toIso8601String(),
      };

      final inserted = await supabase.from('medical_records').insert(recordData).select().single();
      final pdfDoc = await _generateBlackPdf(inserted, isAnalysis, sigBytes);
      await Printing.layoutPdf(onLayout: (format) => pdfDoc.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Nouvelle Ordonnance"),
        backgroundColor: Colors.black,
        bottom: TabBar(controller: _tabController, indicatorColor: Colors.white, tabs: const [Tab(text: "ORDONNANCE"), Tab(text: "ANALYSES")]),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : TabBarView(controller: _tabController, children: [_buildForm(false), _buildForm(true)]),
    );
  }

  Widget _buildForm(bool isAnalysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تم استخدام _doctorDisplayName هنا
          _buildInfoCard("Médecin", _doctorDisplayName, Icons.person_pin),
          _buildInfoCard("Lieu", _doctorHospital ?? "---", Icons.local_hospital),
          const SizedBox(height: 20),
          
          const Text("Informations Patient", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildInput(_patientNameCtrl, "Nom du Patient"),
          _buildInput(_patientAgeCtrl, "Âge", isNumber: true),
          
          const Divider(height: 40),

          if (!isAnalysis) ...[
            const Text("Médicaments", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._meds.asMap().entries.map((e) => _buildMedCard(e.key)).toList(),
            TextButton.icon(onPressed: () => setState(() => _meds.add(MedItem())), icon: const Icon(Icons.add_circle, color: Colors.black), label: const Text("Ajouter Médicament", style: TextStyle(color: Colors.black))),
          ] else ...[
            const Text("Analyses", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _analysisCtrl, maxLines: 5, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), hintText: "Saisissez les analyses...")),
          ],
          
          _buildSignatureSection(),
          _buildActionButtons(isAnalysis),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) => Card(
    margin: const EdgeInsets.only(bottom: 5),
    child: ListTile(
      leading: Icon(icon, color: Colors.black, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      dense: true,
    ),
  );

  Widget _buildInput(TextEditingController ctrl, String hint, {bool isNumber = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
  );

  Widget _buildMedCard(int index) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: TextField(onChanged: (v) => _meds[index].name = v, decoration: const InputDecoration(hintText: "Nom", border: InputBorder.none))),
          Expanded(child: TextField(onChanged: (v) => _meds[index].dose = v, decoration: const InputDecoration(hintText: "Dosage", border: InputBorder.none))),
          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _meds.removeAt(index))),
        ],
      ),
    ),
  );

  Widget _buildSignatureSection() => Column(children: [const SizedBox(height: 30), const Text("Signature du Médecin", style: TextStyle(color: Colors.grey)), Container(margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)), child: Signature(controller: _sigController, height: 120, backgroundColor: Colors.transparent)), TextButton(onPressed: () => _sigController.clear(), child: const Text("Effacer", style: TextStyle(color: Colors.red)))]);

  Widget _buildActionButtons(bool isAnalysis) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _handleSaveAndPrint(isAnalysis), icon: const Icon(Icons.print, color: Colors.white), label: const Text("SAUVEGARDER & IMPRIMER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}

/*import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedItem {
  String name = '';
  String dose = '';
  String duration = '';
  Map<String, String> toMap() => {'name': name, 'dose': dose, 'duration': duration};
}

class OrdonnancePage extends StatefulWidget {
  final Map<String, dynamic>? patient;
  const OrdonnancePage({super.key, this.patient});

  @override
  State<OrdonnancePage> createState() => _OrdonnancePageState();
}

class _OrdonnancePageState extends State<OrdonnancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  String? _doctorName;
  String? _doctorSpec;
  String? _doctorPhone;
  String? _doctorHospital;

  // الـ Getter المضاف لإضافة Dr. تلقائياً
  String get _doctorDisplayName => (_doctorName != null && _doctorName!.isNotEmpty)
      ? (_doctorName!.toLowerCase().startsWith("dr") ? _doctorName! : 'Dr. $_doctorName')
      : 'Dr. Médecin';

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _patientAgeCtrl = TextEditingController();
  final TextEditingController _analysisCtrl = TextEditingController();

  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  List<MedItem> _meds = [MedItem()];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDoctorData();
    if (widget.patient != null) {
      _patientNameCtrl.text = widget.patient!['name'] ?? '';
      _patientAgeCtrl.text = widget.patient!['age']?.toString() ?? '';
    }
  }

  Future<void> _fetchDoctorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('doctors')
            .select('full_name, speciality, phone, hospital')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _doctorName = data['full_name'];
          _doctorSpec = data['speciality'];
          _doctorPhone = data['phone'];
          _doctorHospital = data['hospital'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  Future<pw.Document> _generateBlackPdf(Map<String, dynamic> data, bool isAnalysis, Uint8List? signature) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              color: PdfColors.black,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // تم استخدام _doctorDisplayName هنا
                      pw.Text(_doctorDisplayName.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text((_doctorSpec ?? "SPÉCIALISTE").toUpperCase(), style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                    ],
                  ),
                  pw.Text(isAnalysis ? "ANALYSES" : "ORDONNANCE", style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                ],
              ),
            ),
            
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (!isAnalysis) ...[
                      pw.Center(
                        child: pw.Text("ORDONNANCE", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                      ),
                      pw.SizedBox(height: 25),
                    ],
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Patient: ${_patientNameCtrl.text}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            if (_patientAgeCtrl.text.isNotEmpty)
                              pw.Text("Age: ${_patientAgeCtrl.text} ans", style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.Text("Le: $dateStr", style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Divider(color: PdfColors.black, thickness: 1.5),
                    pw.SizedBox(height: 30),
                    
                    if (!isAnalysis)
                      pw.TableHelper.fromTextArray(
                        border: null,
                        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                        headers: ['Médicament', 'Dosage', 'Durée'],
                        data: (data['medications'] as List).map((m) => [m['name'], m['dose'], m['duration']]).toList(),
                      )
                    else
                      pw.Text(_analysisCtrl.text, style: const pw.TextStyle(fontSize: 13)),

                    pw.Spacer(),
                    
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        children: [
                          if (signature != null) pw.Image(pw.MemoryImage(signature), width: 110),
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 5),
                          pw.Text("Cachet et Signature", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 15),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Text("${_doctorHospital ?? 'Lieu de travail non spécifié'}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text("Contact: ${_doctorPhone ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  Future<void> _handleSaveAndPrint(bool isAnalysis) async {
    if (_patientNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez saisir le nom du patient")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sigBytes = await _sigController.toPngBytes();
      final medicationsList = isAnalysis ? null : _meds.where((m) => m.name.isNotEmpty).map((m) => m.toMap()).toList();

      final recordData = {
        'medecin_id': supabase.auth.currentUser!.id,
        'doctor_name': _doctorName,
        'patient_name': _patientNameCtrl.text,
        'type': isAnalysis ? 'ANALYSIS' : 'PRESCRIPTION',
        'content': isAnalysis ? _analysisCtrl.text : null,
        'medications': medicationsList,
        'created_at': DateTime.now().toIso8601String(),
      };

      final inserted = await supabase.from('medical_records').insert(recordData).select().single();
      final pdfDoc = await _generateBlackPdf(inserted, isAnalysis, sigBytes);
      await Printing.layoutPdf(onLayout: (format) => pdfDoc.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Nouvelle Ordonnance"),
        backgroundColor: Colors.black,
        bottom: TabBar(controller: _tabController, indicatorColor: Colors.white, tabs: const [Tab(text: "ORDONNANCE"), Tab(text: "ANALYSES")]),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : TabBarView(controller: _tabController, children: [_buildForm(false), _buildForm(true)]),
    );
  }

  Widget _buildForm(bool isAnalysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تم استخدام _doctorDisplayName هنا
          _buildInfoCard("Médecin", _doctorDisplayName, Icons.person_pin),
          _buildInfoCard("Lieu", _doctorHospital ?? "---", Icons.local_hospital),
          const SizedBox(height: 20),
          
          const Text("Informations Patient", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildInput(_patientNameCtrl, "Nom du Patient"),
          _buildInput(_patientAgeCtrl, "Âge", isNumber: true),
          
          const Divider(height: 40),

          if (!isAnalysis) ...[
            const Text("Médicaments", style: TextStyle(fontWeight: FontWeight.bold)),
            ..._meds.asMap().entries.map((e) => _buildMedCard(e.key)).toList(),
            TextButton.icon(onPressed: () => setState(() => _meds.add(MedItem())), icon: const Icon(Icons.add_circle, color: Colors.black), label: const Text("Ajouter Médicament", style: TextStyle(color: Colors.black))),
          ] else ...[
            const Text("Analyses", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _analysisCtrl, maxLines: 5, decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), hintText: "Saisissez les analyses...")),
          ],
          
          _buildSignatureSection(),
          _buildActionButtons(isAnalysis),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) => Card(
    margin: const EdgeInsets.only(bottom: 5),
    child: ListTile(
      leading: Icon(icon, color: Colors.black, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      dense: true,
    ),
  );

  Widget _buildInput(TextEditingController ctrl, String hint, {bool isNumber = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
  );

  Widget _buildMedCard(int index) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: TextField(onChanged: (v) => _meds[index].name = v, decoration: const InputDecoration(hintText: "Nom", border: InputBorder.none))),
          Expanded(child: TextField(onChanged: (v) => _meds[index].dose = v, decoration: const InputDecoration(hintText: "Dosage", border: InputBorder.none))),
          IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => _meds.removeAt(index))),
        ],
      ),
    ),
  );

  Widget _buildSignatureSection() => Column(children: [const SizedBox(height: 30), const Text("Signature du Médecin", style: TextStyle(color: Colors.grey)), Container(margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)), child: Signature(controller: _sigController, height: 120, backgroundColor: Colors.transparent)), TextButton(onPressed: () => _sigController.clear(), child: const Text("Effacer", style: TextStyle(color: Colors.red)))]);

  Widget _buildActionButtons(bool isAnalysis) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => _handleSaveAndPrint(isAnalysis), icon: const Icon(Icons.print, color: Colors.white), label: const Text("SAUVEGARDER & IMPRIMER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}
*/
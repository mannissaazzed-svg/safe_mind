import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/soignant/caregiver.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

class PatientForm extends StatefulWidget {
  final String preselectedDisease;

  const PatientForm({super.key, this.preselectedDisease = 'Parkinson'});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final nom        = TextEditingController();
  final age        = TextEditingController();
  final phone      = TextEditingController();
  final doctorCode = TextEditingController();

  late String maladie;
  String genre = "Homme";

  // Symptômes Parkinson
  bool rigidite     = false;
  bool lenteur      = false;
  bool desequilibre = false;

  // Symptômes Alzheimer
  bool desorientation = false;
  bool reconnaissance = false;
  bool humeur         = false;

  bool _isLoading  = true;
  bool _isSending  = false;
  bool _requestSent = false;

  
  @override
  void initState() {
    super.initState();
    maladie = widget.preselectedDisease;
    _checkIfAlreadyFilled();
  }

  @override
  void dispose() {
    nom.dispose();
    age.dispose();
    phone.dispose();
    doctorCode.dispose(); 
    super.dispose();
  }

  
  Future<void> _checkIfAlreadyFilled() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('users')
          .select('patient_filled, disease')
          .eq('id', userId)
          .maybeSingle();

      final filled  = data?['patient_filled'] as bool? ?? false;
      final disease = data?['disease'] as String? ?? widget.preselectedDisease;

      if (filled && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Caregiver(diseaseType: disease)),
        );
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (['Parkinson', 'Alzheimer', 'Alzheimer & Parkinson']
              .contains(disease)) {
            maladie = disease;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  Map<String, dynamic> _buildSymptoms() {
    final Map<String, dynamic> s = {};
    if (maladie == 'Parkinson' || maladie == 'Alzheimer & Parkinson') {
      s['rigidite']     = rigidite;
      s['lenteur']      = lenteur;
      s['desequilibre'] = desequilibre;
    }
    if (maladie == 'Alzheimer' || maladie == 'Alzheimer & Parkinson') {
      s['desorientation'] = desorientation;
      s['reconnaissance'] = reconnaissance;
      s['humeur']         = humeur;
    }
    return s;
  }

  
  Future<void> _sendToDoctor() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Veuillez vérifier les informations', isError: true);
      return;
    }

    final code = doctorCode.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showSnack('Veuillez entrer le code du médecin', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final caregiverId = _supabase.auth.currentUser!.id;

      
      final caregiverData = await _supabase
          .from('users')
          .select('linked_to')
          .eq('id', caregiverId)
          .maybeSingle();

      final patientId = caregiverData?['linked_to'] as String?;

      
      final doctorData = await _supabase
          .from('users')
          .select('id, full_name')
          .eq('short_code', code)
          .eq('role', 'doctor')
          .maybeSingle();

      if (doctorData == null) {
        _showSnack('Code médecin invalide ! Vérifiez le code.', isError: true);
        setState(() => _isSending = false);
        return;
      }

      final medecinId = doctorData['id'] as String;

      
      final existing = await _supabase
          .from('doctor_requests')
          .select('id')
          .eq('medecin_id', medecinId)
          .eq('caregiver_id', caregiverId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        _showSnack('Demande déjà envoyée à ce médecin !', isError: true);
        setState(() => _isSending = false);
        return;
      }

      
      await _supabase.from('doctor_requests').insert({
        'medecin_id':     medecinId,
        'caregiver_id':   caregiverId,
        'patient_id':     patientId,
        'patient_name':   nom.text.trim(),
        'patient_age':    int.tryParse(age.text.trim()),
        'patient_gender': genre,
        'disease':        maladie,
        'symptoms':       jsonEncode(_buildSymptoms()), 
        'status':         'pending',
      });

     
      await _supabase.from('notifications').insert({
        'user_id': medecinId,
        'title':   'Nouvelle demande patient',
        'body':    'Un aidant souhaite vous confier le patient ${nom.text.trim()}',
        'type':    'doctor_request',
        'is_read': false,
      });

      setState(() {
        _isSending    = false;
        _requestSent  = true;
      });

      _showSnack(
        'Demande envoyée au Dr. ${doctorData['full_name']} avec succès !',
        isError: false,
      );
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
      setState(() => _isSending = false);
    }
  }

 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Veuillez vérifier les informations', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('users').upsert({
        'id':             userId,
        'disease':        maladie,
        'patient_filled': true,
        'role':           'caregiver',
        'patient_age':    int.tryParse(age.text.trim()),
        'patient_phone':  phone.text.trim(),
        'patient_genre':  genre,
        'symptoms':       jsonEncode(_buildSymptoms()), 
      }, onConflict: 'id');

      
      final caregiverData = await _supabase
          .from('users')
          .select('linked_to')
          .eq('id', userId)
          .maybeSingle();

      final patientId = caregiverData?['linked_to'] as String?;
      if (patientId != null) {
        await _supabase
            .from('users')
            .update({'disease': maladie}).eq('id', patientId);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Caregiver(diseaseType: maladie)),
      );
    } catch (e) {
      _showSnack('Erreur: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xffE9F2FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(t.patientProfile),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: AssetImage("assets/patient.png"),
                  ),
                ),
                const SizedBox(height: 20),

                
                buildSection(
                  title: t.identification,
                  child: Column(children: [
                    buildText(t.name),
                    buildField(nom, t.name),
                    buildText(t.age),
                    buildField(age, t.age, isNumber: true, isAge: true),
                    buildText(t.phone),
                    buildField(phone, t.phone, isNumber: true, isPhone: true),
                    const SizedBox(height: 10),
                    buildText(t.gender),
                    Row(children: [
                      Expanded(
                        child: RadioListTile(
                          title: Text(t.male,
                              style: const TextStyle(fontSize: 12)),
                          value: "Homme",
                          groupValue: genre,
                          onChanged: (v) => setState(() => genre = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: Text(t.female,
                              style: const TextStyle(fontSize: 12)),
                          value: "Femme",
                          groupValue: genre,
                          onChanged: (v) => setState(() => genre = v!),
                        ),
                      ),
                    ]),
                  ]),
                ),

               
                buildSection(
                  title: t.diagnosis,
                  child: DropdownButtonFormField<String>(
                    value: maladie,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: "Parkinson", child: Text("Parkinson")),
                      DropdownMenuItem(
                          value: "Alzheimer", child: Text("Alzheimer")),
                      DropdownMenuItem(
                          value: "Alzheimer & Parkinson",
                          child: Text("Alzheimer & Parkinson")),
                    ],
                    onChanged: (v) => setState(() => maladie = v!),
                  ),
                ),

                
                buildSection(
                  title: t.symptoms,
                  child: Column(children: [
                    if (maladie == "Parkinson" ||
                        maladie == "Alzheimer & Parkinson") ...[
                      if (maladie == "Alzheimer & Parkinson")
                        buildText(t.symptomsParkinson),
                      buildCheckItem(t.rigidity, rigidite,
                          (v) => setState(() => rigidite = v!)),
                      buildCheckItem(t.bradykinesia, lenteur,
                          (v) => setState(() => lenteur = v!)),
                      buildCheckItem(t.posturalInstability, desequilibre,
                          (v) => setState(() => desequilibre = v!)),
                      if (maladie == "Alzheimer & Parkinson")
                        const Divider(),
                    ],
                    if (maladie == "Alzheimer" ||
                        maladie == "Alzheimer & Parkinson") ...[
                      if (maladie == "Alzheimer & Parkinson")
                        buildText(t.symptomsAlzheimer),
                      buildCheckItem(t.spatialDisorientation, desorientation,
                          (v) => setState(() => desorientation = v!)),
                      buildCheckItem(t.memoryDisorder, reconnaissance,
                          (v) => setState(() => reconnaissance = v!)),
                      buildCheckItem(t.moodChanges, humeur,
                          (v) => setState(() => humeur = v!)),
                    ],
                  ]),
                ),

               
                buildSection(
                  title: t.sendToDoctor,
                  color: const Color(0xFF10B981),
                  child: Column(children: [
                    if (_requestSent) ...[
                      
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF10B981), size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.requestSentConfirm,
                              style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                    ] else ...[
                     
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.doctorCodeHint,
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      
                      TextFormField(
                        controller: doctorCode,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            fontSize: 16),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.vpn_key_outlined,
                              color: Color(0xFF10B981)),
                          hintText: t.doctorCodeHint2,
                          filled: true,
                          fillColor: const Color(0xFFF5F4FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF10B981), width: 2),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                   
                    Row(children: [
                      // Bouton Médecin
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSending ? null : _sendToDoctor, 
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send,
                                  color: Colors.white, size: 18),
                          label: Text(t.doctorBtn,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                          label: Text(t.continueBtn,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 30),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  Widget buildSection({
    required String title,
    required Widget child,
    Color color = Colors.blue, 
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color, 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Padding(padding: const EdgeInsets.all(15), child: child),
      ]),
    );
  }

  Widget buildField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
    bool isAge = false,
    bool isPhone = false,
  }) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: isPhone ? 10 : null,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return t.required;
          if (isAge) {
            final n = int.tryParse(v);
            if (n == null || n < 30 || n > 100) return t.invalidAge;
          }
          if (isPhone) {
            if (!RegExp(r'^(0)(5|6|7)[0-9]{8}$').hasMatch(v))
              return t.invalidPhone;
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          counterText: "",
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget buildCheckItem(
      String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      value: value,
      title: Text(title, style: const TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  Widget buildText(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}









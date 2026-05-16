import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/soignant/caregiver.dart';

class PatientForm extends StatefulWidget {
  
  final String preselectedDisease;

  const PatientForm({super.key, this.preselectedDisease = 'Parkinson'});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final nom   = TextEditingController();
  final age   = TextEditingController();
  final phone = TextEditingController();

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
   
    maladie = widget.preselectedDisease;
    _checkIfAlreadyFilled();
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
          MaterialPageRoute(
              builder: (_) => Caregiver(diseaseType: disease)),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack("Veuillez vérifier les informations", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

     
      await _supabase.from('users').upsert({
        'id':             userId,
        'disease':        maladie,   // maladie confirmée ici
        'patient_filled': true,
        'role':           'caregiver',
        'patient_age':    int.tryParse(age.text.trim()),
        'patient_phone':  phone.text.trim(),
        'patient_genre':  genre,
        'symptoms': {
          if (maladie == 'Parkinson' ||
              maladie == 'Alzheimer & Parkinson') ...{
            'rigidite':     rigidite,
            'lenteur':      lenteur,
            'desequilibre': desequilibre,
          },
          if (maladie == 'Alzheimer' ||
              maladie == 'Alzheimer & Parkinson') ...{
            'desorientation': desorientation,
            'reconnaissance': reconnaissance,
            'humeur':         humeur,
          }
        }.toString(),
      }, onConflict: 'id');

      
      final caregiverData = await _supabase
          .from('users')
          .select('linked_to')
          .eq('id', userId)
          .maybeSingle();

      final patientId = caregiverData?['linked_to'] as String?;
      if (patientId != null) {
        await _supabase.from('users').update({
          'disease': maladie,
        }).eq('id', patientId);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => Caregiver(diseaseType: maladie)),
      );
    } catch (e) {
      _showSnack("Erreur: ${e.toString()}", isError: true);
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
  void dispose() {
    nom.dispose();
    age.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xffE9F2FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Profil Médical du Patient"),
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
                  "Identification du Patient",
                  Column(children: [
                    buildText("Nom complet"),
                    buildField(nom, "Nom du patient"),
                    buildText("Âge (Entre 30 et 100)"),
                    buildField(age, "Âge",
                        isNumber: true, isAge: true),
                    buildText("Téléphone du tuteur"),
                    buildField(phone, "05/06/07XXXXXXXX",
                        isNumber: true, isPhone: true),
                    const SizedBox(height: 10),
                    buildText("Genre"),
                    Row(children: [
                      Expanded(
                          child: RadioListTile(
                        title: const Text("H",
                            style: TextStyle(fontSize: 12)),
                        value: "Homme",
                        groupValue: genre,
                        onChanged: (v) =>
                            setState(() => genre = v!),
                      )),
                      Expanded(
                          child: RadioListTile(
                        title: const Text("F",
                            style: TextStyle(fontSize: 12)),
                        value: "Femme",
                        groupValue: genre,
                        onChanged: (v) =>
                            setState(() => genre = v!),
                      )),
                    ]),
                  ]),
                ),

             
                buildSection(
                  "Diagnostic Principal",
                  DropdownButtonFormField(
                    value: maladie,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: "Parkinson",
                          child: Text("Parkinson")),
                      DropdownMenuItem(
                          value: "Alzheimer",
                          child: Text("Alzheimer")),
                      DropdownMenuItem(
                          value: "Alzheimer & Parkinson",
                          child: Text("Alzheimer & Parkinson")),
                    ],
                    onChanged: (v) => setState(() => maladie = v!),
                  ),
                ),

                
                buildSection(
                  "Évaluation des Symptômes",
                  Column(children: [
                    if (maladie == "Parkinson" ||
                        maladie == "Alzheimer & Parkinson") ...[
                      if (maladie == "Alzheimer & Parkinson")
                        buildText("Symptômes Parkinson:"),
                      buildCheckItem("Rigidité musculaire", rigidite,
                          (v) => setState(() => rigidite = v!)),
                      buildCheckItem(
                          "Bradykinésie (Lenteur)",
                          lenteur,
                          (v) => setState(() => lenteur = v!)),
                      buildCheckItem(
                          "Instabilité posturale",
                          desequilibre,
                          (v) => setState(() => desequilibre = v!)),
                      if (maladie == "Alzheimer & Parkinson")
                        const Divider(),
                    ],
                    if (maladie == "Alzheimer" ||
                        maladie == "Alzheimer & Parkinson") ...[
                      if (maladie == "Alzheimer & Parkinson")
                        buildText("Symptômes Alzheimer:"),
                      buildCheckItem(
                          "Désorientation spatiale",
                          desorientation,
                          (v) =>
                              setState(() => desorientation = v!)),
                      buildCheckItem(
                          "Troubles de mémoire",
                          reconnaissance,
                          (v) =>
                              setState(() => reconnaissance = v!)),
                      buildCheckItem("Changements d'humeur", humeur,
                          (v) => setState(() => humeur = v!)),
                    ],
                  ]),
                ),

                const SizedBox(height: 20),

                Row(children: [
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Dossier envoyé au médecin !")));
                        }
                      },
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 18),
                      label: const Text("Médecin",
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Bouton continuer
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
                      label: const Text("Continuer",
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ]),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 5)
        ],
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)),
          ),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Padding(
            padding: const EdgeInsets.all(15), child: child),
      ]),
    );
  }

  Widget buildField(TextEditingController ctrl, String hint,
      {bool isNumber = false,
      bool isAge = false,
      bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        maxLength: isPhone ? 10 : null,
        validator: (v) {
          if (v == null || v.trim().isEmpty)
            return "Ce champ est obligatoire";
          if (isAge) {
            final n = int.tryParse(v);
            if (n == null || n < 30 || n > 100)
              return "L'âge doit être entre 30 et 100";
          }
          if (isPhone) {
            if (!RegExp(r'^(0)(5|6|7)[0-9]{8}$').hasMatch(v))
              return "Invalide (Ex: 05XXXXXXXX)";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          counterText: "",
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10),
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

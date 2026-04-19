import 'package:flutter/material.dart';
import 'package:safemind/screens/soignant/caregiver.dart';

class PatientForm extends StatefulWidget {
  const PatientForm({super.key});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  // مفتاح النموذج للتحقق من البيانات
  final _formKey = GlobalKey<FormState>();

  TextEditingController nom = TextEditingController();
  TextEditingController age = TextEditingController();

  String maladie = "Parkinson";
  String genre = "Homme";

  // أعراض باركنسون
  bool rigidite = false;
  bool lenteur = false;
  bool desequilibre = false;

  // أعراض ألزهايمر
  bool desorientation = false;
  bool reconnaissance = false;
  bool humeur = false;

  @override
  Widget build(BuildContext context) {
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
            key: _formKey, // ربط النموذج بالمفتاح
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

                /// قسم تحديد الهوية
                buildSection(
                  "Identification du Patient",
                  Column(
                    children: [
                      buildText("Nom complet"),
                      buildField(nom, "Nom du patient"),
                      buildText("Âge"),
                      buildField(age, "Âge", isNumber: true),
                      const SizedBox(height: 10),
                      buildText("Genre"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text("H", style: TextStyle(fontSize: 12)),
                              value: "Homme",
                              groupValue: genre,
                              onChanged: (value) => setState(() => genre = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text("F", style: TextStyle(fontSize: 12)),
                              value: "Femme",
                              groupValue: genre,
                              onChanged: (value) => setState(() => genre = value!),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                /// قسم التشخيص
                buildSection(
                  "Diagnostic Principal",
                  DropdownButtonFormField(
                    value: maladie,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: "Parkinson", child: Text("Parkinson")),
                      DropdownMenuItem(value: "Alzheimer", child: Text("Alzheimer")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        maladie = value!;
                      });
                    },
                  ),
                ),

                /// قسم الأعراض (يتغير حسب المرض)
                buildSection(
                  "Évaluation des Symptômes",
                  Column(
                    children: maladie == "Parkinson"
                        ? [
                            buildCheckItem("Rigidité musculaire", rigidite, (v) => setState(() => rigidite = v!)),
                            buildCheckItem("Bradykinésie (Lenteur)", lenteur, (v) => setState(() => lenteur = v!)),
                            buildCheckItem("Instabilité posturale", desequilibre, (v) => setState(() => desequilibre = v!)),
                          ]
                        : [
                            buildCheckItem("Désorientation spatiale", desorientation, (v) => setState(() => desorientation = v!)),
                            buildCheckItem("Troubles de mémoire", reconnaissance, (v) => setState(() => reconnaissance = v!)),
                            buildCheckItem("Changements d'humeur", humeur, (v) => setState(() => humeur = v!)),
                          ],
                  ),
                ),

                const SizedBox(height: 20),

                /// الأزرار مع منطق التحقق
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Dossier envoyé au médecin !")),
                            );
                          } else {
                            showWarningSnackBar("Veuillez remplir les informations manquantes");
                          }
                        },
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        label: const Text("Médecin", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Caregiver(diseaseType: maladie),
                              ),
                            );
                          } else {
                            showWarningSnackBar("Données incomplètes !");
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        label: const Text("Continuer", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لإظهار رسالة تحذير حمراء
  void showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget buildSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(padding: const EdgeInsets.all(15), child: child)
        ],
      ),
    );
  }

  Widget buildField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // إضافة التحقق (Validator)
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Ce champ est obligatoire"; // الحقل مطلوب
          }
          if (isNumber && int.tryParse(value) == null) {
            return "Entrez un nombre valide"; // يجب إدخال رقم
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget buildCheckItem(String title, bool value, Function(bool?) onChanged) {
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
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}







/*import 'package:flutter/material.dart';
import 'package:safemind/screens/soignant/caregiver.dart';
import 'medicine_form.dart';

class PatientForm extends StatefulWidget {
  const PatientForm({super.key});

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nom = TextEditingController();
  TextEditingController age = TextEditingController();

  String maladie = "Parkinson"; 
  String genre = "Homme";

  
  bool rigidite = false;
  bool lenteur = false;
  bool desequilibre = false;

  
  bool desorientation = false;
  bool reconnaissance = false;
  bool humeur = false;

  @override
  Widget build(BuildContext context) {
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
                  Column(
                    children: [
                      buildText("Nom complet"),
                      buildField(nom, "Nom du patient"),
                      buildText("Âge"),
                      buildField(age, "Âge", isNumber: true),
                      const SizedBox(height: 10),
                      buildText("Genre"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text("H", style: TextStyle(fontSize: 12)),
                              value: "Homme",
                              groupValue: genre,
                              onChanged: (value) => setState(() => genre = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text("F", style: TextStyle(fontSize: 12)),
                              value: "Femme",
                              groupValue: genre,
                              onChanged: (value) => setState(() => genre = value!),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                
                buildSection(
                  "Diagnostic Principal",
                  DropdownButtonFormField(
                    value: maladie,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: "Parkinson", child: Text("Parkinson")),
                      DropdownMenuItem(value: "Alzheimer", child: Text("Alzheimer")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        maladie = value!;
                      });
                    },
                  ),
                ),

               
                buildSection(
                  "Évaluation des Symptômes",
                  Column(
                    children: maladie == "Parkinson"
                        ? [
                            buildCheckItem("Rigidité musculaire", rigidite, (v) => setState(() => rigidite = v!)),
                            buildCheckItem("Bradykinésie (Lenteur)", lenteur, (v) => setState(() => lenteur = v!)),
                            buildCheckItem("Instabilité posturale", desequilibre, (v) => setState(() => desequilibre = v!)),
                          ]
                        : [
                            buildCheckItem("Désorientation spatiale", desorientation, (v) => setState(() => desorientation = v!)),
                            buildCheckItem("Troubles de mémoire", reconnaissance, (v) => setState(() => reconnaissance = v!)),
                            buildCheckItem("Changements d'humeur", humeur, (v) => setState(() => humeur = v!)),
                          ],
                  ),
                ),

                const SizedBox(height: 20),

                
                Row(
                  children: [
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Dossier envoyé au médecin !")),
                          );
                        },
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        label: const Text("Médecin", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                             
                              builder: (context) => Caregiver(diseaseType: maladie),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        label: const Text("Continuer", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
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
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(padding: const EdgeInsets.all(15), child: child)
        ],
      ),
    );
  }

  Widget buildField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget buildCheckItem(String title, bool value, Function(bool?) onChanged) {
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
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
*/










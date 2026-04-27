import 'package:flutter/material.dart';
import 'package:safemind/screens/soignant/map.dart';
import 'package:safemind/screens/medecin.dart';
import 'package:safemind/screens/soignant/call.dart';
import 'package:safemind/screens/soignant/map.dart';
import 'package:safemind/screens/soignant/medicine_form.dart';
import 'package:safemind/screens/soignant/tasks.dart';

class Caregiver extends StatefulWidget {
  final String diseaseType;

  const Caregiver({super.key, required this.diseaseType});

  @override
  State<Caregiver> createState() => _CaregiverState();
}

class _CaregiverState extends State<Caregiver> {
  int selectedNav = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          
          _buildHeader(),

          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: GridView.count(
                 
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildGridItem(
                      'assets/check_list.png',
                      "Suivi quotidien",
                      const Color(0xFFF9F5C0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverAddTasks()));
                      },
                    ),
                    _buildGridItem(
                      'assets/doctor.png',
                      "Médecin",
                      const Color(0xFFF9C5C0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const Medecin()));
                      },
                    ),
                    _buildGridItem(
                      'assets/m.png',
                      "Médicaments",
                      const Color(0xFF94B3FF),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineForm(diseaseType: widget.diseaseType)));
                      },
                    ),
                    _buildGridItem(
                      'assets/maps.png',
                      "Localisation",
                      const Color(0xFFC5FFD5),
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) =>  CaregiverMap()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF419AFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Caregiver",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Patient: ${widget.diseaseType}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                   
                  },
                )
              ],
            ),
          ),

          const SizedBox(height: 15),

          /// Banner
          SizedBox(
            height: 180, 
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildBanner('assets/bleu.png'),
                _buildBanner('assets/green.png'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => _buildDot(index == _currentPage)),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover, 
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white24,
              child: const Icon(Icons.broken_image, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 22 : 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive ? Colors.white : Colors.white38,
      ),
    );
  }

  Widget _buildGridItem(String image, String title, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Flexible(child: Image.asset(image, height: 65)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          glowNavItem(Icons.home, 0),
          glowNavItem(Icons.phone, 1),
          glowNavItem(Icons.check_box, 2),
        ],
      ),
    );
  }

  Widget glowNavItem(IconData icon, int index) {
    bool isSelected = selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedNav = index);
        
      },
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.blue[200] : Colors.white54,
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










/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/soignant/map.dart'; 
import 'package:safemind/screens/medecin.dart';
import 'package:safemind/screens/soignant/call.dart';
import 'package:safemind/screens/soignant/medicine_form.dart';
import 'package:safemind/screens/soignant/tasks.dart';

class Caregiver extends StatefulWidget {
  final String diseaseType;

  const Caregiver({super.key, required this.diseaseType});

  @override
  State<Caregiver> createState() => _CaregiverState();
}

class _CaregiverState extends State<Caregiver> {
  int selectedNav = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildGridItem(
                      'assets/check_list.png',
                      "Suivi quotidien",
                      const Color(0xFFF9F5C0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CaregiverAddTasks()));
                      },
                    ),
                    _buildGridItem(
                      'assets/doctor.png',
                      "Médecin",
                      const Color(0xFFF9C5C0),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => Medecin()));
                      },
                    ),
                    _buildGridItem(
                      'assets/m.png',
                      "Médicaments",
                      const Color(0xFF94B3FF),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineForm(diseaseType: widget.diseaseType)));
                      },
                    ),
                   
                    _buildGridItem(
                      'assets/maps.png',
                      "Localisation",
                      const Color(0xFFC5FFD5),
                      onTap: () {
                      
                        double radius;
                        String disease = widget.diseaseType.toLowerCase();
                        if (disease.contains("alzheimer")) {
                          radius = 200.0;
                        } else if (disease.contains("parkinson")) {
                          radius = 500.0;
                        } else {
                          radius = 350.0;
                        }

                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaregiverMap(safeRadius: radius),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  
  Widget _buildGridItem(String image, String title, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Image.asset(image, height: 60)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildHeader() { return Container(); }
  Widget _buildBottomNav() {  return Container(); }
}

*/
import 'package:flutter/material.dart';

class MedicineForm extends StatefulWidget {
  const MedicineForm({super.key});

  @override
  State<MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends State<MedicineForm> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  int frequence = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
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
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  onPressed: () {}, 
                  child: const Icon(Icons.camera_alt, color: Color(0xff00A3FF)),
                ),
              ),
            ],
          ),

        
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -30, 0), 
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -10),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Médicaments", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 25),

                    
                    const Text("Nom de médicament", style: _labelStyle),
                    const SizedBox(height: 10),
                    _buildModernField(nomController, Icons.edit_note),

                    const SizedBox(height: 20),

                   
                    const Text("Dose", style: _labelStyle),
                    const SizedBox(height: 10),
                    _buildModernField(doseController, Icons.scale),

                    const SizedBox(height: 25),

                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Nombre de fois par jour", style: _labelStyle),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xffF5F8FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              _iconBtn(Icons.remove, () {
                                if (frequence > 1) setState(() => frequence--);
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Text("$frequence", 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              _iconBtn(Icons.add, () {
                                setState(() => frequence++);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff00A3FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Sauvegarder", 
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45);

  Widget _buildModernField(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF5F8FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.blue, size: 20),
    );
  }
}
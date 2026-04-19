import 'package:flutter/material.dart';
import 'package:safemind/screens/map.dart';
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
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const Tasks()));
                      },
                    ),
                    _buildGridItem(
                      'assets/doctor.png',
                      "Médecin",
                      const Color(0xFFF9C5C0),
                      onTap: () {
                        //Navigator.push(context, MaterialPageRoute(builder: (_) => const Medecin()));
                      },
                    ),
                    _buildGridItem(
                      'assets/m.png',
                      "Médicaments",
                      const Color(0xFF94B3FF),
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineForm(diseaseType: widget.diseaseType)));
                      },
                    ),
                    _buildGridItem(
                      'assets/maps.png',
                      "Localisation",
                      const Color(0xFFC5FFD5),
                      onTap: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
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







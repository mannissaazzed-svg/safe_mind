import 'package:flutter/material.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/notifications.dart';
import 'package:safemind/screens/patient/exercices/activites.dart';
import 'package:safemind/screens/patient/patient_location.dart';
import 'package:safemind/screens/soignant/call.dart';
import 'package:safemind/screens/soignant/map.dart';
import 'package:safemind/screens/patient/medicaments.dart'; 
import 'package:safemind/screens/patient/nutrition.dart';
import 'package:safemind/screens/patient/patient.dart';
import 'package:safemind/screens/profile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedNav = 0;
  int selectedCategory = 0; 

  final authService = AuthService();

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: const Color.fromARGB(255, 173, 214, 239),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopHeader(context),
                  _buildSectionTitle("Catégories"),
                  const SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _categoryItem("Alzheimer", "assets/alzheimer.png", 0),
                      const SizedBox(width: 30),
                      _categoryItem("Parkinson", "assets/parkinson.png", 1),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle("Services"),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: _glassDecoration(),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.85,
                        children: [
                          GestureDetector(
                            onTap: () {
                              String diseaseName = (selectedCategory == 0) ? "Alzheimer" : "Parkinson";
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicinesPage(diseaseType: diseaseName),
                                ),
                              );
                            },
                            child: serviceItem("assets/med.png", "Médicaments"),
                          ),

                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HealthAnalysis())),
                            child: serviceItem("assets/nutrition.png", "Nutrition"),
                          ),

                          serviceItem("assets/rendezvous.png", "Rendez-vous"),

                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivitiesPage())),
                            child: serviceItem("assets/ex.png", "Exercices"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildEmergencyButton(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 22, color: Colors.brown[700], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _categoryItem(String title, String image, int index) {
    bool isSelected = selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = index),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35, 
            backgroundImage: AssetImage(image),
            child: isSelected ? Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 4))) : null,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(title, style: TextStyle(fontSize: 18, color: isSelected ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget serviceItem(String image, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 80),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0.15)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(left: 20, right: 12), 
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/tech.png", 
                  height: 220, 
                  width: double.infinity, 
                  fit: BoxFit.fill, 
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 5,
            left: 15, 
            child: IconButton(
              
              icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 35), 
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Container(
      height: 76, width: 194,
      decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 37, 21), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Image.asset("assets/alert.png", height: 92)),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 39, 40, 40), borderRadius: BorderRadius.circular(40)),
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
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => CallPage()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => PatientPage()));
      },
      child: Icon(icon, size: 28, color: isSelected ? Colors.blue[200] : Colors.grey),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF81C784), 
              Color(0xFFA5D6A7), 
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            
            _drawerItem(Icons.map_outlined, "Carte", () {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartMapScreen()));
            }),

            _drawerItem(Icons.notifications_none_rounded, "Notifications", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
            }),

            const Spacer(),

            _drawerItem(Icons.logout_rounded, "Déconnexion", () {
              logout();
            }, isLogout: true),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isLogout ? Colors.red[900] : Colors.white,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red[900] : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      onTap: onTap,
    );
  }
}


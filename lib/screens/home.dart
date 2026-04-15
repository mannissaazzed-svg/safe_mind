import 'package:flutter/material.dart';
import 'package:safemind/screens/activites.dart';
import 'package:safemind/screens/map.dart';
import 'package:safemind/screens/medicaments.dart';
import 'package:safemind/screens/notifications.dart';
import 'package:safemind/screens/nutrition.dart';
import 'package:safemind/screens/profile.dart';
import 'package:safemind/screens/tasks.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedNav = 0;
  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      drawer: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        child: Drawer(
          elevation: 0,
          width: MediaQuery.of(context).size.width * 0.75,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Cerebro.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.3), 
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/alzheimer.png"),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "SafeMind",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  _drawerItem(Icons.person, "Profile", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
                  _drawerItem(Icons.settings, "Paramètres", () {}),
                  _drawerItem(Icons.map, "Carte", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()))),
                  _drawerItem(Icons.notifications, "Notifications", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
                  const Spacer(),
                  _drawerItem(Icons.logout, "Déconnexion", () {}, isLogout: true),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),

      backgroundColor: const Color.fromARGB(255, 173, 214, 239),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Stack(
                      children: [
                     
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(left: 60, right: 12), 
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                "assets/tech.png",
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                       
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Categories Title
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Catégories",
                        style: TextStyle(fontSize: 22, color: Colors.brown[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Categories Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _categoryItem("Alzheimer", "assets/alzheimer.png", 0),
                      const SizedBox(width: 30),
                      _categoryItem("Parkinson", "assets/parkinson.png", 1),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Services Title
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Services",
                        style: TextStyle(fontSize: 22, color: Colors.brown[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                 
                  Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),

                    
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),

                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.85, 
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicinesPage())),
                            child: serviceItem("assets/med.png", "Médicaments"),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionPage())),
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

                  // Emergency Button
                  const SizedBox(height: 10),
                  Container(
                    height: 76,
                    width: 194,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 37, 21),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.asset("assets/alert.png", height: 92),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        ),
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 39, 40, 40),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            glowNavItem(Icons.home, 0),
            glowNavItem(Icons.person, 1),
            glowNavItem(Icons.check_box, 2),
            glowNavItem(Icons.map, 3),
            glowNavItem(Icons.notifications, 4),
          ],
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
          CircleAvatar(radius: 35, backgroundImage: AssetImage(image)),
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
          Image.asset(image, height: 100),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.white),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }

  Widget glowNavItem(IconData icon, int index) {
    bool isSelected = selectedNav == index;
    return GestureDetector(
      onTap: () {
        setState(() => selectedNav = index);
        if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) =>  TaskScreen()));
        if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10)] : [],
        ),
        child: Icon(icon, size: 28, color: isSelected ? Colors.blue[200] : Colors.grey),
      ),
    );
  }
  }
  

import 'package:flutter/material.dart';
import 'package:safemind/screens/contact_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/notifications.dart';
import 'package:safemind/screens/patient/exercices/activites.dart';
import 'package:safemind/screens/patient/medicaments.dart';
import 'package:safemind/screens/patient/nutrition.dart';
import 'package:safemind/screens/patient/patient.dart';
import 'package:safemind/screens/patient/patient_profile.dart';
import 'package:safemind/screens/patient/patient_location.dart';
import 'package:safemind/screens/login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedNav      = 0;
  int selectedCategory = 0;
  bool isBothDiseases  = false;

  final authService = AuthService();
  final _supabase   = Supabase.instance.client;

  String? userName;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  
  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      
      final data = await _supabase
          .from('users')
          .select('full_name, avatar_url, disease')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return;

      String disease = data['disease'] as String? ?? '';

     
      if (disease.isEmpty) {
        final caregiverData = await _supabase
            .from('users')
            .select('disease')
            .eq('linked_to', user.id)
            .eq('role', 'caregiver')
            .maybeSingle();

        disease = caregiverData?['disease'] as String? ?? '';

       
        if (disease.isNotEmpty) {
          await _supabase.from('users').update({
            'disease': disease,
          }).eq('id', user.id);
        }
      }

      if (mounted) {
        setState(() {
          userName        = data['full_name'] as String?;
          profileImageUrl = data['avatar_url'] as String?;

          if (disease == 'Alzheimer & Parkinson') {
            isBothDiseases  = true;
            selectedCategory = 0;
          } else if (disease == 'Parkinson') {
            isBothDiseases  = false;
            selectedCategory = 1;
          } else {
            // Alzheimer ou vide → catégorie 0
            isBothDiseases  = false;
            selectedCategory = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content:
            const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text("Confirmer",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    await authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) async {
    if (index == 0) return;
    setState(() => selectedNav = index);
    if (index == 1) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
    } else if (index == 2) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PatientPage()));
    }
    if (mounted) {
      setState(() => selectedNav = 0);
      _fetchUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: const Color.fromARGB(255, 173, 214, 239),
      body: SafeArea(
        child: Builder(
          builder: (context) => SingleChildScrollView(
            child: Column(
              children: [
                _buildTopHeader(context),
                _buildSectionTitle("Catégories"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _categoryItem(
                      "Alzheimer",
                      "assets/alzheimer.png",
                      selectedCategory == 0 || isBothDiseases,
                    ),
                    const SizedBox(width: 30),
                    _categoryItem(
                      "Parkinson",
                      "assets/parkinson.png",
                      selectedCategory == 1 || isBothDiseases,
                    ),
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
                      physics:
                          const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.85,
                      children: [
                        _serviceWrapper("assets/med.png", "Médicaments",
                            () {
                          final d = isBothDiseases
                              ? "Alzheimer & Parkinson"
                              : (selectedCategory == 0
                                  ? "Alzheimer"
                                  : "Parkinson");
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MedicinesPage(diseaseType: d)));
                        }),
                        _serviceWrapper(
                            "assets/nutrition.png", "Nutrition", () {
                          final d = isBothDiseases
                              ? "Alzheimer & Parkinson"
                              : (selectedCategory == 0
                                  ? "Alzheimer"
                                  : "Parkinson");
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      HealthAnalysis(diseaseType: d)));
                        }),
                        _serviceWrapper(
                            "assets/rendezvous.png", "Rendez-vous",
                            () {}),
                        _serviceWrapper("assets/ex.png", "Exercices",
                            () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ActivitiesPage()));
                        }),
                      ],
                    ),
                  ),
                ),
                _buildEmergencyButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _categoryItem(
      String title, String image, bool isSelected) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(image),
            ),
            if (isSelected)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF419AFF), width: 3.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF419AFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Color(0xFFA5D6A7)],
          ),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration:
                  const BoxDecoration(color: Colors.transparent),
              currentAccountPicture: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const PatientProfileScreen()));
                  _fetchUserData();
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (profileImageUrl != null &&
                          profileImageUrl!.isNotEmpty)
                      ? NetworkImage(profileImageUrl!)
                      : const AssetImage("assets/default_user.png")
                          as ImageProvider,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              accountName: Text(userName ?? "Utilisateur",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(
                  _supabase.auth.currentUser?.email ?? ""),
            ),
            _drawerItem(Icons.person_outline, "Mon Profil", () async {
              Navigator.pop(context);
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PatientProfileScreen()));
              _fetchUserData();
            }),
            _drawerItem(Icons.map_outlined, "Carte", () {
              Navigator.pop(context);
              _openPatientMap();
            }),
            _drawerItem(Icons.chat_bubble_outline, "Messages", () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContactsPage()));
            }),
            _drawerItem(Icons.notifications_none_rounded,
                "Notifications", () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsPage()));
            }),
            const Spacer(),
            _drawerItem(
                Icons.logout_rounded, "Déconnexion", _showLogoutDialog,
                isLogout: true),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 39, 40, 40),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _glowNavItem(Icons.home, 0),
          _glowNavItem(Icons.chat_bubble_outline, 1),
          _glowNavItem(Icons.check_box_outlined, 2),
        ],
      ),
    );
  }

  Widget _glowNavItem(IconData icon, int index) {
    bool isSelected = (selectedNav == index);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(icon,
          size: 28,
          color: isSelected ? Colors.blue[200] : Colors.grey),
    );
  }

  Widget _serviceWrapper(
      String image, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: TextStyle(
                fontSize: 22,
                color: Colors.brown[700],
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.15)
        ]),
        border:
            Border.all(color: Colors.white.withOpacity(0.5)),
      );

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin:
                  const EdgeInsets.only(left: 20, right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset("assets/tech.png",
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.fill),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.sort_rounded,
                  color: Colors.white, size: 35),
              onPressed: () =>
                  Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Container(
      height: 76,
      width: 194,
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 37, 21),
          borderRadius: BorderRadius.circular(20)),
      child: Center(
          child: Image.asset("assets/alert.png", height: 92)),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isLogout ? Colors.red[900] : Colors.white,
          size: 28),
      title: Text(title,
          style: TextStyle(
              color: isLogout ? Colors.red[900] : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17)),
      onTap: onTap,
    );
  }

  Future<void> _openPatientMap() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final data = await _supabase
        .from('users')
        .select('full_name, linked_to')
        .eq('id', userId)
        .maybeSingle();
    if (!mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PatientMapScreen(
                  patientId: userId,
                  companionId: data?['linked_to'] as String?,
                  patientName: data?['full_name'] ?? 'Patient',
                )));
  }
}


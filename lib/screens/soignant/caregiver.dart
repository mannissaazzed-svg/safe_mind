import 'package:flutter/material.dart';
import 'package:safemind/screens/contact_page.dart';
import 'package:safemind/screens/notifications.dart';
import 'package:safemind/screens/patient/call.dart';
import 'package:safemind/screens/rendez_vous.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/soignant/map.dart';
import 'package:safemind/screens/soignant/medicine_form.dart';
import 'package:safemind/screens/soignant/tasks.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/soignant/caregiver_profile.dart';
import 'package:safemind/screens/rendez_vous.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

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

  Map<String, dynamic>? caregiverData;
  Map<String, dynamic>? patientData;
  bool _isLoading = true;

  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final caregiver = await supabase
        .from('users')
        .select('full_name, avatar_url, linked_to')
        .eq('id', userId)
        .maybeSingle();

    final patientId = caregiver?['linked_to'];
    Map<String, dynamic>? patient;

    if (patientId != null) {
      patient = await supabase
          .from('users')
          .select('full_name, disease')
          .eq('id', patientId)
          .maybeSingle();
    }

    setState(() {
      caregiverData = caregiver;
      patientData = patient;
      _isLoading = false;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  
  Future<void> _logout() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.logout),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.confirm, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  Future<void> _openCompanionMap() async {
    final t = AppLocalizations.of(context)!;
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      _showSnack(t.notConnected);
      return;
    }

    try {
      final data = await supabase
          .from('users')
          .select('linked_to')
          .eq('id', userId)
          .maybeSingle();

      final patientId = data?['linked_to'] as String?;
      if (patientId == null) {
        _showSnack(t.noPatientLinked);
        return;
      }

      final pData = await supabase
          .from('users')
          .select('full_name, disease')
          .eq('id', patientId)
          .maybeSingle();

      if (pData == null) {
        _showSnack(t.patientNotFound);
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanionMapScreen(
            companionId: userId,
            patientId: patientId,
            patientName: pData['full_name'] ?? 'patient',
            patientDisease: pData['disease'] ?? '',
          ),
        ),
      );
    } catch (e) {
      _showSnack(t.connectionError);
    }
  }

  
  void _onNavTap(int index) async {
    if (index == 0) {
      setState(() => selectedNav = 0);
      return;
    }

    setState(() => selectedNav = index);

    switch (index) {
      case 1:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ContactsPage()));
        break;
      case 2:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;
    }

    
    if (mounted) {
      setState(() => selectedNav = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _buildHeader(t),
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
                      t.dailyFollowUp,
                      const Color(0xFFF9F5C0),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CaregiverAddTasks())),
                    ),
                    _buildGridItem(
                      'assets/doctor.png',
                      t.doctor,
                      const Color(0xFFF9C5C0),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RendezVous())),
                    ),
                    _buildGridItem(
                      'assets/m.png',
                      t.medications,
                      const Color(0xFF94B3FF),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => MedicineForm(diseaseType: widget.diseaseType))),
                    ),
                    _buildGridItem(
                      'assets/maps.png',
                      t.location,
                      const Color(0xFFC5FFD5),
                      onTap: _openCompanionMap,
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

  Widget _buildHeader(AppLocalizations t) {
    final avatarUrl = caregiverData?['avatar_url'] as String?;
    final name = caregiverData?['full_name'] as String? ?? '';
    final patientName = patientData?['full_name'] as String? ?? '';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CaregiverProfileScreen()),
                      );
                      _loadUserData(); 
                    },
                    child: Row(
                      children: [
                        _isLoading
                            ? const CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white24,
                                child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              )
                            : CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white24,
                                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isNotEmpty ? name : t.accompanying,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Accompagnateur de',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                patientName.isNotEmpty ? patientName : t.noPatient,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

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
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white24,
            child: const Icon(Icons.broken_image, color: Colors.white),
          ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
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
          glowNavItem(Icons.chat_bubble_outline, 1),
          glowNavItem(Icons.notifications, 2),
        ],
      ),
    );
  }

  Widget glowNavItem(IconData icon, int index) {
    bool isSelected = selectedNav == index;
    return GestureDetector(
      onTap: () => _onNavTap(index), 
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.blue[200] : Colors.white54,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:safemind/screens/medecin/ordonnance_page.dart';
import 'package:safemind/screens/my_code.dart';
import 'package:safemind/screens/notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:safemind/screens/contact_page.dart';
import 'package:safemind/screens/my_code.dart';
import 'package:safemind/screens/medecin/patients_list_page.dart';
import 'package:safemind/screens/medecin/appointments_calendar_page.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/medecin/ordonnance_page.dart';
// ═══════════════════════════════════════════════════════
// Dashboard Médecin — SafeMind (Version Complète)
// ✅ Nom réel du médecin
// ✅ Stats : Alzheimer, Parkinson, Femmes, Hommes
// ✅ RDV du jour affichés
// ✅ Patients récents avec recherche
// ✅ Accès Ordonnances & Fichiers
// ═══════════════════════════════════════════════════════

class MedecinDashboardPage extends StatefulWidget {
  const MedecinDashboardPage({super.key});
  @override
  State<MedecinDashboardPage> createState() => _MedecinDashboardPageState();
}

class _MedecinDashboardPageState extends State<MedecinDashboardPage> {
  final _supabase   = Supabase.instance.client;
  final authService = AuthService();

  int    _selectedNav = 0;
  String _medecinName = '';        // ✅ nom réel
  String _medecinSpeciality = '';  // ✅ spécialité réelle
  String? _avatarUrl;

  // ── Stats ──────────────────────────────────────────
  int _totalPatients = 0;
  int _alzheimer     = 0;
  int _parkinson     = 0;
  int _women         = 0;
  int _men           = 0;
  int _upcomingAppts = 0;

  List<Map<String, dynamic>> _recentPatients    = [];
  List<Map<String, dynamic>> _todayAppts        = [];
  List<Map<String, dynamic>> _upcomingApptsList = [];

  bool _isLoading = true;

  static const Color _primary   = Color(0xFF6C63FF);
  static const Color _bg        = Color(0xFFF5F4FA);
  static const Color _cardColor = Colors.white;

  @override
  void initState() { super.initState(); _loadData(); }

  // ══════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMedecinInfo(),
      _loadStats(),
      _loadRecentPatients(),
      _loadTodayAppointments(),
      _loadUpcomingAppointments(),
    ]);
    setState(() => _isLoading = false);
  }

  // ✅ Nom réel depuis table medecins
  Future<void> _loadMedecinInfo() async {
    try {
      final uid  = _supabase.auth.currentUser!.id;
      // Chercher d'abord dans medecins
      final med  = await _supabase.from('medecins')
          .select('full_name, avatar_url, speciality')
          .eq('id', uid).maybeSingle();
      if (med != null) {
        setState(() {
          _medecinName       = med['full_name'] ?? '';
          _medecinSpeciality = med['speciality'] ?? '';
          _avatarUrl         = med['avatar_url'];
        });
        return;
      }
      // Fallback: table users
      final usr = await _supabase.from('users')
          .select('name, full_name, avatar_url')
          .eq('id', uid).maybeSingle();
      if (usr != null) {
        setState(() {
          _medecinName = usr['name'] ?? usr['full_name'] ?? 'Médecin';
          _avatarUrl   = usr['avatar_url'];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final uid      = _supabase.auth.currentUser!.id;
      final patients = await _supabase.from('patients')
          .select('disease, gender').eq('medecin_id', uid);
      final appts    = await _supabase.from('appointments')
          .select('id').eq('medecin_id', uid).eq('status', 'upcoming');
      setState(() {
        _totalPatients = patients.length;
        _alzheimer     = patients.where((p) =>
            (p['disease'] ?? '').toLowerCase().contains('alzheimer')).length;
        _parkinson     = patients.where((p) =>
            (p['disease'] ?? '').toLowerCase().contains('parkinson')).length;
        _women         = patients.where((p) =>
            (p['gender'] ?? '').toLowerCase() == 'femme').length;
        _men           = patients.where((p) =>
            (p['gender'] ?? '').toLowerCase() == 'homme').length;
        _upcomingAppts = appts.length;
      });
    } catch (_) {}
  }

  Future<void> _loadRecentPatients() async {
    try {
      final uid  = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('patients')
          .select('id, name, disease, age, avatar_url, gender')
          .eq('medecin_id', uid)
          .order('created_at', ascending: false).limit(5);
      setState(() => _recentPatients = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  // ✅ RDV d'aujourd'hui
  Future<void> _loadTodayAppointments() async {
    try {
      final uid   = _supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day).toIso8601String();
      final end   = DateTime(today.year, today.month, today.day, 23, 59).toIso8601String();
      final data  = await _supabase.from('appointments').select()
          .eq('medecin_id', uid)
          .gte('date_time', start).lte('date_time', end)
          .order('date_time').limit(5);
      setState(() => _todayAppts = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      final uid  = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('appointments')
          .select('id, patient_name, date_time, notes')
          .eq('medecin_id', uid).eq('status', 'upcoming')
          .order('date_time').limit(3);
      setState(() => _upcomingApptsList = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  // ── Supprimer patient ──────────────────────────────
  Future<void> _deletePatient(String patientId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le patient ?'),
        content: Text('Supprimer "$name" et toutes ses données ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    await _supabase.from('patients').delete().eq('id', patientId);
    _loadData();
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: CustomScrollView(slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    // ── Stats 4 cartes ──────────────
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // ── RDV aujourd'hui ─────────────
                    _buildSectionHeader("Rendez-vous aujourd'hui",
                        Icons.today_outlined, () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MedecinAppointmentsCalendarPage()))),
                    const SizedBox(height: 12),
                    ..._buildTodayAppts(),
                    const SizedBox(height: 24),

                    // ── RDV à venir ─────────────────
                    _buildSectionHeader('Prochains rendez-vous',
                        Icons.calendar_today_outlined, () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MedecinAppointmentsCalendarPage()))),
                    const SizedBox(height: 12),
                    ..._buildUpcomingAppts(),
                    const SizedBox(height: 24),

                    // ── Patients récents ────────────
                    _buildSectionHeader('Patients récents',
                        Icons.people_outline, () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MedecinPatientsListPage()))),
                    const SizedBox(height: 12),
                    ..._buildPatientCards(),
                    const SizedBox(height: 100),
                  ])),
                ),
              ]),
            ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MedecinPatientsListPage())),
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  // ── SliverAppBar ────────────────────────────────────
  Widget _buildSliverAppBar() {
    // ✅ Affiche le vrai nom
    final displayName = _medecinName.isNotEmpty ? _medecinName : 'Médecin';
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: _primary,
      leading: Builder(builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => Scaffold.of(ctx).openDrawer())),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadData),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyCodePage())),
                child: CircleAvatar(radius: 32, backgroundColor: Colors.white24,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                    ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                    : null)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bonjour,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  // ✅ Vrai nom ici
                  Text('Dr. $displayName',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_medecinSpeciality.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(_medecinSpeciality,
                        style: const TextStyle(color: Colors.white, fontSize: 11))),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    _apptBadge('$_totalPatients patients', Icons.people),
                    const SizedBox(width: 8),
                    _apptBadge('$_upcomingAppts RDV', Icons.calendar_today),
                  ]),
                ])),
            ]),
          )),
        ),
      ),
      title: Text('Dr. $displayName',
        style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  Widget _apptBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.white),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]));
  }

  // ── Stats Grid ──────────────────────────────────────
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.2,
      children: [
        _statCard('Alzheimer', _alzheimer, _totalPatients, const Color(0xFF6C63FF), Icons.psychology),
        _statCard('Parkinson', _parkinson, _totalPatients, const Color(0xFF0EA5E9), Icons.accessibility_new),
        _statCard('Femmes', _women, _totalPatients, const Color(0xFFEC4899), Icons.female),
        _statCard('Hommes', _men, _totalPatients, const Color(0xFF10B981), Icons.male),
      ]);
  }

  Widget _statCard(String label, int count, int total, Color color, IconData icon) {
    final ratio = total == 0 ? 0.0 : count / total;
    final pct   = (ratio * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 54, height: 54,
            child: CircularProgressIndicator(value: ratio, strokeWidth: 6,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color))),
          Icon(icon, color: color, size: 20),
        ]),
        const SizedBox(height: 10),
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text('$pct%', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ]));
  }

  // ── Section header ──────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onSeeAll) {
    return Row(children: [
      Icon(icon, color: _primary, size: 20), const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
      const Spacer(),
      GestureDetector(onTap: onSeeAll,
        child: const Text('Voir tout', style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w500))),
    ]);
  }

  // ── RDV aujourd'hui ─────────────────────────────────
  List<Widget> _buildTodayAppts() {
    if (_todayAppts.isEmpty) {
      return [_emptyCard("Aucun rendez-vous aujourd'hui", Icons.event_available)];
    }
    return _todayAppts.map((a) {
      final dt  = DateTime.tryParse(a['date_time'] ?? '')?.toLocal();
      final t   = dt != null ? DateFormat('HH:mm').format(dt) : '';
      final status = a['status'] ?? 'upcoming';
      final isDone = status == 'done';
      final color  = isDone ? Colors.green : _primary;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(t, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['patient_name'] ?? 'Patient',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (a['notes'] != null && a['notes'].toString().isNotEmpty)
              Text(a['notes'], style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(isDone ? 'Terminé' : 'À venir',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600))),
        ]));
    }).toList();
  }

  // ── RDV à venir ─────────────────────────────────────
  List<Widget> _buildUpcomingAppts() {
    if (_upcomingApptsList.isEmpty) {
      return [_emptyCard('Aucun rendez-vous à venir', Icons.calendar_month_outlined)];
    }
    return _upcomingApptsList.map((a) {
      final dt  = DateTime.tryParse(a['date_time'] ?? '')?.toLocal();
      final dateStr = dt != null ? DateFormat('d MMM — HH:mm').format(dt) : 'N/A';
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today, color: _primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['patient_name'] ?? 'Patient',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]));
    }).toList();
  }

  // ── Cartes patients ─────────────────────────────────
  List<Widget> _buildPatientCards() {
    if (_recentPatients.isEmpty) {
      return [_emptyCard('Aucun patient ajouté', Icons.person_add_outlined)];
    }
    return _recentPatients.map((p) {
      final disease = p['disease'] ?? '';
      final isAlz   = disease.toLowerCase().contains('alzheimer');
      final color   = isAlz ? _primary : const Color(0xFF0EA5E9);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.12),
            backgroundImage: p['avatar_url'] != null ? NetworkImage(p['avatar_url']) : null,
            child: p['avatar_url'] == null
              ? Text((p['name'] ?? 'P')[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))
              : null),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['name'] ?? 'Inconnu',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 3),
            Row(children: [
              _chip(disease, color), const SizedBox(width: 8),
              if (p['gender'] != null) _chip(p['gender'], Colors.grey),
              const SizedBox(width: 8),
              if (p['age'] != null)
                Text('${p['age']} ans', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ])),
          // ✅ Bouton supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _deletePatient(p['id'].toString(), p['name'] ?? ''),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]));
    }).toList();
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)));
  }

  Widget _emptyCard(String msg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.grey.shade300, size: 26),
        const SizedBox(width: 10),
        Text(msg, style: TextStyle(color: Colors.grey.shade400)),
      ]));
  }

  // ── Drawer ──────────────────────────────────────────
  Widget _buildDrawer() {
    final displayName = _medecinName.isNotEmpty ? _medecinName : 'Médecin';
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(child: Column(children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: _primary.withOpacity(0.3),
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                ? Text(displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ✅ Vrai nom dans le drawer
              Text('Dr. $displayName',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(_medecinSpeciality.isNotEmpty ? _medecinSpeciality : 'Médecin',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ])),
          ])),
        const SizedBox(height: 10),
        _dItem(Icons.dashboard_rounded, 'Tableau de bord', true, () {}),
        _dItem(Icons.badge_outlined, 'Mon Code', false, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCodePage()));
        }),
        _dItem(Icons.chat_bubble_outline, 'Messages', false, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
        }),
        _dItem(Icons.people_outline, 'Mes Patients', false, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MedecinPatientsListPage()));
        }),
        _dItem(Icons.calendar_today_outlined, 'ordonnance', false, () {
  Navigator.pop(context);
  Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrdonnancePage(patient: null),
  ));
}),
        const Spacer(),
        _dItem(Icons.logout_rounded, 'Déconnexion', false, () async {
          await authService.signOut();
        }, isLogout: true),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _dItem(IconData icon, String label, bool selected, VoidCallback onTap,
      {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? _primary.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 22,
          color: isLogout ? Colors.red[300] : selected ? _primary : Colors.white60),
        title: Text(label, style: TextStyle(fontSize: 14,
          color: isLogout ? Colors.red[300] : selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap));
  }

  // ── Bottom Nav ──────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navItem(Icons.home_outlined, 0, () {}),
        _navItem(Icons.people_outline, 1, () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MedecinPatientsListPage()))),
       /// _navItem(Icons.calendar_today_outlined, 2, () => Navigator.push(context,
         ///   MaterialPageRoute(builder: (_) => const MedecinAppointmentsCalendarPage()))),
        _navItem(Icons.chat_bubble_outline, 3, () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()))),
            IconButton(
  icon: Icon(Icons.receipt_long),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdonnancePage(patient: null),
      ),
    );
  },
)
      ]));
  }

  Widget _navItem(IconData icon, int index, VoidCallback onTap) {
    final bool sel = _selectedNav == index;
    return GestureDetector(
      onTap: () { setState(() => _selectedNav = index); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, size: 26, color: sel ? _primary : Colors.white54)));
  }
}
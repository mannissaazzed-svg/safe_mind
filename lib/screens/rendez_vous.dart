// rendez_vous.dart — SafeMind
// ═══════════════════════════════════════════════════════
// Rendez-vous patient/accompagnant avec Realtime
// Notification instantanée quand le médecin crée un RDV
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RendezVous extends StatefulWidget {
  const RendezVous({super.key});

  @override
  State<RendezVous> createState() => _RendezVousState();
}

class _RendezVousState extends State<RendezVous>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _past     = [];
  bool _isLoading = true;
  String? _userRole;
  String? _patientId;
  RealtimeChannel? _channel;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger  = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final uid  = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('users')
          .select('role, linked_to')
          .eq('id', uid)
          .maybeSingle();

      _userRole = data?['role'] as String? ?? 'patient';

      if (_userRole == 'caregiver') {
        _patientId = data?['linked_to'] as String?;
      } else {
        _patientId = uid;
      }

      await _loadAppointments();
      _subscribeRealtime(); // ← Realtime après le premier chargement
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════
  // REALTIME — écoute les nouveaux RDV en temps réel
  // ══════════════════════════════════════════════════
  void _subscribeRealtime() {
    if (_patientId == null) return;

    _channel = _supabase
        .channel('rdv_patient_$_patientId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'appointments',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'patient_id',
            value:  _patientId!,
          ),
          callback: (payload) {
            if (!mounted) return;
            _loadAppointments(); // Rafraîchir la liste
            _showNewRdvBanner(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'appointments',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'patient_id',
            value:  _patientId!,
          ),
          callback: (_) {
            if (!mounted) return;
            _loadAppointments();
          },
        )
        .subscribe();
  }

  void _showNewRdvBanner(Map<String, dynamic> record) {
    final dt = DateTime.tryParse(record['date_time'] ?? '')?.toLocal();
    final dateStr = dt != null
        ? DateFormat('EEEE d MMMM — HH:mm', 'fr').format(dt)
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nouveau rendez-vous !',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ]),
      ),
    );

    // Basculer vers l'onglet "À venir"
    _tabController.animateTo(0);
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      if (_patientId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await _supabase
          .from('appointments')
          .select()
          .eq('patient_id', _patientId!)
          .order('date_time');

      final all      = List<Map<String, dynamic>>.from(data);
      final upcoming = <Map<String, dynamic>>[];
      final past     = <Map<String, dynamic>>[];

      for (final a in all) {
        final dt = DateTime.tryParse(a['date_time'] ?? '');
        if (dt != null && dt.isAfter(DateTime.now())) {
          upcoming.add(a);
        } else {
          past.add(a);
        }
      }

      past.sort((a, b) {
        final da = DateTime.tryParse(a['date_time'] ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['date_time'] ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

      setState(() {
        _upcoming  = upcoming;
        _past      = past;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: _primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAppointments,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mes Rendez-vous',
                            style: TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          _userRole == 'caregiver'
                              ? 'Rendez-vous de votre patient'
                              : 'Vos rendez-vous avec le médecin',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statBadge('${_upcoming.length}', 'À venir', Icons.event_available),
                          const SizedBox(width: 10),
                          _statBadge('${_past.length}', 'Passés', Icons.history),
                          const SizedBox(width: 10),
                          // Indicateur Realtime
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: _channel != null ? _success : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _channel != null ? 'En direct' : 'Hors ligne',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.upcoming, size: 16),
                    const SizedBox(width: 6),
                    const Text('À venir'),
                    if (_upcoming.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: _warning, borderRadius: BorderRadius.circular(10)),
                        child: Text('${_upcoming.length}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ),
                const Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history, size: 16),
                    SizedBox(width: 6),
                    Text('Historique'),
                  ]),
                ),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : TabBarView(
                controller: _tabController,
                children: [_buildUpcoming(), _buildPast()],
              ),
      ),
    );
  }

  Widget _buildUpcoming() {
    if (_upcoming.isEmpty) {
      return _emptyState(
        icon: Icons.event_available_outlined,
        title: 'Aucun rendez-vous à venir',
        subtitle: 'Votre médecin n\'a pas encore planifié de rendez-vous.\nVous serez notifié automatiquement.',
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcoming.length,
        itemBuilder: (_, i) => _buildUpcomingCard(_upcoming[i]),
      ),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> appt) {
    final dt         = DateTime.tryParse(appt['date_time'] ?? '')?.toLocal();
    final isToday    = dt != null && dt.day == DateTime.now().day && dt.month == DateTime.now().month && dt.year == DateTime.now().year;
    final isTomorrow = dt != null && dt.difference(DateTime.now()).inDays == 1;
    final daysLeft   = dt != null ? dt.difference(DateTime.now()).inDays : 0;

    Color cardColor;
    String timeLabel;

    if (isToday) {
      cardColor = _danger;
      timeLabel = "Aujourd'hui !";
    } else if (isTomorrow) {
      cardColor = _warning;
      timeLabel = 'Demain';
    } else {
      cardColor = _primary;
      timeLabel = 'Dans $daysLeft jour${daysLeft > 1 ? 's' : ''}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: cardColor, width: 5)),
        boxShadow: [BoxShadow(color: cardColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(dt != null ? DateFormat('d').format(dt) : '--',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cardColor)),
                Text(dt != null ? DateFormat('MMM', 'fr').format(dt) : '--',
                    style: TextStyle(fontSize: 10, color: cardColor)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  dt != null ? DateFormat('EEEE d MMMM yyyy', 'fr').format(dt) : 'Date N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dt != null ? DateFormat('HH:mm').format(dt) : '--',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(timeLabel,
                  style: TextStyle(color: cardColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          if (appt['notes'] != null && appt['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F4FA), borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.note_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(appt['notes'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                ),
              ]),
            ),
          ],
          if (isToday) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _danger.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.notifications_active, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Text('Vous avez un rendez-vous aujourd\'hui !',
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildPast() {
    if (_past.isEmpty) {
      return _emptyState(
        icon: Icons.history_outlined,
        title: 'Aucun historique',
        subtitle: 'Les consultations passées apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _past.length,
        itemBuilder: (_, i) => _buildPastCard(_past[i]),
      ),
    );
  }

  Widget _buildPastCard(Map<String, dynamic> appt) {
    final dt     = DateTime.tryParse(appt['date_time'] ?? '')?.toLocal();
    final status = appt['status'] as String? ?? 'done';
    final isDone = status == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isDone ? _success.withOpacity(0.1) : _danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isDone ? _success : _danger, size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              dt != null ? DateFormat('d MMM yyyy', 'fr').format(dt) : 'Date N/A',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(dt != null ? DateFormat('HH:mm').format(dt) : '',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (appt['notes'] != null && appt['notes'].toString().isNotEmpty)
              Text(appt['notes'],
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDone ? _success.withOpacity(0.1) : _danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isDone ? 'Terminé' : 'Manqué',
            style: TextStyle(
                color: isDone ? _success : _danger,
                fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _statBadge(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text('$value $label',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
              color: _primary.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: _primary),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
      ]),
    );
  }
}
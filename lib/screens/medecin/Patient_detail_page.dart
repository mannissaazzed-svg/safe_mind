import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════
// Fiche détaillée du patient — SafeMind
// ═══════════════════════════════════════════════════════

class MedecinPatientDetailPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  const MedecinPatientDetailPage({super.key, required this.patient});

  @override
  State<MedecinPatientDetailPage> createState() => _MedecinPatientDetailPageState();
}

class _MedecinPatientDetailPageState extends State<MedecinPatientDetailPage>
    with SingleTickerProviderStateMixin {
  final _supabase  = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _notes        = [];
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadNotes(), _loadAppointments()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotes() async {
    try {
      final data = await _supabase
          .from('medecin_notes')
          .select()
          .eq('patient_id', widget.patient['id'])
          .order('created_at', ascending: false);
      setState(() => _notes = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _loadAppointments() async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('patient_id', widget.patient['id'])
          .order('date_time');
      setState(() =>
          _appointments = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  // ── Ajouter note ───────────────────────────────────
  Future<void> _addNote() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle note',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Écrire une note...',
                  filled: true,
                  fillColor: const Color(0xFFF5F4FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    await _supabase.from('medecin_notes').insert({
                      'medecin_id':  _supabase.auth.currentUser!.id,
                      'patient_id': widget.patient['id'],
                      'content':    ctrl.text.trim(),
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadNotes();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ajouter RDV ────────────────────────────────────
  Future<void> _addAppointment() async {
    DateTime? picked;
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nouveau rendez-vous',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) {
                        setModal(() => picked = DateTime(
                            d.year, d.month, d.day, t.hour, t.minute));
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F4FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: picked != null
                              ? _primary : Colors.grey.shade200,
                          width: picked != null ? 2 : 1),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          color: picked != null
                              ? _primary : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        picked != null
                            ? DateFormat('d MMM yyyy — HH:mm')
                                .format(picked!)
                            : 'Choisir date et heure',
                        style: TextStyle(
                          color: picked != null
                              ? const Color(0xFF1A1A2E) : Colors.grey,
                          fontWeight: picked != null
                              ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    hintText: 'Notes (optionnel)',
                    filled: true,
                    fillColor: const Color(0xFFF5F4FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (picked == null) return;
                      await _supabase.from('appointments').insert({
                        'medecin_id':    _supabase.auth.currentUser!.id,
                        'patient_id':   widget.patient['id'],
                        'patient_name': widget.patient['name'],
                        'date_time':    picked!.toIso8601String(),
                        'notes':        notesCtrl.text.trim(),
                        'status':       'upcoming',
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadAppointments();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enregistrer',
                        style:
                            TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final p       = widget.patient;
    final name    = p['name'] ?? 'Patient';
    final disease = p['disease'] ?? '';
    final isAlz   = disease.toLowerCase().contains('alzheimer');
    final color   = isAlz ? _primary : const Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.note_add_outlined,
                    color: Colors.white),
                onPressed: _addNote,
                tooltip: 'Ajouter note',
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined,
                    color: Colors.white),
                onPressed: _addAppointment,
                tooltip: 'Ajouter RDV',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white24,
                        backgroundImage: p['avatar_url'] != null
                            ? NetworkImage(p['avatar_url']) : null,
                        child: p['avatar_url'] == null
                            ? Text(name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badge(disease, Colors.white24, Colors.white),
                          const SizedBox(width: 8),
                          if (p['age'] != null)
                            _badge('${p['age']} ans',
                                Colors.white24, Colors.white),
                          if (p['gender'] != null) ...[
                            const SizedBox(width: 8),
                            _badge(p['gender'],
                                Colors.white24, Colors.white),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Dossier'),
                Tab(text: 'Notes'),
                Tab(text: 'Rendez-vous'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDossierTab(p, color),
                  _buildNotesTab(),
                  _buildAppointmentsTab(),
                ],
              ),
      ),
    );
  }

  // ── Onglet Dossier ─────────────────────────────────
  Widget _buildDossierTab(Map p, Color color) {
    final createdAt = p['created_at'] != null
        ? DateTime.tryParse(p['created_at'])?.toLocal() : null;
    final sinceStr  = createdAt != null
        ? DateFormat('d MMM yyyy').format(createdAt) : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // ── Infos générales ────────────────────────
        _infoCard('Informations générales', Icons.person_outline, color, [
          _infoRow('Nom', p['name'] ?? 'N/A'),
          _infoRow('Âge', p['age']?.toString() ?? 'N/A'),
          _infoRow('Genre', p['gender'] ?? 'N/A'),
          _infoRow('Maladie', p['disease'] ?? 'N/A'),
          _infoRow('Patient depuis', sinceStr),
        ]),
        const SizedBox(height: 16),

        // ── Accompagnant ───────────────────────────
        _infoCard('Accompagnant', Icons.people_outline, color, [
          _infoRow('Nom', p['caregiver_name'] ?? 'N/A'),
          _infoRow('Téléphone', p['caregiver_phone'] ?? 'N/A'),
        ]),
        const SizedBox(height: 16),

        // ── Médicaments ────────────────────────────
        if (p['medications'] != null) ...[
          _infoCard('Médicaments', Icons.medication_outlined, color,
              (p['medications'] as List).map((m) =>
                  _infoRow('💊', m.toString())).toList()),
          const SizedBox(height: 16),
        ],

        // ── Notes générales ────────────────────────
        if (p['notes'] != null && p['notes'].toString().isNotEmpty)
          _infoCard('Notes générales', Icons.note_outlined, color, [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(p['notes'],
                  style: TextStyle(
                      color: Colors.grey.shade700, height: 1.5)),
            ),
          ]),
      ]),
    );
  }

  Widget _infoCard(String title, IconData icon, Color color,
      List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14,
                  color: Color(0xFF1A1A2E))),
        ]),
        const Divider(height: 20),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text('$label : ',
            style: const TextStyle(
                color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E))),
        ),
      ]),
    );
  }

  // ── Onglet Notes ───────────────────────────────────
  Widget _buildNotesTab() {
    return _notes.isEmpty
        ? _emptyState('Aucune note', Icons.note_outlined, _addNote,
            'Ajouter une note')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notes.length,
            itemBuilder: (_, i) {
              final note = _notes[i];
              final dt   = DateTime.tryParse(
                  note['created_at'] ?? '')?.toLocal();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _primary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note['content'] ?? '',
                        style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      dt != null
                          ? DateFormat('d MMM yyyy — HH:mm').format(dt)
                          : '',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          );
  }

  // ── Onglet Rendez-vous ─────────────────────────────
  Widget _buildAppointmentsTab() {
    return _appointments.isEmpty
        ? _emptyState('Aucun rendez-vous',
            Icons.calendar_today_outlined, _addAppointment,
            'Ajouter un RDV')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _appointments.length,
            itemBuilder: (_, i) {
              final a  = _appointments[i];
              final dt = DateTime.tryParse(a['date_time'] ?? '')?.toLocal();
              final isPast = dt != null && dt.isBefore(DateTime.now());
              final status = a['status'] ?? 'upcoming';
              Color statusColor = status == 'done'
                  ? Colors.green : isPast ? Colors.red : _primary;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: statusColor.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today,
                        color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dt != null
                            ? DateFormat('d MMM yyyy — HH:mm').format(dt)
                            : 'Date N/A',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (a['notes'] != null &&
                          a['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(a['notes'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'done' ? 'Terminé'
                          : isPast ? 'Passé' : 'À venir',
                      style: TextStyle(
                          color: statusColor, fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              );
            },
          );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _emptyState(String msg, IconData icon,
      VoidCallback onTap, String btnLabel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(btnLabel,
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
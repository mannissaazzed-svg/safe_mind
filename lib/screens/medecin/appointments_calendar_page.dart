import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════
// Page Calendrier des Rendez-vous — SafeMind
// Style Google Calendar avec vue mensuelle + détails
// ═══════════════════════════════════════════════════════

class MedecinAppointmentsCalendarPage extends StatefulWidget {
  const MedecinAppointmentsCalendarPage({super.key});

  @override
  State<MedecinAppointmentsCalendarPage> createState() =>
      _MedecinAppointmentsCalendarPageState();
}

class _MedecinAppointmentsCalendarPageState
    extends State<MedecinAppointmentsCalendarPage> {
  final _supabase = Supabase.instance.client;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay  = DateTime.now();

  List<Map<String, dynamic>> _allAppointments = [];
  bool _isLoading = true;

  static const Color _primary   = Color(0xFF6C63FF);
  static const Color _bg        = Color(0xFFF5F4FA);
  static const Color _today     = Color(0xFF6C63FF);
  static const Color _selected  = Color(0xFFEDE9FE);
  static const Color _hasAppt   = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final uid  = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('medecin_id', uid)
          .order('date_time');
      setState(() {
        _allAppointments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Rendez-vous du jour sélectionné ───────────────
  List<Map<String, dynamic>> get _selectedDayAppts {
    return _allAppointments.where((a) {
      final dt = DateTime.tryParse(a['date_time'] ?? '');
      if (dt == null) return false;
      return dt.year == _selectedDay.year &&
          dt.month == _selectedDay.month &&
          dt.day == _selectedDay.day;
    }).toList();
  }

  // ── Vérifier si un jour a des RDV ─────────────────
  bool _hasAppointment(DateTime day) {
    return _allAppointments.any((a) {
      final dt = DateTime.tryParse(a['date_time'] ?? '');
      if (dt == null) return false;
      return dt.year == day.year &&
          dt.month == day.month &&
          dt.day == day.day;
    });
  }

  // ── Ajouter RDV ────────────────────────────────────
  Future<void> _addAppointment() async {
    final nameCtrl  = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? picked = DateTime(
      _selectedDay.year, _selectedDay.month, _selectedDay.day,
      DateTime.now().hour, DateTime.now().minute,
    );

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nouveau rendez-vous',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),

                // ── Date/heure ─────────────────────
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(
                          hour: picked!.hour, minute: picked!.minute),
                    );
                    if (t != null) {
                      setModal(() => picked = DateTime(
                          _selectedDay.year, _selectedDay.month,
                          _selectedDay.day, t.hour, t.minute));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time, color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE d MMM yyyy — HH:mm', 'fr')
                            .format(picked!),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Nom patient ────────────────────
                _inputField(nameCtrl, 'Nom du patient', Icons.person_outline),
                const SizedBox(height: 12),

                // ── Notes ──────────────────────────
                _inputField(notesCtrl, 'Notes (optionnel)',
                    Icons.note_outlined, maxLines: 3),
                const SizedBox(height: 20),

                // ── Bouton ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final uid = _supabase.auth.currentUser!.id;
                      await _supabase.from('appointments').insert({
                        'medecin_id':   uid,
                        'patient_name': nameCtrl.text.trim(),
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
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Enregistrer',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
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

  // ── Supprimer RDV ──────────────────────────────────
  Future<void> _deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('id', id);
    _loadAppointments();
  }

  // ── Marquer comme terminé ──────────────────────────
  Future<void> _markDone(String id) async {
    await _supabase
        .from('appointments')
        .update({'status': 'done'})
        .eq('id', id);
    _loadAppointments();
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rendez-vous',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // ── Calendrier ────────────────────────
                _buildCalendar(),
                // ── RDV du jour sélectionné ───────────
                Expanded(child: _buildDayAppointments()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: _addAppointment,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Calendrier mensuel ────────────────────────────
  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── Navigateur mois ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _primary),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'fr').format(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _primary),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                ),
              ],
            ),
          ),

          // ── Jours de la semaine ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                  .map((d) => SizedBox(
                        width: 40,
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            )),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Grille des jours ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildDaysGrid(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Lundi = 1, donc décalage
    int startWeekday = firstDay.weekday - 1;
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    List<Widget> cells = [];

    // Cellules vides avant le 1er
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 40, height: 44));
    }

    // Jours du mois
    for (int day = 1; day <= daysInMonth; day++) {
      final date  = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isToday = date.year == today.year &&
          date.month == today.month && date.day == today.day;
      final isSelected = date.year == _selectedDay.year &&
          date.month == _selectedDay.month && date.day == _selectedDay.day;
      final hasAppt = _hasAppointment(date);

      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDay = date),
        child: Container(
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? _selected : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isToday ? _today : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : isSelected
                              ? _primary
                              : const Color(0xFF1A1A2E),
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (hasAppt)
                Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: _hasAppt, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: cells,
    );
  }

  // ── RDV du jour ───────────────────────────────────
  Widget _buildDayAppointments() {
    final appts = _selectedDayAppts;
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header du jour ───────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            const Icon(Icons.calendar_today, color: _primary, size: 16),
            const SizedBox(width: 8),
            Text(dateStr,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E))),
            const Spacer(),
            if (appts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${appts.length} RDV',
                    style: const TextStyle(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
        ),

        // ── Liste des RDV ────────────────────────
        Expanded(
          child: appts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      Text('Aucun rendez-vous ce jour',
                          style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _addAppointment,
                        icon: const Icon(Icons.add, color: _primary, size: 18),
                        label: const Text('Ajouter un RDV',
                            style: TextStyle(color: _primary)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appts.length,
                  itemBuilder: (_, i) => _buildApptCard(appts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildApptCard(Map<String, dynamic> a) {
    final dt      = DateTime.tryParse(a['date_time'] ?? '')?.toLocal();
    final timeStr = dt != null ? DateFormat('HH:mm').format(dt) : '';
    final status  = a['status'] ?? 'upcoming';
    final isDone  = status == 'done';
    final isPast  = dt != null && dt.isBefore(DateTime.now());
    final color   = isDone ? Colors.green : isPast ? Colors.red : _primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(timeStr,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        title: Text(a['patient_name'] ?? 'Patient',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a['notes'] != null && a['notes'].toString().isNotEmpty)
              Text(a['notes'],
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isDone ? 'Terminé' : isPast ? 'Passé' : 'À venir',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'done') _markDone(a['id'].toString());
            if (v == 'delete') _deleteAppointment(a['id'].toString());
          },
          itemBuilder: (_) => [
            if (!isDone)
              const PopupMenuItem(
                value: 'done',
                child: Row(children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 18),
                  SizedBox(width: 10),
                  Text('Marquer terminé'),
                ]),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                SizedBox(width: 10),
                Text('Supprimer', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController c, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primary, size: 20),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F4FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }
}
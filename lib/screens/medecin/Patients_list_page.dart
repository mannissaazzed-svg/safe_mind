import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/medecin/patient_detail_page.dart';

// ═══════════════════════════════════════════════════════
// Liste des patients — SafeMind
// ═══════════════════════════════════════════════════════

class MedecinPatientsListPage extends StatefulWidget {
  const MedecinPatientsListPage({super.key});

  @override
  State<MedecinPatientsListPage> createState() => _MedecinPatientsListPageState();
}

class _MedecinPatientsListPageState extends State<MedecinPatientsListPage> {
  final _supabase     = Supabase.instance.client;
  final _searchCtrl   = TextEditingController();

  List<Map<String, dynamic>> _patients   = [];
  List<Map<String, dynamic>> _filtered   = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final uid  = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('patients')
          .select()
          .eq('medecin_id', uid)
          .order('created_at', ascending: false);
      setState(() {
        _patients = List<Map<String, dynamic>>.from(data);
        _filtered = _patients;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients
          : _patients.where((p) {
              final name = (p['name'] ?? '').toLowerCase();
              final id   = (p['id'] ?? '').toLowerCase();
              return name.contains(q) || id.contains(q);
            }).toList();
    });
  }

  // ── Ajouter patient ────────────────────────────────
  void _showAddPatient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPatientSheet(onAdded: _loadPatients),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Text('Mes Patients',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ── Ajouter patient ────────────────────────
          IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white, size: 18),
            ),
            onPressed: _showAddPatient,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de recherche ─────────────────────
          Container(
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou ID...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch();
                        })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Compteur ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              Text('${_filtered.length} patient(s)',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            ]),
          ),

          // ── Liste ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildPatientCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: _showAddPatient,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> p) {
    final disease = p['disease'] ?? '';
    final isAlz   = disease.toLowerCase().contains('alzheimer');
    final color   = isAlz ? _primary : const Color(0xFF0EA5E9);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedecinPatientDetailPage(patient: p),
        ),
      ).then((_) => _loadPatients()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          // ── Avatar ──────────────────────────────
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            backgroundImage: p['avatar_url'] != null
                ? NetworkImage(p['avatar_url']) : null,
            child: p['avatar_url'] == null
                ? Text(
                    (p['name'] ?? 'P')[0].toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18))
                : null,
          ),
          const SizedBox(width: 14),

          // ── Infos ────────────────────────────────
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['name'] ?? 'Inconnu',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                _chip(disease, color),
                const SizedBox(width: 8),
                if (p['gender'] != null)
                  _chip(p['gender'], Colors.grey),
                const SizedBox(width: 8),
                if (p['age'] != null)
                  Text('${p['age']} ans',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
              ]),
              if (p['caregiver_name'] != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.people_outline,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(p['caregiver_name'],
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ]),
              ],
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline,
                size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun patient trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ajoutez votre premier patient',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// FICHE AJOUT PATIENT
// ══════════════════════════════════════════════════════

class _AddPatientSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddPatientSheet({required this.onAdded});

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _supabase = Supabase.instance.client;
  final _picker   = ImagePicker();
  final _nameCtrl         = TextEditingController();
  final _ageCtrl          = TextEditingController();
  final _caregiverNameCtrl = TextEditingController();
  final _caregiverPhoneCtrl = TextEditingController();
  final _notesCtrl        = TextEditingController();

  String? _gender;
  String? _disease;
  File?   _photo;
  bool    _isSaving = false;

  static const Color _primary = Color(0xFF6C63FF);

  Future<void> _pickPhoto() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _photo = File(img.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      String? avatarUrl;

      if (_photo != null) {
        final name = 'patient_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('avatars').upload(
            name, _photo!,
            fileOptions: const FileOptions(upsert: true));
        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(name);
      }

      await _supabase.from('patients').insert({
        'medecin_id':      uid,
        'name':           _nameCtrl.text.trim(),
        'age':            int.tryParse(_ageCtrl.text),
        'gender':         _gender,
        'disease':        _disease,
        'caregiver_name': _caregiverNameCtrl.text.trim(),
        'caregiver_phone': _caregiverPhoneCtrl.text.trim(),
        'notes':          _notesCtrl.text.trim(),
        'avatar_url':     avatarUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'),
              backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('Nouveau Patient',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: _primary, strokeWidth: 2))
                    : const Text('Enregistrer',
                        style: TextStyle(color: _primary,
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              children: [
                // ── Photo ──────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: _primary.withOpacity(0.1),
                        backgroundImage: _photo != null
                            ? FileImage(_photo!) : null,
                        child: _photo == null
                            ? const Icon(Icons.person_add,
                                size: 36, color: _primary)
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: const BoxDecoration(
                              color: _primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Champs ─────────────────────────
                _field(_nameCtrl, 'Nom complet *', Icons.person_outline),
                _field(_ageCtrl, 'Âge', Icons.cake_outlined,
                    type: TextInputType.number),

                // Gender
                _dropdownRow('Genre', ['Homme', 'Femme'], _gender,
                    (v) => setState(() => _gender = v)),
                const SizedBox(height: 12),

                // Disease
                _dropdownRow('Maladie', ['Alzheimer', 'Parkinson'], _disease,
                    (v) => setState(() => _disease = v)),
                const SizedBox(height: 20),

                const Text('Accompagnant',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 10),
                _field(_caregiverNameCtrl, 'Nom de l\'accompagnant',
                    Icons.people_outline),
                _field(_caregiverPhoneCtrl, 'Téléphone accompagnant',
                    Icons.phone_outlined,
                    type: TextInputType.phone),

                const SizedBox(height: 8),
                _field(_notesCtrl, 'Notes', Icons.note_outlined,
                    maxLines: 3),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
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
      ),
    );
  }

  Widget _dropdownRow(String label, List<String> options,
      String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
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
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
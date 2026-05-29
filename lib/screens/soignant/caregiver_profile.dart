import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/soignant/formulaire.dart';
import 'package:safemind/widgets/link_by_code_widget.dart';
import 'package:safemind/screens/soignant/caregiver.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

class CaregiverProfileScreen extends StatefulWidget {
  final bool isFirstTime;
  const CaregiverProfileScreen({super.key, this.isFirstTime = false});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final _supabase = Supabase.instance.client;
  final authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _doctorCodeCtrl = TextEditingController();

  final List<String> _diseasesList = [
    'Alzheimer',
    'Parkinson',
    'Alzheimer & Parkinson'
  ];
  String? _selectedDisease;

  Map<String, dynamic>? _data;
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) return;
    final currentTypedName = _nameCtrl.text;
    try {
      final d = await _supabase.from('users').select().eq('id', id).maybeSingle();
      if (mounted) {
        setState(() {
          _data = d;
          final dbName = d?['full_name'] as String? ?? '';
          _nameCtrl.text = currentTypedName.isNotEmpty ? currentTypedName : dbName;
          if (_diseasesList.contains(d?['disease'])) _selectedDisease = d?['disease'];
        });
      }
      final patientId = d?['linked_to'] as String?;
      if (patientId != null) {
        final pd = await _supabase.from('users').select('full_name, disease, avatar_url').eq('id', patientId).maybeSingle();
        if (mounted) setState(() => _patientData = pd);
      } else {
        if (mounted) setState(() => _patientData = null);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final t = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt, color: Color(0xFF419AFF)), title: Text(t.caregiver_camera), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library, color: Color(0xFF419AFF)), title: Text(t.caregiver_gallery), onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (picked == null) return;
    setState(() => _localImage = File(picked.path));
    try {
      final id = _supabase.auth.currentUser!.id;
      final bytes = await File(picked.path).readAsBytes();
      final fileName = '$id-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$fileName';
      await _supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase.from('users').update({'avatar_url': url}).eq('id', id);
      if (mounted) { setState(() => _data = {...?_data, 'avatar_url': url}); _snack(t.caregiver_name_saved, isError: false); }
    } catch (e) { _snack(AppLocalizations.of(context)!.caregiver_image_error); }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack(t.caregiver_name_required); return; }
    if (_selectedDisease == null) { _snack(t.caregiver_disease_required); return; }
    setState(() => _isSaving = true);
    try {
      final id = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'full_name': name, 'disease': _selectedDisease}).eq('id', id);
      if (mounted) {
        setState(() => _data = {...?_data, 'full_name': name, 'disease': _selectedDisease});
        if (widget.isFirstTime) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PatientForm(preselectedDisease: _selectedDisease!)));
        } else {
          final patientId = _data?['linked_to'] as String?;
          if (patientId != null) await _supabase.from('users').update({'disease': _selectedDisease}).eq('id', patientId);
          _snack(t.caregiver_profile_saved, isError: false);
        }
      }
    } catch (e) { _snack(AppLocalizations.of(context)!.caregiver_save_error); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _linkDoctor() async {
    final t = AppLocalizations.of(context)!;
    final code = _doctorCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) { _snack(t.caregiver_doctor_code_required); return; }
    try {
      final caregiverId = _supabase.auth.currentUser!.id;
      final doctor = await _supabase.from('users').select().eq('short_code', code).eq('role', 'doctor').maybeSingle();
      if (doctor == null) { _snack(t.caregiver_doctor_not_found); return; }
      await _supabase.from('users').update({'doctor_id': doctor['id']}).eq('id', caregiverId);
      _snack(t.caregiver_doctor_linked, isError: false);
      _doctorCodeCtrl.clear();
      await _load();
    } catch (e) { _snack(AppLocalizations.of(context)!.caregiver_link_error); }
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(t.logout), content: Text(t.logoutConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirm, style: const TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      await authService.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? Colors.red : const Color(0xFF419AFF),
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() { _nameCtrl.dispose(); _doctorCodeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF419AFF))));

    final avatarUrl = _data?['avatar_url'] as String?;
    final bool isLinked = _data?['linked_to'] != null && _patientData != null;
    final patientName = (_patientData?['full_name'] as String?)?.isNotEmpty == true ? _patientData!['full_name'] as String : 'Patient (non nommé)';
    final patientDisease = (_patientData?['disease'] as String?)?.isNotEmpty == true ? _patientData!['disease'] as String : 'Non spécifiée';
    final myCode = (_supabase.auth.currentUser?.id ?? '').length >= 8 ? _supabase.auth.currentUser!.id.substring(0, 8).toUpperCase() : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FB),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240, pinned: true,
          backgroundColor: const Color(0xFF419AFF),
          automaticallyImplyLeading: !widget.isFirstTime,
          actions: [if (!widget.isFirstTime) IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF419AFF), Color(0xFF185FA5)])),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                GestureDetector(onTap: _pickImage,
                  child: Stack(children: [
                    Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                      child: CircleAvatar(radius: 50, backgroundColor: Colors.white,
                        backgroundImage: _localImage != null ? FileImage(_localImage!) as ImageProvider : (avatarUrl != null ? NetworkImage(avatarUrl) : null),
                        child: (_localImage == null && avatarUrl == null) ? const Icon(Icons.person, size: 50, color: Color(0xFF419AFF)) : null)),
                    Positioned(bottom: 0, right: 0,
                      child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF419AFF), size: 20))),
                  ])),
                const SizedBox(height: 10),
                Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Votre Nom',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(delegate: SliverChildListDelegate([
            if (widget.isFirstTime) ...[
              Text(t.caregiver_welcome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF185FA5))),
              Text(t.caregiver_welcome_sub, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
            ],

            // ── Nom ──────────────────────────────────────
            _card(icon: Icons.person_outline, color: const Color(0xFF419AFF), title: t.caregiver_full_name,
              child: Column(children: [
                TextField(controller: _nameCtrl, onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: t.caregiver_name_hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) { _snack(t.caregiver_name_required); return; }
                    setState(() => _isSaving = true);
                    try {
                      await _supabase.from('users').update({'full_name': name}).eq('id', _supabase.auth.currentUser!.id);
                      setState(() => _data = {...?_data, 'full_name': name});
                      _snack(t.caregiver_name_saved, isError: false);
                    } catch (_) { _snack(t.caregiver_save_error); }
                    finally { if (mounted) setState(() => _isSaving = false); }
                  },
                  icon: _isSaving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                  label: Text(_isSaving ? t.caregiver_saving : t.caregiver_save_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF419AFF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ])),
            const SizedBox(height: 15),

            // ── Informations compte ───────────────────────
            _card(icon: Icons.medical_information_outlined, color: Colors.blue, title: t.caregiver_account_info,
              child: Column(children: [
                _infoRow(Icons.email_outlined, t.caregiver_email, _supabase.auth.currentUser?.email ?? '—'),
                const Divider(height: 25),
                Row(children: [
                  Text(t.caregiver_disease, style: const TextStyle(color: Colors.grey, fontSize: 14)), const Spacer(),
                  DropdownButton<String>(
                    value: _selectedDisease, hint: Text(t.caregiver_disease_choose), underline: const SizedBox(),
                    items: _diseasesList.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) => setState(() => _selectedDisease = val)),
                ]),
              ])),
            const SizedBox(height: 15),

            // ── Mon code ─────────────────────────────────
            _card(icon: Icons.qr_code_2, color: Colors.orange, title: t.caregiver_my_code,
              child: Column(children: [
                Text(t.caregiver_code_hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: myCode)); _snack(t.caregiver_code_copied, isError: false); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.shade300, width: 1.5)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(myCode, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 8)),
                      const SizedBox(width: 10), const Icon(Icons.copy_rounded, color: Colors.orange, size: 20),
                    ])),
                ),
              ])),
            const SizedBox(height: 15),

            // ── Patient lié ───────────────────────────────
            _card(icon: Icons.link_rounded, color: const Color(0xFF1D9E75), title: t.caregiver_linked_patient,
              child: isLinked
                  ? ListTile(contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundImage: _patientData!['avatar_url'] != null ? NetworkImage(_patientData!['avatar_url']) : null, child: _patientData!['avatar_url'] == null ? const Icon(Icons.person) : null),
                      title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(patientDisease), trailing: const Icon(Icons.check_circle, color: Colors.green))
                  : LinkByCodeWidget(supabase: _supabase, currentRole: 'caregiver', onLinked: _load)),
            const SizedBox(height: 15),

            // ── Médecin ───────────────────────────────────
            _card(icon: Icons.local_hospital, color: Colors.red, title: t.caregiver_linked_doctor,
              child: Column(children: [
                TextField(controller: _doctorCodeCtrl,
                  decoration: InputDecoration(hintText: t.caregiver_doctor_code_hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.medical_services))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _linkDoctor, icon: const Icon(Icons.link, color: Colors.white),
                  label: Text(t.caregiver_link_doctor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ])),
            const SizedBox(height: 40),

            // ── Bouton principal ──────────────────────────
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isFirstTime ? const Color(0xFF1D9E75) : const Color(0xFF419AFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(widget.isFirstTime ? Icons.supervisor_account_rounded : Icons.save_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.isFirstTime ? t.caregiver_next_patient : t.caregiver_save_changes, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (widget.isFirstTime) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.white, size: 20)],
                    ]),
            )),
            const SizedBox(height: 20),
          ])),
        ),
      ]),
    );
  }

  Widget _card({required IconData icon, required Color color, required String title, required Widget child}) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
        const SizedBox(height: 15), child,
      ]));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}




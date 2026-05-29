import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/widgets/link_by_code_widget.dart';
import 'package:safemind/generated/l10n/app_localizations.dart';

class PatientProfileScreen extends StatefulWidget {
  final bool isFirstTime;
  const PatientProfileScreen({super.key, this.isFirstTime = false});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _supabase   = Supabase.instance.client;
  final authService = AuthService();
  final _nameCtrl   = TextEditingController();
  final _doctorCodeCtrl = TextEditingController();
  bool _isDoctorLinking  = false;
  String? _linkedDoctorName;

  Map<String, dynamic>? _data;
  Map<String, dynamic>? _caregiverData;
  bool _isLoading = true;
  bool _isSaving  = false;
  File? _localImage;

  @override
  void initState() { super.initState(); _load(); }

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
          _isLoading = false;
        });
      }
      final linkedTo = d?['linked_to'] as String?;
      if (linkedTo != null) {
        final cd = await _supabase.from('users').select('full_name, avatar_url, role').eq('id', linkedTo).maybeSingle();
        if (mounted) setState(() => _caregiverData = cd);
      } else {
        if (mounted) setState(() => _caregiverData = null);
      }
      final doctorCode = d?['doctor_code'] as String?;
      if (doctorCode != null && doctorCode.isNotEmpty) {
        final doc = await _supabase.from('users').select('full_name').eq('short_code', doctorCode).maybeSingle();
        if (mounted) setState(() => _linkedDoctorName = doc?['full_name'] as String? ?? doctorCode);
      }
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _linkDoctor() async {
    final t = AppLocalizations.of(context)!;
    final code = _doctorCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) { _snack(t.patient_code_required); return; }
    if (code.length != 8) { _snack(t.patient_code_length); return; }
    setState(() => _isDoctorLinking = true);
    try {
      final doctor = await _supabase.from('users').select('id, full_name, role, short_code').eq('short_code', code).maybeSingle();
      if (doctor == null) { _snack(t.patient_doctor_not_found); return; }
      if (doctor['role'] != 'doctor') { _snack(t.patient_not_doctor_role); return; }
      final id = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'doctor_code': code}).eq('id', id);
      setState(() { _data = {...?_data, 'doctor_code': code}; _linkedDoctorName = doctor['full_name'] as String? ?? code; _doctorCodeCtrl.clear(); });
      _snack(t.patient_doctor_linked, isError: false);
    } catch (_) { _snack(AppLocalizations.of(context)!.patient_link_error); }
    finally { if (mounted) setState(() => _isDoctorLinking = false); }
  }

  Future<void> _unlinkDoctor() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(t.patient_doctor_unlink), content: Text(t.patient_doctor_unlink_confirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.unlink, style: const TextStyle(color: Colors.red))),
      ],
    ));
    if (ok != true) return;
    try {
      final id = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'doctor_code': null}).eq('id', id);
      setState(() { _data = {...?_data, 'doctor_code': null}; _linkedDoctorName = null; });
      _snack(t.patient_doctor_unlinked, isError: false);
    } catch (_) { _snack(AppLocalizations.of(context)!.patient_unlink_error); }
  }

  Future<void> _pickImage() async {
    final t = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt, color: Color(0xFF1D9E75)), title: Text(t.caregiver_camera), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library, color: Color(0xFF1D9E75)), title: Text(t.caregiver_gallery), onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (picked == null) return;
    setState(() => _localImage = File(picked.path));
    try {
      final id = _supabase.auth.currentUser!.id;
      final bytes = await File(picked.path).readAsBytes();
      final path = 'avatars/$id.jpg';
      await _supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase.from('users').update({'avatar_url': url}).eq('id', id);
      setState(() => _data = {...?_data, 'avatar_url': url});
    } catch (_) { _snack(AppLocalizations.of(context)!.patient_image_error); }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack(t.patient_name_required); return; }
    setState(() => _isSaving = true);
    try {
      final id = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'full_name': name}).eq('id', id);
      setState(() => _data = {...?_data, 'full_name': name});
      _snack(t.patient_saved, isError: false);
    } catch (_) { _snack(AppLocalizations.of(context)!.patient_save_error); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(t.logout), content: Text(t.logoutConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.patient_disconnect, style: const TextStyle(color: Colors.red))),
      ],
    ));
    if (ok != true) return;
    await authService.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? Colors.red : const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() { _nameCtrl.dispose(); _doctorCodeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75))));

    final avatarUrl      = _data?['avatar_url'] as String?;
    final linkedTo       = _data?['linked_to'] as String?;
    final isLinked       = linkedTo != null && _caregiverData != null;
    final isDoctorLinked = _linkedDoctorName != null;
    final caregiverName  = (_caregiverData?['full_name'] as String?)?.isNotEmpty == true ? _caregiverData!['full_name'] as String : 'Soignant';
    final myCode = (_supabase.auth.currentUser?.id ?? '').length >= 8 ? _supabase.auth.currentUser!.id.substring(0, 8).toUpperCase() : '—';
    final initials = _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F4),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240, pinned: true,
          backgroundColor: const Color(0xFF1D9E75),
          automaticallyImplyLeading: !widget.isFirstTime,
          leading: widget.isFirstTime ? const SizedBox() : IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          actions: [if (!widget.isFirstTime) IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)])),
              child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 20),
                GestureDetector(onTap: _pickImage, child: Stack(children: [
                  Container(width: 104, height: 104,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14)]),
                    child: CircleAvatar(radius: 50, backgroundColor: const Color(0xFFE1F5EE),
                      backgroundImage: _localImage != null ? FileImage(_localImage!) as ImageProvider : (avatarUrl != null ? NetworkImage(avatarUrl) : null),
                      child: (_localImage == null && avatarUrl == null) ? Text(initials, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75))) : null)),
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF1D9E75), size: 16))),
                ])),
                const SizedBox(height: 10),
                Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Votre Nom', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(t.patient_role, style: const TextStyle(color: Colors.white, fontSize: 12))),
              ])),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          sliver: SliverList(delegate: SliverChildListDelegate([
            if (widget.isFirstTime) ...[
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFE1F5EE), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.waving_hand, color: Color(0xFF1D9E75)), const SizedBox(width: 10),
                  Expanded(child: Text(t.patient_welcome, style: const TextStyle(color: Color(0xFF0F6E56), fontWeight: FontWeight.w600, fontSize: 14))),
                ])),
              const SizedBox(height: 16),
            ],

           
            _card(icon: Icons.person_outline, color: const Color(0xFF1D9E75), title: t.patient_full_name,
              child: Column(children: [
                TextField(controller: _nameCtrl, onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: t.patient_name_hint, prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF1D9E75)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(_isSaving ? t.caregiver_saving : t.patient_save_name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ])),
            const SizedBox(height: 14),

            
            _card(icon: Icons.info_outline, color: Colors.blue, title: t.patient_account_info,
              child: _infoRow(Icons.email_outlined, t.caregiver_email, _supabase.auth.currentUser?.email ?? '—')),
            const SizedBox(height: 14),

           
            _card(icon: Icons.qr_code_2, color: Colors.orange, title: t.patient_my_code,
              child: Column(children: [
                Text(t.patient_code_hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: myCode)); _snack(t.patient_code_copied, isError: false); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.orange.shade300, width: 1.5)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(myCode, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 8)),
                      const SizedBox(width: 10), const Icon(Icons.copy_rounded, color: Colors.orange, size: 20),
                    ])),
                ),
              ])),
            const SizedBox(height: 14),

           
            _card(icon: Icons.medical_services_outlined, color: const Color(0xFF6C63FF), title: t.patient_doctor_section,
              child: isDoctorLinked
                  ? Column(children: [
                      Container(padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFEEEDFE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
                        child: Row(children: [
                          Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.medical_services, color: Color(0xFF6C63FF), size: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Dr. $_linkedDoctorName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF3C3489))),
                            Text(t.doctor_linked_label, style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
                          ])),
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                        ])),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _unlinkDoctor,
                        icon: const Icon(Icons.link_off, color: Colors.red, size: 16),
                        label: Text(t.patient_doctor_unlink, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.patient_doctor_code_label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextField(controller: _doctorCodeCtrl, textCapitalization: TextCapitalization.characters, maxLength: 8,
                        decoration: InputDecoration(hintText: t.patient_doctor_hint, counterText: '',
                          prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF6C63FF)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)))),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(
                        onPressed: _isDoctorLinking ? null : _linkDoctor,
                        icon: _isDoctorLinking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.link, color: Colors.white),
                        label: Text(_isDoctorLinking ? t.patient_linking : t.patient_link_doctor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      )),
                    ])),
            const SizedBox(height: 14),

            
            _card(icon: Icons.link_rounded, color: const Color(0xFF1D9E75), title: t.patient_linked_caregiver,
              child: isLinked
                  ? ListTile(contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: _caregiverData!['avatar_url'] != null ? NetworkImage(_caregiverData!['avatar_url']) : null,
                        child: _caregiverData!['avatar_url'] == null ? const Icon(Icons.person) : null),
                      title: Text(caregiverName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(t.patient_caregiver_sub),
                      trailing: const Icon(Icons.check_circle, color: Colors.green))
                  : LinkByCodeWidget(supabase: _supabase, currentRole: 'patient', onLinked: _load)),
            const SizedBox(height: 24),

           
            if (widget.isFirstTime)
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home())),
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                label: Text(t.patient_go_home, style: const TextStyle(color: Colors.white, fontSize: 15)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              )),

            if (!widget.isFirstTime) ...[
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(t.patient_disconnect, style: const TextStyle(color: Colors.red, fontSize: 15)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ],
          ])),
        ),
      ]),
    );
  }

  Widget _card({required IconData icon, required Color color, required String title, required Widget child}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ]),
        const SizedBox(height: 14), child,
      ]));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, color: Colors.grey, size: 18), const SizedBox(width: 10), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))]);
  }
}


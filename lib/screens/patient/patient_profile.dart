import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/services/auth/auth_service.dart';
import 'package:safemind/screens/login.dart';
import 'package:safemind/screens/patient/home.dart';
import 'package:safemind/widgets/link_by_code_widget.dart';

class PatientProfileScreen extends StatefulWidget {
  final bool isFirstTime;
  const PatientProfileScreen({super.key, this.isFirstTime = false});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _supabase = Supabase.instance.client;
  final authService = AuthService();
  final _nameCtrl = TextEditingController();

  Map<String, dynamic>? _data;
  Map<String, dynamic>? _caregiverData; 
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
      final d = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

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
        final cd = await _supabase
            .from('users')
            .select('full_name, avatar_url, role')
            .eq('id', linkedTo)
            .maybeSingle();
        if (mounted) setState(() => _caregiverData = cd);
      } else {
        if (mounted) setState(() => _caregiverData = null);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1D9E75)),
              title: const Text("Ouvrir l'appareil photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1D9E75)),
              title: const Text("Choisir depuis la galerie"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() => _localImage = File(picked.path));

    try {
      final id = _supabase.auth.currentUser!.id;
      final bytes = await File(picked.path).readAsBytes();
      final path = 'avatars/$id.jpg';

      await _supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase.from('users').update({'avatar_url': url}).eq('id', id);
      setState(() => _data = {...?_data, 'avatar_url': url});
    } catch (_) {
      _snack("Erreur lors de l'importation de l'image");
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Veuillez entrer votre nom');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final id = _supabase.auth.currentUser!.id;
      await _supabase.from('users').update({'full_name': name}).eq('id', id);
      setState(() => _data = {...?_data, 'full_name': name});
      _snack(' Enregistré avec succès', isError: false);
    } catch (_) {
      _snack("Erreur lors de l'enregistrement");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnexion',
                  style: TextStyle(color: Colors.red))),
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

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75))));
    }

    final avatarUrl = _data?['avatar_url'] as String?;
    final linkedTo = _data?['linked_to'] as String?;
    final isLinked = linkedTo != null && _caregiverData != null;

   
    final caregiverName =
        (_caregiverData?['full_name'] as String?)?.isNotEmpty == true
            ? _caregiverData!['full_name'] as String
            : 'Soignant (non nommé)';

    final myCode = (_supabase.auth.currentUser?.id ?? '').length >= 8
        ? _supabase.auth.currentUser!.id.substring(0, 8).toUpperCase()
        : '—';
    final initials =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F4),
      body: CustomScrollView(
        slivers: [
         
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF1D9E75),
            automaticallyImplyLeading: !widget.isFirstTime,
            leading: widget.isFirstTime
                ? const SizedBox()
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
            actions: [
              if (!widget.isFirstTime)
                IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 14)
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFE1F5EE),
                              backgroundImage: _localImage != null
                                  ? FileImage(_localImage!) as ImageProvider
                                  : (avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null),
                              child: (_localImage == null && avatarUrl == null)
                                  ? Text(initials,
                                      style: const TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D9E75)))
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4)
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Color(0xFF1D9E75), size: 16),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text
                              : 'Votre Nom',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Patient',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              if (widget.isFirstTime) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF1D9E75).withOpacity(0.4)),
                  ),
                  child: Row(children: const [
                    Icon(Icons.waving_hand, color: Color(0xFF1D9E75)),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      'Bienvenue ! Complétez votre profil pour continuer',
                      style: TextStyle(
                          color: Color(0xFF0F6E56),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

             
              _card(
                icon: Icons.person_outline,
                color: const Color(0xFF1D9E75),
                title: 'Nom Complet',
               child: Column(
  children: [
    TextField(
      controller: _nameCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Entrez votre nom complet...',
        prefixIcon: const Icon(
          Icons.edit_outlined,
          color: Color(0xFF1D9E75),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1D9E75),
            width: 2,
          ),
        ),
      ),
    ),

    const SizedBox(height: 12),

    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving
            ? null
            : () async {
                final name = _nameCtrl.text.trim();

                if (name.isEmpty) {
                  _snack('Veuillez entrer votre nom');
                  return;
                }

                setState(() => _isSaving = true);

                try {
                  final id = _supabase.auth.currentUser!.id;

                  await _supabase.from('users').update({
                    'full_name': name,
                  }).eq('id', id);

                  setState(() {
                    _data = {
                      ...?_data,
                      'full_name': name,
                    };
                  });

                  _snack('Nom enregistré ', isError: false);
                } catch (_) {
                  _snack("Erreur lors de l'enregistrement");
                } finally {
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                }
              },
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_rounded,
                color: Colors.white),
        label: Text(
          _isSaving
              ? 'Enregistrement...'
              : 'Sauvegarder le nom',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D9E75),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  ],
),
              ),
              const SizedBox(height: 14),

             
              _card(
                icon: Icons.info_outline,
                color: Colors.blue,
                title: 'Informations du Compte',
                child: _infoRow(Icons.email_outlined, 'Email',
                    _supabase.auth.currentUser?.email ?? '—'),
              ),
              const SizedBox(height: 14),

            
              _card(
                icon: Icons.qr_code_2,
                color: Colors.orange,
                title: 'Mon Code de Liaison',
                child: Column(children: [
                  const Text(
                    'Partagez ce code avec votre soignant pour qu\'il puisse vous lier',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: myCode));
                      _snack('Code copié ', isError: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.orange.shade300, width: 1.5),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(myCode,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orange,
                                    letterSpacing: 8)),
                            const SizedBox(width: 10),
                            const Icon(Icons.copy_rounded,
                                color: Colors.orange, size: 20),
                          ]),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

             
              _card(
                icon: Icons.link_rounded,
                color: const Color(0xFF1D9E75),
                title: 'Soignant Lié',
                child: isLinked
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage:
                              _caregiverData!['avatar_url'] != null
                                  ? NetworkImage(
                                      _caregiverData!['avatar_url'])
                                  : null,
                          child: _caregiverData!['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                       
                        title: Text(caregiverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: const Text('Aide soignant'),
                        trailing: const Icon(Icons.check_circle,
                            color: Colors.green),
                      )
                    : LinkByCodeWidget(
                        supabase: _supabase,
                        currentRole: 'patient',
                        onLinked: _load,
                      ),
              ),
              const SizedBox(height: 24),

           
              if (!widget.isFirstTime) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded,
                            color: Colors.white),
                    label: Text(
                        _isSaving
                            ? 'Enregistrement...'
                            : 'Enregistrer les modifications',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

            
              if (widget.isFirstTime)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final linked = _data?['linked_to'] as String?;
                      if (linked != null && linked.isNotEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const Home()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Veuillez d\'abord lier un soignant'),
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.home_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Aller à l\'accueil',
                      style:
                          TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

              if (!widget.isFirstTime) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Déconnexion',
                        style: TextStyle(
                            color: Colors.red, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ])),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.grey, size: 18),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
  }
}

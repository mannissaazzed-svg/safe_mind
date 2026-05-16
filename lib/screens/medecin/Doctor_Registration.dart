import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';

// ═══════════════════════════════════════════════════════
// Page d'inscription médecin — SafeMind
// ═══════════════════════════════════════════════════════

class MedecinRegistrationPage extends StatefulWidget {
  const MedecinRegistrationPage({super.key});

  @override
  State<MedecinRegistrationPage> createState() => _MedecinRegistrationPageState();
}

class _MedecinRegistrationPageState extends State<MedecinRegistrationPage> {
  final _formKey    = GlobalKey<FormState>();
  final _supabase   = Supabase.instance.client;
  final _picker     = ImagePicker();

  // Controllers
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _licenseCtrl  = TextEditingController();

  String? _speciality;
  File?   _photoFile;
  bool    _isLoading = false;
  int     _currentStep = 0;

  static const Color _primary = Color(0xFF6C63FF);

  final List<String> _specialities = [
    'Neurologue',
    'Généraliste',
    'Psychiatre',
    'Gériatre',
    'Autre',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _hospitalCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  // ── Choisir photo ──────────────────────────────────
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Photo de profil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceOption(Icons.camera_alt_outlined, 'Caméra',
                    const Color(0xFF0EA5E9), ImageSource.camera),
                _sourceOption(Icons.photo_library_outlined, 'Galerie',
                    const Color(0xFF8B5CF6), ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    if (source == null) return;
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img != null) setState(() => _photoFile = File(img.path));
  }

  Widget _sourceOption(
      IconData icon, String label, Color color, ImageSource value) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Soumettre ──────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_speciality == null) {
      _showError('Veuillez choisir une spécialité.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      String? avatarUrl;

      // Upload photo
      if (_photoFile != null) {
        final name = 'medecin_$userId.jpg';
        await _supabase.storage.from('avatars').upload(
          name, _photoFile!,
          fileOptions: const FileOptions(upsert: true),
        );
        avatarUrl = _supabase.storage.from('avatars').getPublicUrl(name);
        // Mettre à jour avatar dans users
        await _supabase.from('users')
            .update({'avatar_url': avatarUrl}).eq('id', userId);
      }

      // Enregistrer dans doctors
      await _supabase.from('doctors').upsert({
        'id': userId,
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'hospital': _hospitalCtrl.text.trim(),
        'license_number': _licenseCtrl.text.trim(),
        'speciality': _speciality,
        'avatar_url': avatarUrl,
      });

      // Mettre à jour name dans users
      await _supabase.from('users').update({
        'name': _nameCtrl.text.trim(),
        'full_name': _nameCtrl.text.trim(),
      }).eq('id', userId);

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MedecinDashboardPage()));
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: Stack(
        children: [
          // ── Fond dégradé ──────────────────────────
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Vérification Professionnelle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Complétez votre profil médical',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Formulaire ────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ── Photo ──────────────────
                          _buildPhotoSection(),
                          const SizedBox(height: 20),

                          // ── Infos personnelles ──────
                          _buildCard(
                            title: 'Informations personnelles',
                            icon: Icons.person_outline,
                            children: [
                              _buildField(
                                controller: _nameCtrl,
                                hint: 'Nom et Prénom',
                                icon: Icons.badge_outlined,
                                validator: (v) => v!.isEmpty
                                    ? 'Champ obligatoire' : null,
                              ),
                              _buildField(
                                controller: _phoneCtrl,
                                hint: 'Numéro de téléphone',
                                icon: Icons.phone_outlined,
                                type: TextInputType.phone,
                                validator: (v) => v!.length < 8
                                    ? 'Numéro invalide' : null,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Infos professionnelles ──
                          _buildCard(
                            title: 'Informations professionnelles',
                            icon: Icons.medical_services_outlined,
                            children: [
                              _buildField(
                                controller: _hospitalCtrl,
                                hint: 'Hôpital / Clinique',
                                icon: Icons.local_hospital_outlined,
                                validator: (v) => v!.isEmpty
                                    ? 'Champ obligatoire' : null,
                              ),
                              _buildField(
                                controller: _licenseCtrl,
                                hint: 'Numéro de licence',
                                icon: Icons.verified_user_outlined,
                                validator: (v) => v!.isEmpty
                                    ? 'Champ obligatoire' : null,
                              ),
                              _buildDropdown(),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Bouton confirmer ────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Confirmer et continuer',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section photo ──────────────────────────────────
  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: ClipOval(
                  child: _photoFile != null
                      ? Image.file(_photoFile!, fit: BoxFit.cover)
                      : Container(
                          color: _primary.withOpacity(0.1),
                          child: const Icon(Icons.person,
                              size: 50, color: _primary),
                        ),
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                      color: _primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _photoFile != null ? 'Photo sélectionnée ✓' : 'Ajouter une photo',
            style: TextStyle(
              color: _photoFile != null
                  ? const Color(0xFF4ADE80) : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card section ───────────────────────────────────
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Champ texte ────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _primary, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  // ── Dropdown spécialité ────────────────────────────
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _speciality,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.local_hospital_outlined,
            color: _primary, size: 20),
        hintText: 'Spécialité',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
      items: _specialities.map((s) => DropdownMenuItem(
        value: s,
        child: Text(s),
      )).toList(),
      onChanged: (v) => setState(() => _speciality = v),
    );
  }
}
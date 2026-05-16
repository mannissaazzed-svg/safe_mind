import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════
// Page Mon Profil & Code — SafeMind
// Fonctionnalités :
//   - Voir et copier son code de connexion
//   - Modifier son nom
//   - Ajouter / changer sa photo de profil
//   - Régénérer son code
// ═══════════════════════════════════════════════════════

class MyCodePage extends StatefulWidget {
  const MyCodePage({super.key});

  @override
  State<MyCodePage> createState() => _MyCodePageState();
}

class _MyCodePageState extends State<MyCodePage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _picker   = ImagePicker();

  String? _code;
  String? _name;
  String? _role;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving  = false;
  bool _copied    = false;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  static const Color _primary = Color(0xFF6C63FF);

  static const Map<String, Color> _roleColors = {
    'patient':   Color(0xFF0EA5E9),
    'doctor':    Color(0xFF10B981),
    'assistant': Color(0xFF8B5CF6),
    'soignant':  Color(0xFF10B981),
  };

  static const Map<String, IconData> _roleIcons = {
    'patient':   Icons.personal_injury_outlined,
    'doctor':    Icons.medical_services_outlined,
    'assistant': Icons.support_agent_outlined,
    'soignant':  Icons.medical_services_outlined,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchMyProfile();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // DONNÉES
  // ══════════════════════════════════════════════════════

  Future<void> _fetchMyProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data   = await _supabase
          .from('users')
          .select('connection_code, name, full_name, role, avatar_url')
          .eq('id', userId)
          .single();

      if (data['connection_code'] == null) {
        await _generateCode(userId);
        return;
      }

      setState(() {
        _code      = data['connection_code'];
        _name      = data['name'] ?? data['full_name'] ?? '';
        _role      = data['role'] ?? 'patient';
        _avatarUrl = data['avatar_url'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur fetchMyProfile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCode(String userId) async {
    final ts   = DateTime.now().millisecondsSinceEpoch.toString();
    final code = ('$userId$ts').hashCode.abs()
        .toRadixString(36).toUpperCase()
        .padLeft(8, '0').substring(0, 8);
    await _supabase.from('users')
        .update({'connection_code': code}).eq('id', userId);
    await _fetchMyProfile();
  }

  Future<void> _saveName(String newName) async {
    if (newName.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _supabase.from('users').update({
        'name': newName.trim(),
        'full_name': newName.trim(),
      }).eq('id', _supabase.auth.currentUser!.id);
      setState(() => _name = newName.trim());
      _showSuccess('Nom mis à jour !');
    } catch (_) {
      _showError('Erreur lors de la sauvegarde.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changeAvatar(ImageSource source) async {
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img == null) return;
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final name   = 'avatar_$userId.jpg';
      await _supabase.storage.from('avatars').upload(
        name, File(img.path),
        fileOptions: const FileOptions(upsert: true),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(name);
      await _supabase.from('users')
          .update({'avatar_url': url}).eq('id', userId);
      setState(() =>
          _avatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}');
      _showSuccess('Photo mise à jour !');
    } catch (_) {
      _showError('Erreur lors du téléchargement.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _regenerateCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nouveau code ?'),
        content: const Text(
          'Votre ancien code ne fonctionnera plus.\nLes liaisons existantes ne seront pas affectées.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Régénérer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    await _generateCode(_supabase.auth.currentUser!.id);
  }

  Future<void> _copyCode() async {
    if (_code == null) return;
    await Clipboard.setData(ClipboardData(text: _code!));
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Votre nom',
            prefixIcon: const Icon(Icons.person_outline, color: _primary),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Enregistrer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) await _saveName(result);
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text('Changer la photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Caméra',
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.pop(context);
                    _changeAvatar(ImageSource.camera);
                  },
                ),
                _photoOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    _changeAvatar(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: const Color(0xFF4ADE80),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColors[_role?.toLowerCase()] ?? _primary;
    final roleIcon  = _roleIcons[_role?.toLowerCase()]  ?? Icons.person_outline;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Text('Mon Profil',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _regenerateCode,
            tooltip: 'Nouveau code',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Stack(children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildProfileSection(roleColor, roleIcon),
                  const SizedBox(height: 20),
                  _buildCodeSection(),
                  const SizedBox(height: 20),
                  _buildInstructions(),
                  const SizedBox(height: 20),
                  _buildSecurityNote(),
                  const SizedBox(height: 30),
                ]),
              ),
              if (_isSaving)
                const Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(_primary),
                    minHeight: 3,
                  ),
                ),
            ]),
    );
  }

  // ── Section profil ────────────────────────────────
  Widget _buildProfileSection(Color roleColor, IconData roleIcon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        // ── Header dégradé ─────────────────────────
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(children: [
            // ── Avatar ─────────────────────────────
            Transform.translate(
              offset: const Offset(0, -44),
              child: GestureDetector(
                onTap: _showAvatarOptions,
                child: Stack(children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null
                          ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultAvatar(roleColor, roleIcon))
                          : _defaultAvatar(roleColor, roleIcon),
                    ),
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(
                          color: _primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Nom ────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -32),
              child: Column(children: [
                GestureDetector(
                  onTap: _editName,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _name?.isNotEmpty == true
                            ? _name!
                            : 'Appuyez pour ajouter un nom',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _name?.isNotEmpty == true
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, size: 16, color: _primary),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Badge rôle ──────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 14, color: roleColor),
                      const SizedBox(width: 6),
                      Text(_formatRole(_role),
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),

            // ── Boutons photo + nom ─────────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: Row(children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.photo_camera_outlined,
                    label: 'Changer photo',
                    color: const Color(0xFF0EA5E9),
                    onTap: _showAvatarOptions,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Modifier nom',
                    color: _primary,
                    onTap: _editName,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Section code ───────────────────────────────────
  Widget _buildCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vpn_key_outlined, color: _primary, size: 20),
            SizedBox(width: 8),
            Text('Mon code de connexion',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
        const SizedBox(height: 6),
        Text('Partagez ce code pour vous lier à un partenaire',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 20),

        // ── Code animé ────────────────────────────
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _primary.withValues(alpha: 0.25), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildCodeLetters(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Copier ────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _copyCode,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_circle : Icons.copy,
                key: ValueKey(_copied),
                color: Colors.white, size: 20,
              ),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _copied ? 'Copié !' : 'Copier le code',
                key: ValueKey(_copied),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _copied ? const Color(0xFF4ADE80) : _primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Régénérer ─────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _regenerateCode,
            icon: const Icon(Icons.refresh, size: 18, color: _primary),
            label: const Text('Générer un nouveau code',
                style: TextStyle(color: _primary, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: _primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildCodeLetters() {
    if (_code == null) return [];
    return _code!.split('').map((char) {
      final isDigit = int.tryParse(char) != null;
      final color   = isDigit ? _primary : const Color(0xFF0EA5E9);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 34, height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(char,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      );
    }).toList();
  }

  // ── Instructions ───────────────────────────────────
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline, color: _primary, size: 18),
          SizedBox(width: 8),
          Text('Comment utiliser ?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
        ]),
        const SizedBox(height: 14),
        _step('1', 'Partagez ce code avec votre partenaire.'),
        _step('2', 'Il appuie sur 🔗 dans la page Messages.'),
        _step('3', 'Il saisit votre code — vous êtes liés !'),
        _step('4', 'Vous pouvez chatter et vous appeler.'),
      ]),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          margin: const EdgeInsets.only(right: 10, top: 1),
          decoration: const BoxDecoration(
              color: _primary, shape: BoxShape.circle),
          child: Center(
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.4)),
        ),
      ]),
    );
  }

  // ── Note sécurité ──────────────────────────────────
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.security, color: Colors.orange.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sécurité',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                'Partagez uniquement avec des personnes de confiance.',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    height: 1.4),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _defaultAvatar(Color color, IconData icon) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(child: Icon(icon, color: color, size: 40)),
    );
  }

  String _formatRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'patient':   return 'Patient';
      case 'doctor':    return 'Médecin';
      case 'assistant': return 'Assistant';
      case 'soignant':  return 'Soignant';
      default:          return role ?? 'Utilisateur';
    }
  }
}
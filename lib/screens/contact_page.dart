import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safemind/screens/chat_page.dart';
import 'package:safemind/screens/group_chat_page.dart';
import 'package:safemind/screens/Incoming_Call_UI.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  late TabController _tabController;

  StreamSubscription? _callSubscription;
  bool _callDialogShown = false;

  String get _myId => _supabase.auth.currentUser!.id;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _bg = Color(0xFFF5F4FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerDonnees();
    _ecouterAppelsEntrants();
    _setOnline(true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _callSubscription?.cancel();
    _setOnline(false);
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════════

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    await Future.wait([_chargerContacts(), _chargerGroupes()]);
    setState(() => _isLoading = false);
  }

  Future<void> _chargerContacts() async {
    try {
      final liens = await _supabase
          .from('contacts')
          .select('contact_id')
          .eq('user_id', _myId);

      if ((liens as List).isEmpty) {
        setState(() => _contacts = []);
        return;
      }

      final ids = liens.map((l) => l['contact_id'].toString()).toList();

      final data = await _supabase
          .from('users')
          .select('id, name, full_name, role, avatar_url, is_online, last_seen')
          .inFilter('id', ids);

      setState(() => _contacts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('ERREUR CONTACTS: $e');
    }
  }

  Future<void> _chargerGroupes() async {
    try {
      // 1. جلب group_id حيث أنا عضو
      final memberships = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', _myId);

      debugPrint('Memberships: $memberships');

      if ((memberships as List).isEmpty) {
        setState(() => _groups = []);
        return;
      }

      final groupIds = memberships
          .map((m) => m['group_id'].toString())
          .toSet()
          .toList();

      debugPrint('Group IDs: $groupIds');

      // 2. جلب تفاصيل المجموعات
      final data = await _supabase
          .from('groups')
          .select('id, name, description, avatar_url, created_by, created_at')
          .inFilter('id', groupIds);

      debugPrint('Groups: $data');

      // 3. عدد الأعضاء
      final groupsWithCount = await Future.wait(
        (data as List).map((g) async {
          final count = await _supabase
              .from('group_members')
              .select('user_id')
              .eq('group_id', g['id']);
          return {...g, 'member_count': (count as List).length};
        }),
      );

      setState(
          () => _groups = List<Map<String, dynamic>>.from(groupsWithCount));
    } catch (e) {
      debugPrint('ERREUR GROUPES: $e');
    }
  }

  Future<void> _setOnline(bool status) async {
    try {
      await _supabase.from('users').update({
        'is_online': status,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', _myId);
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════
  // APPELS ENTRANTS
  // ══════════════════════════════════════════════════════

  void _ecouterAppelsEntrants() {
    _callSubscription = _supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', _myId)
        .order('created_at', ascending: false)
        .listen((data) {
          if (!mounted) return;
          final recent = data.where((c) {
            if (c['status'] != 'ringing') return false;
            final created = DateTime.tryParse(c['created_at'] ?? '');
            if (created == null) return false;
            return DateTime.now().difference(created).inSeconds < 30;
          }).toList();

          if (recent.isNotEmpty && !_callDialogShown) {
            _callDialogShown = true;
            _afficherAppelEntrant(recent.first);
          }
        });
  }

  void _afficherAppelEntrant(Map<String, dynamic> call) {
    final caller = _contacts.firstWhere(
      (c) => c['id'] == call['caller_id'],
      orElse: () => {},
    );
    final callerName = caller['name'] ?? caller['full_name'] ?? 'Appelant';
    final callerAvatar = caller['avatar_url'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallPage(
          channelId: call['channel_id'],
          callId: call['id'].toString(),
          appId: 'feaef859a6c740ee9880322144128c96',
          type: call['type'] ?? 'audio',
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      ),
    ).then((_) => _callDialogShown = false);
  }

  // ══════════════════════════════════════════════════════
  // AJOUTER UN CONTACT
  // ══════════════════════════════════════════════════════

  Future<void> _ajouterContact() async {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ajouter un contact',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Entrez le code de connexion de la personne',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Code de connexion',
                  hintText: 'Ex: ABC123',
                  prefixIcon: const Icon(Icons.person_add_outlined,
                      color: _primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    if (code.isEmpty) return;
                    Navigator.pop(context);
                    await _effectuerAjout(code);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ajouter le contact',
                      style:
                          TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _effectuerAjout(String code) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final res = await _supabase
          .from('users')
          .select('id, name, full_name')
          .eq('connection_code', code)
          .maybeSingle();

      if (!mounted) return;
      Navigator.pop(context);

      if (res == null) {
        _afficherErreur('Code introuvable. Verifiez et reessayez.');
        return;
      }

      final foreignId = res['id'].toString();

      if (foreignId == _myId) {
        _afficherErreur('Vous ne pouvez pas vous ajouter vous-meme.');
        return;
      }

      final foreignName = res['name'] ?? res['full_name'] ?? 'Contact';

      final existe = await _supabase
          .from('contacts')
          .select('id')
          .eq('user_id', _myId)
          .eq('contact_id', foreignId)
          .maybeSingle();

      if (existe != null) {
        _afficherErreur('$foreignName est deja dans vos contacts.');
        return;
      }

      await _supabase.from('contacts').insert({
        'user_id': _myId,
        'contact_id': foreignId,
      });

      await _supabase.from('contacts').insert({
        'user_id': foreignId,
        'contact_id': _myId,
      });

      _afficherSucces('$foreignName ajoute a vos contacts !');
      await _chargerDonnees();
    } catch (e) {
      debugPrint('ERREUR AJOUT: $e');
      if (mounted) Navigator.pop(context);
      _afficherErreur('Erreur: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════
  // CREER UN GROUPE
  // ══════════════════════════════════════════════════════

  Future<void> _creerGroupe() async {
    if (_contacts.isEmpty) {
      _afficherErreur(
          'Ajoutez d\'abord des contacts pour creer un groupe.');
      return;
    }

    final nomController = TextEditingController();
    final descController = TextEditingController();
    final Set<String> membresSel = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Creer un groupe',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom du groupe',
                    prefixIcon:
                        const Icon(Icons.group_outlined, color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: const Icon(Icons.description_outlined,
                        color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Choisir des membres',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (_, i) {
                      final c = _contacts[i];
                      final id = c['id'].toString();
                      final nom =
                          (c['name'] ?? c['full_name'] ?? 'Contact')
                              .toString();
                      final sel = membresSel.contains(id);
                      return CheckboxListTile(
                        dense: true,
                        value: sel,
                        activeColor: _primary,
                        title: Text(nom),
                        secondary: _buildMiniAvatar(c),
                        onChanged: (v) {
                          setModalState(() {
                            if (v == true) {
                              membresSel.add(id);
                            } else {
                              membresSel.remove(id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nom = nomController.text.trim();
                      if (nom.isEmpty) {
                        _afficherErreur('Entrez un nom pour le groupe.');
                        return;
                      }
                      if (membresSel.isEmpty) {
                        _afficherErreur(
                            'Selectionnez au moins un membre.');
                        return;
                      }
                      Navigator.pop(context);
                      await _effectuerCreationGroupe(
                          nom, descController.text.trim(), membresSel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Creer le groupe',
                        style: TextStyle(
                            fontSize: 15, color: Colors.white)),
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

  Future<void> _effectuerCreationGroupe(
      String nom, String desc, Set<String> membres) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      // 1. إنشاء المجموعة
      final groupe = await _supabase
          .from('groups')
          .insert({
            'name': nom,
            'description': desc.isEmpty ? null : desc,
            'created_by': _myId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final groupId = groupe['id'].toString();
      debugPrint('Groupe cree ID: $groupId');

      // 2. إضافة المشرف في جدول group_members
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': _myId,
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. إضافة الأعضاء في جدول group_members
      for (final memberId in membres) {
        await _supabase.from('group_members').insert({
          'group_id': groupId,
          'user_id': memberId,
          'role': 'member',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('Membres ajoutes: ${membres.length + 1}');

      if (mounted) {
        Navigator.pop(context);
        _afficherSucces(
            'Groupe "$nom" cree avec ${membres.length + 1} membres !');
        await Future.delayed(const Duration(milliseconds: 500));
        await _chargerDonnees();
      }
    } catch (e) {
      debugPrint('ERREUR CREATION GROUPE: $e');
      if (mounted) Navigator.pop(context);
      _afficherErreur('Erreur: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════
  // APPELS SORTANTS
  // ══════════════════════════════════════════════════════

  Future<void> _initierAppel(
      Map<String, dynamic> contact, String type) async {
    try {
      final channelId =
          'call_${_myId}_${DateTime.now().millisecondsSinceEpoch}';
      await _supabase.from('calls').insert({
        'caller_id': _myId,
        'receiver_id': contact['id'],
        'channel_id': channelId,
        'type': type,
        'status': 'ringing',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _afficherErreur('Impossible d\'initier l\'appel.');
    }
  }

  // ══════════════════════════════════════════════════════
  // SNACKBARS
  // ══════════════════════════════════════════════════════

  void _afficherErreur(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _afficherSucces(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFF4ADE80),
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListeContacts(),
                _buildListeGroupes(),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      title: const Column(
        children: [
          Text('SafeMind',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('Messages',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Text('Contacts (${_contacts.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 18),
                const SizedBox(width: 6),
                Text('Groupes (${_groups.length})'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.refresh, size: 20, color: Colors.white),
          ),
          onPressed: _chargerDonnees,
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) {
        final isContacts = _tabController.index == 0;
        return FloatingActionButton.extended(
          backgroundColor: _primary,
          icon: Icon(isContacts
              ? Icons.person_add_outlined
              : Icons.group_add_outlined),
          label: Text(isContacts ? 'Ajouter' : 'Creer groupe'),
          onPressed: isContacts ? _ajouterContact : _creerGroupe,
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // LISTE CONTACTS
  // ══════════════════════════════════════════════════════

  Widget _buildListeContacts() {
    if (_contacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        titre: 'Aucun contact',
        sousTitre:
            'Appuyez sur "Ajouter" pour\najouter un contact par code',
        boutonLabel: 'Ajouter un contact',
        onTap: _ajouterContact,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _chargerDonnees,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _contacts.length,
        itemBuilder: (_, i) => _buildContactItem(_contacts[i]),
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact) {
    final nom =
        (contact['name'] ?? contact['full_name'] ?? 'Contact').toString();
    final role = (contact['role'] ?? '').toString();
    final isOnline = contact['is_online'] == true;
    final lastSeen = contact['last_seen']?.toString();
    final convId =
        _genererIdConversation(_myId, contact['id'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            _buildAvatar(contact, nom, 48),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(nom,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1A1A2E))),
        subtitle: Text(
          role.isNotEmpty
              ? role
              : (isOnline ? 'En ligne' : _formatLastSeen(lastSeen)),
          style: TextStyle(
            color: isOnline && role.isEmpty
                ? const Color(0xFF4ADE80)
                : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconAction(
              icon: Icons.chat_bubble_outline,
              color: _primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversationId: convId,
                    receiverId: contact['id'].toString(),
                    receiverName: nom,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildIconAction(
              icon: Icons.call_outlined,
              color: const Color(0xFF4ADE80),
              onTap: () => _initierAppel(contact, 'audio'),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: convId,
              receiverId: contact['id'].toString(),
              receiverName: nom,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // LISTE GROUPES
  // ══════════════════════════════════════════════════════

  Widget _buildListeGroupes() {
    if (_groups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        titre: 'Aucun groupe',
        sousTitre:
            'Appuyez sur "Creer groupe" pour\ndemarrer une conversation de groupe',
        boutonLabel: 'Creer un groupe',
        onTap: _creerGroupe,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _chargerDonnees,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _groups.length,
        itemBuilder: (_, i) => _buildGroupeItem(_groups[i]),
      ),
    );
  }

  Widget _buildGroupeItem(Map<String, dynamic> groupe) {
    final nom = (groupe['name'] ?? 'Groupe').toString();
    final desc = (groupe['description'] ?? '').toString();
    final memberCount = groupe['member_count'] ?? 0;
    final avatarUrl = groupe['avatar_url']?.toString();
    final isAdmin = groupe['created_by'].toString() == _myId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: avatarUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.group, color: _primary, size: 26),
                  ),
                )
              : const Icon(Icons.group, color: _primary, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
            ),
            if (isAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Admin',
                    style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: Text(
          desc.isNotEmpty
              ? desc
              : '$memberCount membre${memberCount > 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('$memberCount',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatPage(
              groupId: groupe['id'].toString(),
              groupName: nom,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════════════════════

  Widget _buildEmptyState({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required String boutonLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: _primary),
            ),
            const SizedBox(height: 24),
            Text(titre,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            Text(sousTitre,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 18),
              label: Text(boutonLabel,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  Widget _buildAvatar(
      Map<String, dynamic> contact, String nom, double size) {
    final avatarUrl = contact['avatar_url']?.toString();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _defaultAvatar(nom, size))
            : _defaultAvatar(nom, size),
      ),
    );
  }

  Widget _buildMiniAvatar(Map<String, dynamic> contact) {
    final nom =
        (contact['name'] ?? contact['full_name'] ?? '?').toString();
    final avatarUrl = contact['avatar_url']?.toString();
    return CircleAvatar(
      radius: 18,
      backgroundColor: _primary.withOpacity(0.2),
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _primary, fontWeight: FontWeight.bold))
          : null,
    );
  }

  Widget _defaultAvatar(String nom, double size) {
    return Container(
      width: size,
      height: size,
      color: _primary.withOpacity(0.2),
      child: Center(
        child: Text(
          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
          style: TextStyle(
            color: _primary,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _genererIdConversation(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return ids.join('_');
  }

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return 'Hors ligne';
    final dt = DateTime.tryParse(lastSeen)?.toLocal();
    if (dt == null) return 'Hors ligne';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'A l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}

// contact_page.dart
// ✅ جهات الاتصال التلقائية من linked_to
// ✅ الطبيب يرى مرضاه تلقائياً
// ✅ إضافة بـ short_code (8 أحرف من user_id)
// ✅ بدون connection_code

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safemind/screens/chat_page.dart';
import 'package:safemind/screens/group_chat_page.dart';
import 'package:safemind/screens/Incoming_Call.dart';
import 'package:safemind/screens/call_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _autoContacts  = []; // تلقائي من linked_to
  List<Map<String, dynamic>> _addedContacts = []; // مضافون بالكود
  List<Map<String, dynamic>> _groups         = [];
  bool _isLoading = true;
  late TabController _tabController;

  StreamSubscription? _callSub;
  bool _callDialogShown = false;

  String get _myId => _supabase.auth.currentUser!.id;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _bg      = Color(0xFFF5F4FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
    _listenIncomingCalls();
    _setOnline(true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _callSub?.cancel();
    _setOnline(false);
    super.dispose();
  }

  // ══════════════════════════════════════════════════
  // CHARGEMENT
  // ══════════════════════════════════════════════════

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAutoContacts(),
      _loadAddedContacts(),
      _loadGroups(),
    ]);
    setState(() => _isLoading = false);
  }

  // ✅ جهات تلقائية من linked_to و patients
  Future<void> _loadAutoContacts() async {
    try {
      final contacts = await CallService().getAutoContacts();
      setState(() => _autoContacts = contacts);
    } catch (e) {
      debugPrint('loadAutoContacts: $e');
    }
  }

  // ✅ جهات مضافون بالكود
  Future<void> _loadAddedContacts() async {
    try {
      final liens = await _supabase
          .from('contacts')
          .select('contact_id')
          .eq('user_id', _myId);

      if ((liens as List).isEmpty) {
        setState(() => _addedContacts = []);
        return;
      }

      final ids = liens.map((l) => l['contact_id'].toString()).toList();
      final data = await _supabase
          .from('users')
          .select('id, name, full_name, role, avatar_url, is_online')
          .inFilter('id', ids);

      setState(() =>
          _addedContacts = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('loadAddedContacts: $e');
    }
  }

  // ✅ جلب المجموعات بدون تكرار البصري
  Future<void> _loadGroups() async {
    try {
      final List<dynamic> data = await _supabase
          .from('group_members')
          .select('''
            group_id,
            groups:group_id (
              id,
              name,
              description,
              avatar_url,
              created_by
            )
          ''')
          .eq('user_id', _myId);

      if (data.isEmpty) {
        setState(() => _groups = []);
        return;
      }

      final List<Map<String, dynamic>> fetchedGroups = [];
      final Set<String> seenGroupIds = {};
      
      for (final item in data) {
        if (item['groups'] != null) {
          final groupData = Map<String, dynamic>.from(item['groups']);
          final groupId = groupData['id'].toString();

          if (seenGroupIds.contains(groupId)) {
            continue;
          }
          seenGroupIds.add(groupId);
          
          final countRes = await _supabase
              .from('group_members')
              .select('user_id')
              .eq('group_id', groupId);
              
          groupData['member_count'] = (countRes as List).length;
          fetchedGroups.add(groupData);
        }
      }

      setState(() => _groups = fetchedGroups);
    } catch (e) {
      debugPrint('Error loading groups: $e');
      setState(() => _groups = []);
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

  // ══════════════════════════════════════════════════
  // APPELS ENTRANTS
  // ══════════════════════════════════════════════════
  void _listenIncomingCalls() {
    _callSub = _supabase
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
        _showIncomingCall(recent.first);
      }
    });
  }

  void _showIncomingCall(Map<String, dynamic> call) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallPage(
          channelId:   call['channel_id'],
          callId:      call['id'].toString(),
          appId:       'feaef859a6c740ee9880322144128c96',
          type:        call['type'] ?? 'audio',
          callerName:  call['caller_name'] ?? 'Appelant',
          callerAvatar: null,
        ),
      ),
    ).then((_) => _callDialogShown = false);
  }

  // ══════════════════════════════════════════════════
  // ✅ AJOUTER PAR SHORT CODE (8 caractères)
  // ══════════════════════════════════════════════════
  Future<void> _addByCode() async {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ajouter un contact',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Entrez le code personnel (8 caractères)\nVisible dans Mon Profil',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: const TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Code personnel',
                  hintText: 'Ex: 6E3B6F79',
                  prefixIcon: const Icon(Icons.person_add_outlined,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final code =
                        codeCtrl.text.trim().toUpperCase();
                    if (code.length < 6) return;
                    Navigator.pop(context);
                    await _doAdd(code);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ajouter',
                      style: TextStyle(
                          fontSize: 15, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doAdd(String code) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final res = await _supabase
          .from('users')
          .select('id, name, full_name')
          .eq('short_code', code)
          .maybeSingle();

      if (!mounted) return;
      Navigator.pop(context);

      if (res == null) {
        _showError('Code introuvable. Vérifiez le code.');
        return;
      }

      final foreignId   = res['id'].toString();
      final foreignName =
          res['name'] ?? res['full_name'] ?? 'Contact';

      if (foreignId == _myId) {
        _showError('Vous ne pouvez pas vous ajouter vous-même.');
        return;
      }

      final exists = await _supabase
          .from('contacts')
          .select('id')
          .eq('user_id', _myId)
          .eq('contact_id', foreignId)
          .maybeSingle();

      if (exists != null) {
        _showError('$foreignName est déjà dans vos contacts.');
        return;
      }

      await _supabase.from('contacts')
          .insert({'user_id': _myId, 'contact_id': foreignId});
      await _supabase.from('contacts')
          .insert({'user_id': foreignId, 'contact_id': _myId});

      _showSuccess('$foreignName ajouté !');
      await _loadAll();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Erreur: $e');
    }
  }

  // ══════════════════════════════════════════════════
  // CRÉER GROUPE
  // ══════════════════════════════════════════════════
  Future<void> _createGroup() async {
    final allContacts = [
      ..._autoContacts,
      ..._addedContacts,
    ];

    if (allContacts.isEmpty) {
      _showError('Ajoutez d\'abord des contacts.');
      return;
    }

    final nomCtrl  = TextEditingController();
    final Set<String> selected = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
              children: [
                const Text('Créer un groupe',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom du groupe *',
                    prefixIcon: const Icon(Icons.group_outlined,
                        color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Membres :',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: allContacts.length,
                    itemBuilder: (_, i) {
                      final c  = allContacts[i];
                      final id = c['id'].toString();
                      final nm = (c['name'] ?? c['full_name'] ??
                              'Contact')
                          .toString();
                      return CheckboxListTile(
                        dense: true,
                        value: selected.contains(id),
                        activeColor: _primary,
                        title: Text(nm),
                        onChanged: (v) => setModal(() {
                          v == true
                              ? selected.add(id)
                              : selected.remove(id);
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nomCtrl.text.trim().isEmpty) return;
                      if (selected.isEmpty) return;
                      Navigator.pop(context);
                      await _doCreateGroup(
                          nomCtrl.text.trim(), selected);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Créer',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ التعديل الجوهري المصحح: إدخال جماعي بدون حقل joined_at لتفادي الأخطاء الحمراء
  Future<void> _doCreateGroup(String name, Set<String> members) async {
    try {
      final groupe = await _supabase
          .from('groups')
          .insert({
            'name':       name,
            'created_by': _myId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final groupId = groupe['id'];

      final List<Map<String, dynamic>> membersToInsert = [];

      // إضافة الأدمن (أنت) بدون حقل joined_at المسبب للخطأ
      membersToInsert.add({
        'group_id': groupId,
        'user_id':  _myId,
        'role':     'admin',
      });

      // إضافة بقية الأعضاء المختارين
      for (final memberId in members) {
        if (memberId != _myId) {
          membersToInsert.add({
            'group_id': groupId,
            'user_id':  memberId,
            'role':     'member',
          });
        }
      }

      // إدراج كل البيانات دفعة واحدة لضمان نجاح العملية
      await _supabase.from('group_members').insert(membersToInsert);

      _showSuccess('Groupe "$name" créé avec succès !');
      await _loadAll();
    } catch (e) {
      debugPrint('Error creating group or inserting members: $e');
      _showError('Erreur lors de la création: $e');
    }
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final allIds = _autoContacts.map((c) => c['id'].toString()).toSet();
    final uniqueAdded = _addedContacts
        .where((c) => !allIds.contains(c['id'].toString()))
        .toList();
    final allContacts = [..._autoContacts, ...uniqueAdded];

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(allContacts.length),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContactsList(allContacts),
                _buildGroupsList(),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(int count) {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      title: Column(children: [
        const Text('Messages',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text('$count contact(s)',
            style: const TextStyle(
                fontSize: 11, color: Colors.white70)),
      ]),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.refresh,
                size: 20, color: Colors.white),
          ),
          onPressed: _loadAll,
        ),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: [
          Tab(text: 'Contacts (${_autoContacts.length + _addedContacts.length})'),
          Tab(text: 'Groupes (${_groups.length})'),
        ],
      ),
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
          label: Text(isContacts ? 'Ajouter' : 'Créer groupe'),
          onPressed: isContacts ? _addByCode : _createGroup,
        );
      },
    );
  }

  // ── Liste contacts ────────────────────────────────
  Widget _buildContactsList(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return _buildEmpty(
        icon: Icons.people_outline,
        title: 'Aucun contact',
        subtitle:
            'Vos contacts liés apparaissent ici automatiquement.\nAjoutez d\'autres par code.',
        btnLabel: 'Ajouter par code',
        onTap: _addByCode,
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c         = contacts[i];
          final isAuto    = i < _autoContacts.length;
          return _buildContactItem(c, isAuto: isAuto);
        },
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact,
      {bool isAuto = false}) {
    final nom = (contact['name'] ??
            contact['full_name'] ??
            'Contact')
        .toString();
    final role     = (contact['role'] ?? '').toString();
    final isOnline = contact['is_online'] == true;
    final convId   =
        _genConvId(_myId, contact['id'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAuto
            ? Border.all(
                color: _primary.withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: Stack(children: [
          _buildAvatar(contact, nom, 48),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 13, height: 13,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF4ADE80)
                    : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          if (isAuto)
            Positioned(
              left: 0, top: 0,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: _primary, shape: BoxShape.circle),
                child: const Icon(Icons.link,
                    color: Colors.white, size: 10),
              ),
            ),
        ]),
        title: Text(nom,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1A1A2E))),
        subtitle: Text(
          _formatRole(role),
          style: const TextStyle(
              color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _iconBtn(Icons.chat_bubble_outline, _primary, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  conversationId: convId,
                  receiverId:     contact['id'].toString(),
                  receiverName:   nom,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _iconBtn(Icons.call_outlined, const Color(0xFF4ADE80),
              () => _startCall(contact, 'audio')),
        ]),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: convId,
              receiverId:     contact['id'].toString(),
              receiverName:   nom,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startCall(
      Map<String, dynamic> contact, String type) async {
    final channelId =
        'call_${_myId}_${DateTime.now().millisecondsSinceEpoch}';
    await CallService().startCall(
      receiverId: contact['id'].toString(),
      channelId:  channelId,
      type:       type,
    );
  }

  // ── Liste groupes ─────────────────────────────────
  Widget _buildGroupsList() {
    if (_groups.isEmpty) {
      return _buildEmpty(
        icon: Icons.group_outlined,
        title: 'Aucun groupe',
        subtitle: 'Créez un groupe pour discuter ensemble.',
        btnLabel: 'Créer un groupe',
        onTap: _createGroup,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      itemCount: _groups.length,
      itemBuilder: (_, i) => _buildGroupItem(_groups[i]),
    );
  }

  // ✅ التعديل الجوهري المضاف: إظهار شارة الأدمن البنفسجية بجانب اسم المجموعة بشكل احترافي ومحمي من الـ Overflow
  Widget _buildGroupItem(Map<String, dynamic> groupe) {
    final nom         = (groupe['name'] ?? 'Groupe').toString();
    final memberCount = groupe['member_count'] ?? 0;
    
    // التحقق مما إذا كنت أنت الأدمن
    final isGroupAdmin = groupe['created_by'].toString() == _myId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.group, color: _primary, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (isGroupAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _primary.withOpacity(0.3), width: 0.8),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text('$memberCount membre(s)',
            style: const TextStyle(
                color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatPage(
              groupId:   groupe['id'].toString(),
              groupName: nom,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────
  Widget _buildAvatar(Map c, String nom, double size) {
    final url = c['avatar_url']?.toString();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _primary.withOpacity(0.15),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.35))
          : null,
    );
  }

  Widget _iconBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: _primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 18),
              label: Text(btnLabel,
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _genConvId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  String _formatRole(String? role) {
    if (role == null || role.isEmpty) return '👤 Contact';
    
    switch (role.toLowerCase()) {
      case 'patient':   return '🧓 Patient';
      case 'caregiver': return '🤝 Aidant';
      case 'medecin':
      case 'doctor':    return '👨‍⚕️ Médecin';
      default:          return role;
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFF4ADE80),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }
}
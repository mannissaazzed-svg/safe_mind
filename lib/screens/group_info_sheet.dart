import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:safemind/screens/voice_recorder.dart';
import 'package:safemind/screens/call_service.dart';
import 'package:safemind/screens/video_call_page.dart';
import 'package:safemind/screens/permissions.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GroupChatPage — SafeMind
// Fonctionnalités : texte · image · audio · appel vidéo/audio
//                   modification · suppression · réactions
//                   séparateurs de date · nom+avatar par membre
//                   ── NOUVEAU ── GroupInfoSheet admin (rename · add · kick)
// ═══════════════════════════════════════════════════════════════════════════

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final VoiceRecorder _recorder = VoiceRecorder();
  final AudioPlayer _player = AudioPlayer();

  // ── État ──────────────────────────────────────────────────────────────────
  bool _isRecording = false;
  bool _isUploading = false;
  bool _showAttachMenu = false;
  String? _editingMessageId;
  String? _currentlyPlayingId;

  // Données membres
  Map<String, Map<String, dynamic>> _sendersInfo = {};
  int _memberCount = 0;
  // Nom du groupe (peut être modifié depuis GroupInfoSheet)
  late String _currentGroupName;

  String get _myId => supabase.auth.currentUser!.id;
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  // ── Animation menu pièces jointes ────────────────────────────────────────
  late AnimationController _attachMenuController;
  late Animation<double> _attachMenuAnimation;

  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _primary  = Color(0xFF6C63FF);
  static const Color _bg       = Color(0xFFF0EFF5);
  static const Color _bubbleMe = Color(0xFF6C63FF);
  static const Color _appBarBg = Color(0xFF6C63FF);

  static const List<Color> _memberColors = [
    Color(0xFF6C63FF), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFf59e0b), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  Color _colorForMember(String userId) =>
      _memberColors[userId.hashCode.abs() % _memberColors.length];

  // ════════════════════════════════════════════════════════════════════════
  // INIT / DISPOSE
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    _currentGroupName = widget.groupName;

    _attachMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _attachMenuAnimation = CurvedAnimation(
      parent: _attachMenuController,
      curve: Curves.easeOutBack,
    );

    _messagesStream = supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .order('created_at', ascending: true)
        .map((data) => data.where((m) => m['is_deleted'] != true).toList());

    _chargerInfoMembres();
  }

  @override
  void dispose() {
    _attachMenuController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHARGEMENT MEMBRES
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _chargerInfoMembres() async {
    try {
      final members = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', widget.groupId);

      if ((members as List).isEmpty) return;

      final ids = members.map((m) => m['user_id'].toString()).toList();

      final users = await supabase
          .from('users')
          .select('id, name, full_name, avatar_url')
          .inFilter('id', ids);

      final map = <String, Map<String, dynamic>>{};
      for (final u in (users as List)) {
        map[u['id'].toString()] = Map<String, dynamic>.from(u);
      }

      if (mounted) {
        setState(() {
          _sendersInfo = map;
          _memberCount = ids.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement membres: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // OUVERTURE GroupInfoSheet
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _openGroupInfo() async {
    // Vérifie si l'utilisateur courant est admin
    bool isAdmin = false;
    try {
      final row = await supabase
          .from('group_members')
          .select('role')
          .eq('group_id', widget.groupId)
          .eq('user_id', _myId)
          .maybeSingle();
      isAdmin = row?['role'] == 'admin';
    } catch (_) {}

    if (!mounted) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupInfoSheet(
        groupId: widget.groupId,
        groupName: _currentGroupName,
        isAdmin: isAdmin,
      ),
    );

    // Mise à jour du nom si l'admin l'a modifié
    if (result is String && result.isNotEmpty && result != 'deleted') {
      if (mounted) setState(() => _currentGroupName = result);
    }

    // Si le groupe a été supprimé
    if (result == 'deleted' && mounted) {
      Navigator.pop(context);
      return;
    }

    // Recharge les membres (ajout / suppression possible)
    _chargerInfoMembres();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ENVOI MESSAGES
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _hideAttachMenu();

    try {
      if (_editingMessageId != null) {
        await supabase
            .from('group_messages')
            .update({'content': text, 'is_edited': true})
            .eq('id', _editingMessageId!);
        setState(() => _editingMessageId = null);
      } else {
        await supabase.from('group_messages').insert({
          'group_id'  : widget.groupId,
          'sender_id' : _myId,
          'content'   : text,
          'type'      : 'text',
          'is_deleted': false,
          'is_edited' : false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erreur envoi texte: $e');
    }
  }

  Future<void> _sendImage({required ImageSource source}) async {
    _hideAttachMenu();
    final img = await _picker.pickImage(source: source, imageQuality: 75);
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(img.path);
      final name = 'group_img_${const Uuid().v4()}.jpg';
      await supabase.storage.from('chat-media').upload(name, file);
      final url = supabase.storage.from('chat-media').getPublicUrl(name);
      await supabase.from('group_messages').insert({
        'group_id'  : widget.groupId,
        'sender_id' : _myId,
        'media_url' : url,
        'type'      : 'image',
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erreur image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _startRecord() async {
    final ok = await Permissions.mic();
    if (!ok) return;
    _hideAttachMenu();
    await _recorder.start();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecord() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(path);
      final name = 'group_voice_${const Uuid().v4()}.m4a';
      await supabase.storage.from('chat-media').upload(name, file);
      final url = supabase.storage.from('chat-media').getPublicUrl(name);
      await supabase.from('group_messages').insert({
        'group_id'  : widget.groupId,
        'sender_id' : _myId,
        'media_url' : url,
        'type'      : 'audio',
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erreur audio: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMessage(String id) async {
    await supabase
        .from('group_messages')
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('sender_id', _myId);
  }

  Future<void> _addReaction(String id, String emoji) async {
    await supabase
        .from('group_messages')
        .update({'reaction': emoji})
        .eq('id', id);
  }

  // ════════════════════════════════════════════════════════════════════════
  // APPEL
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _call(String type) async {
    final channelId = const Uuid().v4();
    final result = await CallService().startCall(
      callerId  : _myId,
      receiverId: widget.groupId,
      channelId : channelId,
      type      : type,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallPage(
          channelId  : channelId,
          appId      : 'feaef859a6c740ee9880322144128c96',
          callId     : result.callId ?? '',
          isVoiceOnly: type == 'audio',
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MENU PIÈCES JOINTES
  // ════════════════════════════════════════════════════════════════════════

  void _toggleAttachMenu() {
    setState(() => _showAttachMenu = !_showAttachMenu);
    _showAttachMenu
        ? _attachMenuController.forward()
        : _attachMenuController.reverse();
  }

  void _hideAttachMenu() {
    if (_showAttachMenu) {
      setState(() => _showAttachMenu = false);
      _attachMenuController.reverse();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: _hideAttachMenu,
        child: Column(
          children: [
            if (_isUploading)
              LinearProgressIndicator(
                backgroundColor: _primary.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(_primary),
                minHeight: 3,
              ),
            Expanded(child: _buildMessageList()),
            if (_editingMessageId != null) _buildEditBanner(),
            if (_showAttachMenu) _buildAttachMenu(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBg,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _openGroupInfo,         // ← Tap sur avatar/nom ouvre le sheet
        child: Row(
          children: [
            // Avatar groupe cliquable
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentGroupName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(
                    '$_memberCount membre${_memberCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        _AppBarAction(icon: Icons.call_outlined,    onTap: () => _call('audio')),
        _AppBarAction(icon: Icons.videocam_outlined, onTap: () => _call('video')),
        // Bouton info groupe
        IconButton(
          tooltip: 'Infos du groupe',
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, size: 19, color: Colors.white),
          ),
          onPressed: _openGroupInfo,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Liste des messages ────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final msgs = snapshot.data!;
        if (msgs.isEmpty) return _buildEmptyState();

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom(animated: false));

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final showDate = i == 0 ||
                _isDifferentDay(
                    msgs[i - 1]['created_at'], msgs[i]['created_at']);
            return Column(
              children: [
                if (showDate) _buildDateDivider(msgs[i]['created_at']),
                _buildBubble(msgs[i]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 36, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun message pour l\'instant',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Soyez le premier à écrire !',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  bool _isDifferentDay(String? a, String? b) {
    if (a == null || b == null) return false;
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return false;
    return da.day != db.day || da.month != db.month || da.year != db.year;
  }

  Widget _buildDateDivider(String? dateStr) {
    if (dateStr == null) return const SizedBox();
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return const SizedBox();
    final today = DateTime.now();
    String label;
    if (dt.day == today.day && dt.month == today.month && dt.year == today.year) {
      label = 'Aujourd\'hui';
    } else if (dt.day == today.day - 1 &&
        dt.month == today.month &&
        dt.year == today.year) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMM yyyy').format(dt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }

  // ── Bulle ─────────────────────────────────────────────────────────────────
  Widget _buildBubble(Map<String, dynamic> msg) {
    final bool isMe       = msg['sender_id'] == _myId;
    final bool isDeleted  = msg['is_deleted'] == true;
    final bool isEdited   = msg['is_edited'] == true;
    final String? reaction = msg['reaction'];
    final String msgId    = msg['id'].toString();
    final String senderId = msg['sender_id']?.toString() ?? '';
    final senderInfo      = _sendersInfo[senderId] ?? {};
    final senderName      =
        (senderInfo['name'] ?? senderInfo['full_name'] ?? 'Membre').toString();
    final senderAvatar    = senderInfo['avatar_url']?.toString();
    final memberColor     = _colorForMember(senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildMiniAvatar(senderName, senderAvatar, memberColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(msg),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Text(
                        senderName,
                        style: TextStyle(
                            fontSize: 11,
                            color: memberColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: isMe ? 60 : 0,
                          right: isMe ? 0 : 60,
                          bottom: reaction != null ? 10 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? _bubbleMe : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: msg['type'] == 'image'
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBubbleContent(msg, isMe, isDeleted, msgId),
                              const SizedBox(height: 4),
                              _buildBubbleMeta(msg, isMe, isEdited),
                            ],
                          ),
                        ),
                      ),
                      if (reaction != null)
                        Positioned(
                          bottom: 0,
                          right: isMe ? 6 : null,
                          left : isMe ? null : 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4)
                              ],
                            ),
                            child: Text(reaction,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Contenu bulle ─────────────────────────────────────────────────────────
  Widget _buildBubbleContent(Map msg, bool isMe, bool isDeleted, String msgId) {
    if (isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block,
              size: 14,
              color: isMe ? Colors.white54 : Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            'Ce message a été supprimé',
            style: TextStyle(
                color: isMe ? Colors.white54 : Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                fontSize: 13),
          ),
        ],
      );
    }

    switch (msg['type']) {
      case 'text':
        return Text(
          msg['content'] ?? '',
          style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 15,
              height: 1.4),
        );

      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Image.network(
            msg['media_url'] ?? '',
            width: 220,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    width: 220,
                    height: 160,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );

      case 'audio':
        return _buildAudioPlayer(msg, isMe, msgId);

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Lecteur audio ─────────────────────────────────────────────────────────
  Widget _buildAudioPlayer(Map msg, bool isMe, String msgId) {
    final bool isPlaying = _currentlyPlayingId == msgId;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            if (isPlaying) {
              await _player.pause();
              setState(() => _currentlyPlayingId = null);
            } else {
              await _player.stop();
              await _player.play(UrlSource(msg['media_url']));
              setState(() => _currentlyPlayingId = msgId);
              _player.onPlayerComplete.listen((_) {
                if (mounted) setState(() => _currentlyPlayingId = null);
              });
            }
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.25)
                  : _primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.white : _primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: List.generate(14, (i) {
            final heights = [
              10.0, 16.0, 8.0, 20.0, 12.0, 18.0, 10.0,
              22.0, 14.0, 10.0, 18.0,  8.0, 16.0, 12.0,
            ];
            return Container(
              width: 3,
              height: heights[i],
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(isPlaying ? 1.0 : 0.5)
                    : _primary.withOpacity(isPlaying ? 1.0 : 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Méta message ──────────────────────────────────────────────────────────
  Widget _buildBubbleMeta(Map msg, bool isMe, bool isEdited) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEdited)
          Text(
            'modifié · ',
            style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white54 : Colors.grey.shade400),
          ),
        Text(
          _formatTime(msg['created_at']),
          style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white54 : Colors.grey.shade400),
        ),
      ],
    );
  }

  // ── Options message (long press) ──────────────────────────────────────────
  void _showMessageOptions(Map<String, dynamic> msg) {
    final bool isMe = msg['sender_id'] == _myId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Réactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '😮', '😢', '👍', '🔥'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      _addReaction(msg['id'].toString(), e);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            if (msg['type'] == 'text')
              _OptionTile(
                icon: Icons.copy_outlined,
                label: 'Copier le message',
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: msg['content'] ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Copié !'),
                        duration: Duration(seconds: 2)),
                  );
                },
              ),
            if (isMe && msg['type'] == 'text' && msg['is_deleted'] != true)
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'Modifier le message',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessageId = msg['id'].toString();
                    _textController.text = msg['content'] ?? '';
                  });
                },
              ),
            if (isMe && msg['is_deleted'] != true)
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Supprimer pour tous',
                color: Colors.red.shade600,
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg['id'].toString());
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Bannière modification ─────────────────────────────────────────────────
  Widget _buildEditBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        border: const Border(left: BorderSide(color: _primary, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 15, color: _primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Modifier le message',
                style: TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _editingMessageId = null;
              _textController.clear();
            }),
            child: const Icon(Icons.close, size: 18, color: _primary),
          ),
        ],
      ),
    );
  }

  // ── Menu pièces jointes ───────────────────────────────────────────────────
  Widget _buildAttachMenu() {
    return ScaleTransition(
      scale: _attachMenuAnimation,
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AttachItem(
              icon: Icons.photo_library_outlined,
              label: 'Galerie',
              color: const Color(0xFF8B5CF6),
              onTap: () => _sendImage(source: ImageSource.gallery),
            ),
            _AttachItem(
              icon: Icons.camera_alt_outlined,
              label: 'Caméra',
              color: const Color(0xFF0EA5E9),
              onTap: () => _sendImage(source: ImageSource.camera),
            ),
            _AttachItem(
              icon: Icons.mic_outlined,
              label: 'Audio',
              color: const Color(0xFF10B981),
              onTap: _startRecord,
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de saisie ───────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _InputIcon(
            icon: _showAttachMenu ? Icons.close : Icons.add,
            color: _showAttachMenu ? Colors.red : _primary,
            onTap: _toggleAttachMenu,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Message au groupe...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onLongPressStart: (_) => _startRecord(),
            onLongPressEnd: (_) => _stopRecord(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red
                    : _primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic_none_outlined,
                color: _isRecording ? Colors.white : _primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: _primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMiniAvatar(String nom, String? avatarUrl, Color color) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withOpacity(0.2),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            )
          : null,
    );
  }

  String _formatTime(String? s) {
    if (s == null) return '';
    final dt = DateTime.tryParse(s)?.toLocal();
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GroupInfoSheet — feuille modale admin
// Onglets : Membres · Ajouter · Paramètres
// ═══════════════════════════════════════════════════════════════════════════

class GroupInfoSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;

  const GroupInfoSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
  });

  @override
  State<GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<GroupInfoSheet>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  late String _groupName;

  final TextEditingController _codeController = TextEditingController();

  static const Color _primary = Color(0xFF6C63FF);

  static const List<Color> _memberColors = [
    Color(0xFF6C63FF), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFf59e0b), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  Color _colorFor(String uid) =>
      _memberColors[uid.hashCode.abs() % _memberColors.length];

  // ════════════════════════════════════════════════════════════════════════
  // INIT / DISPOSE
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _tabController = TabController(length: 3, vsync: this);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // CHARGEMENT MEMBRES
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final rows = await supabase
          .from('group_members')
          .select('user_id, role')
          .eq('group_id', widget.groupId);

      if ((rows as List).isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final ids = rows.map((r) => r['user_id'].toString()).toList();

      final users = await supabase
          .from('users')
          .select('id, name, full_name, avatar_url')
          .inFilter('id', ids);

      final userMap = <String, Map>{};
      for (final u in (users as List)) {
        userMap[u['id'].toString()] = u;
      }

      final merged = rows.map<Map<String, dynamic>>((r) {
        final info = userMap[r['user_id'].toString()] ?? {};
        return {
          'user_id'   : r['user_id'],
          'role'      : r['role'] ?? 'member',
          'name'      : info['name'] ?? info['full_name'] ?? 'Membre',
          'avatar_url': info['avatar_url'],
        };
      }).toList();

      // Admin en tête
      merged.sort((a, b) {
        if (a['role'] == 'admin' && b['role'] != 'admin') return -1;
        if (b['role'] == 'admin' && a['role'] != 'admin') return 1;
        return 0;
      });

      if (mounted) setState(() { _members = merged; _loading = false; });
    } catch (e) {
      debugPrint('loadMembers: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS ADMIN
  // ════════════════════════════════════════════════════════════════════════

  /// Renommer le groupe
  Future<void> _renameGroup() async {
    final ctrl = TextEditingController(text: _groupName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.drive_file_rename_outline, color: _primary, size: 22),
          SizedBox(width: 10),
          Text('Renommer le groupe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nouveau nom...',
            filled: true,
            fillColor: const Color(0xFFF5F4FA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Enregistrer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    try {
      await supabase
          .from('groups')
          .update({'name': result})
          .eq('id', widget.groupId);
      setState(() => _groupName = result);
      _showSnack('✅ Groupe renommé avec succès');
    } catch (e) {
      _showSnack('Erreur: $e');
    }
  }

  /// Ajouter un membre par code de connexion
  Future<void> _addByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) { _showSnack('Entrez un code de connexion'); return; }

    try {
      final res = await supabase
          .from('users')
          .select('id, name, full_name')
          .eq('connection_code', code)
          .maybeSingle();

      if (res == null) {
        _showSnack('❌ Code invalide ou introuvable');
        return;
      }

      final userId = res['id'].toString();

      final exists = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', widget.groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (exists != null) {
        _showSnack('Ce membre est déjà dans le groupe');
        return;
      }

      await supabase.from('group_members').insert({
        'group_id' : widget.groupId,
        'user_id'  : userId,
        'role'     : 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      _codeController.clear();
      final name = (res['name'] ?? res['full_name'] ?? 'Membre').toString();
      _showSnack('✅ $name ajouté au groupe !');
      _loadMembers();
    } catch (e) {
      _showSnack('Erreur: $e');
    }
  }

  /// Retirer un membre
  Future<void> _kickMember(Map member) async {
    final name = member['name'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retirer le membre',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous retirer $name du groupe ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', widget.groupId)
          .eq('user_id', member['user_id']);
      _showSnack('$name retiré du groupe');
      _loadMembers();
    } catch (e) {
      _showSnack('Erreur: $e');
    }
  }

  /// Promouvoir / rétrograder admin
  Future<void> _toggleRole(Map member) async {
    final newRole = member['role'] == 'admin' ? 'member' : 'admin';
    try {
      await supabase
          .from('group_members')
          .update({'role': newRole})
          .eq('group_id', widget.groupId)
          .eq('user_id', member['user_id']);
      _showSnack(newRole == 'admin'
          ? '${member['name']} est maintenant Admin'
          : '${member['name']} rétrogradé en Membre');
      _loadMembers();
    } catch (e) {
      _showSnack('Erreur: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  // Avatar groupe — tap → renommer (admin seulement)
                  GestureDetector(
                    onTap: widget.isAdmin ? _renameGroup : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.group_rounded,
                              color: _primary, size: 32),
                        ),
                        if (widget.isAdmin)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _groupName,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (widget.isAdmin)
                              GestureDetector(
                                onTap: _renameGroup,
                                child: const Icon(
                                    Icons.drive_file_rename_outline,
                                    size: 18,
                                    color: _primary),
                              ),
                          ],
                        ),
                        Text(
                          '${_members.length} membre(s)',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        if (widget.isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_rounded,
                                    size: 12,
                                    color: Color(0xFF92400E)),
                                SizedBox(width: 4),
                                Text('Administrateur',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tabs ──
            TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _primary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Membres'),
                Tab(text: 'Ajouter'),
                Tab(text: 'Paramètres'),
              ],
            ),

            // ── Contenu tabs ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(scrollController),
                  _buildAddTab(),
                  _buildSettingsTab(scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Onglet Membres ────────────────────────────────────────────────────────
  Widget _buildMembersTab(ScrollController ctrl) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_members.isEmpty) {
      return const Center(
          child: Text('Aucun membre', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _members.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) => _buildMemberTile(_members[i]),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final myId   = supabase.auth.currentUser!.id;
    final isMe   = member['user_id'] == myId;
    final isAdm  = member['role'] == 'admin';
    final color  = _colorFor(member['user_id'].toString());
    final name   = member['name'].toString();

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withOpacity(0.15),
        backgroundImage: member['avatar_url'] != null
            ? NetworkImage(member['avatar_url']) : null,
        child: member['avatar_url'] == null
            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('vous',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (isAdm)
            const Icon(Icons.shield_rounded, size: 12, color: _primary),
          if (isAdm) const SizedBox(width: 3),
          Text(
            isAdm ? 'Administrateur' : 'Membre',
            style: TextStyle(
                fontSize: 11,
                color: isAdm ? _primary : Colors.grey,
                fontWeight:
                    isAdm ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
      trailing: !isMe && widget.isAdmin
          ? PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (val) {
                if (val == 'role') _toggleRole(member);
                if (val == 'kick') _kickMember(member);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Row(children: [
                    Icon(
                        isAdm
                            ? Icons.person_remove_outlined
                            : Icons.shield_outlined,
                        size: 18,
                        color: isAdm ? Colors.orange : _primary),
                    const SizedBox(width: 10),
                    Text(isAdm
                        ? 'Retirer les droits admin'
                        : 'Promouvoir admin'),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'kick',
                  child: Row(children: [
                    const Icon(Icons.person_off_outlined,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    const Text('Retirer du groupe',
                        style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            )
          : null,
    );
  }

  // ── Onglet Ajouter ────────────────────────────────────────────────────────
  Widget _buildAddTab() {
    if (!widget.isAdmin) {
      return const _LockedTab();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Par code ──
          const Text('Ajouter par code de connexion',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Demandez au membre son code personnel visible dans son profil SafeMind.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'ex: SM-4829',
                    prefixIcon:
                        const Icon(Icons.tag, color: _primary),
                    filled: true,
                    fillColor: const Color(0xFFF5F4FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: _primary)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _addByCode,
                icon: const Icon(Icons.person_add,
                    color: Colors.white, size: 18),
                label: const Text('Ajouter',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // ── Lien d'invitation ──
          const Text('Partager le lien d\'invitation',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: _primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lien d\'invitation',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(
                        'safemind.app/join/${widget.groupId.substring(0, 8)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: _primary, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'safemind.app/join/${widget.groupId}'));
                    _showSnack('Lien copié !');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet Paramètres ─────────────────────────────────────────────────────
  Widget _buildSettingsTab(ScrollController ctrl) {
    if (!widget.isAdmin) {
      return const _LockedTab();
    }

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Général'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.drive_file_rename_outline,
          label: 'Renommer le groupe',
          subtitle: _groupName,
          color: _primary,
          onTap: _renameGroup,
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Activées pour tous',
          color: Colors.green,
          onTap: () => _showSnack('Bientôt disponible'),
        ),
        _SettingsTile(
          icon: Icons.lock_outline,
          label: 'Qui peut écrire ?',
          subtitle: 'Tous les membres',
          color: Colors.orange,
          onTap: () => _showSnack('Bientôt disponible'),
        ),
        _SettingsTile(
          icon: Icons.image_outlined,
          label: 'Photo du groupe',
          subtitle: 'Modifier l\'image',
          color: Colors.purple,
          onTap: () => _showSnack('Bientôt disponible'),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Zone de danger'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _SettingsTile(
            icon: Icons.delete_outline,
            label: 'Supprimer le groupe',
            subtitle: 'Action irréversible pour tous',
            color: Colors.red,
            onTap: _confirmDeleteGroup,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le groupe ?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Cette action est irréversible et supprimera tous les messages et membres.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Supprimer messages puis groupe
      await supabase
          .from('group_messages')
          .delete()
          .eq('group_id', widget.groupId);
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', widget.groupId);
      await supabase
          .from('groups')
          .delete()
          .eq('id', widget.groupId);

      if (mounted) Navigator.pop(context, 'deleted');
    } catch (e) {
      _showSnack('Erreur suppression: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════════════

/// Onglet verrouillé pour les non-admins
class _LockedTab extends StatelessWidget {
  const _LockedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                size: 30, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          const Text('Réservé à l\'administrateur',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Seul l\'admin peut modifier ces paramètres.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.8),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing:
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

// ── AppBar action button ──────────────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: Colors.white),
      ),
      onPressed: onTap,
    );
  }
}

// ── Input icon ────────────────────────────────────────────────────────────
class _InputIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _InputIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ── Attach menu item ──────────────────────────────────────────────────────
class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Option tile (long press menu) ─────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w500, fontSize: 14)),
    );
  }
}
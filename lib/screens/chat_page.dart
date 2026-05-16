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

// ═══════════════════════════════════════════════════════
// Page de chat professionnelle — SafeMind
// Fonctionnalités : texte, image, audio, appel vidéo,
//                   modification/suppression, réactions,
//                   changement de photo et de nom
// ═══════════════════════════════════════════════════════

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final VoiceRecorder _recorder = VoiceRecorder();
  final AudioPlayer _player = AudioPlayer();

  // ── État (variables) ──────────────────────────────────────────────
  bool _isRecording = false;
  bool _isUploading = false;
  bool _showAttachMenu = false;
  String? _editingMessageId;
  String? _currentlyPlayingId;
  String? _receiverAvatarUrl;
  String _receiverName = '';
  bool _receiverOnline = false;

  String get _myId => supabase.auth.currentUser!.id;
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  // ── Animation ──────────────────────────────────────────
  late AnimationController _attachMenuController;
  late Animation<double> _attachMenuAnimation;

  // ── Couleurs ────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _primaryDark = Color(0xFF4A42CC);
  static const Color _bg = Color(0xFFF0EFF5);
  static const Color _bubbleMe = Color(0xFF6C63FF);
  static const Color _bubbleOther = Colors.white;
  static const Color _appBarBg = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _receiverName = widget.receiverName;

    _attachMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _attachMenuAnimation = CurvedAnimation(
      parent: _attachMenuController,
      curve: Curves.easeOutBack,
    );

    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true)
        .map((data) => data
            .where((m) => m['is_deleted'] != true)
            .toList());

    _fetchReceiverInfo();
    _markSeen();
    _setOnline(true);
  }

  @override
  void dispose() {
    _attachMenuController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _player.dispose();
    _setOnline(false);
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // MÉTHODES DE DONNÉES
  // ══════════════════════════════════════════════════════

  Future<void> _fetchReceiverInfo() async {
    try {
      final data = await supabase
          .from('users')
          .select('name, avatar_url, is_online')
          .eq('id', widget.receiverId)
          .single();
      setState(() {
        _receiverName = data['name'] ?? widget.receiverName;
        _receiverAvatarUrl = data['avatar_url'];
        _receiverOnline = data['is_online'] == true;
      });
    } catch (_) {}
  }

  Future<void> _setOnline(bool status) async {
    try {
      await supabase.from('users').update({
        'is_online': status,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', _myId);
    } catch (_) {}
  }

  Future<void> _markSeen() async {
    try {
      await supabase
          .from('messages')
          .update({'is_seen': true})
          .eq('conversation_id', widget.conversationId)
          .eq('receiver_id', _myId);
    } catch (_) {}
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
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  // ══════════════════════════════════════════════════════
  // MÉTHODES D'ENVOI
  // ══════════════════════════════════════════════════════

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _hideAttachMenu();

    if (_editingMessageId != null) {
      await supabase
          .from('messages')
          .update({'content': text, 'is_edited': true})
          .eq('id', _editingMessageId!);
      setState(() => _editingMessageId = null);
    } else {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'receiver_id': widget.receiverId,
        'content': text,
        'type': 'text',
        'is_seen': false,
        'is_deleted': false,
        'is_edited': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendImage({required ImageSource source}) async {
    _hideAttachMenu();
    final img = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(img.path);
      final name = 'img_${const Uuid().v4()}.jpg';
      await supabase.storage.from('chat-media').upload(name, file);
      final url = supabase.storage.from('chat-media').getPublicUrl(name);
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'receiver_id': widget.receiverId,
        'media_url': url,
        'type': 'image',
        'is_seen': false,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _scrollToBottom();
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
      final name = 'voice_${const Uuid().v4()}.m4a';
      await supabase.storage.from('chat-media').upload(name, file);
      final url = supabase.storage.from('chat-media').getPublicUrl(name);
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'receiver_id': widget.receiverId,
        'media_url': url,
        'type': 'audio',
        'is_seen': false,
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _scrollToBottom();
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMessage(String id) async {
    await supabase
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('sender_id', _myId);
  }

  Future<void> _addReaction(String id, String emoji) async {
    await supabase.from('messages').update({'reaction': emoji}).eq('id', id);
  }

  // ══════════════════════════════════════════════════════
  // MODIFICATION AVATAR / NOM
  // ══════════════════════════════════════════════════════

  /// Changer la photo de l'utilisateur avec qui vous discutez
  Future<void> _changeReceiverAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarSourceSheet(),
    );
    if (source == null) return;

    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(img.path);
      final name = 'avatar_${widget.receiverId}.jpg';
      await supabase.storage.from('avatars').upload(
            name,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = supabase.storage.from('avatars').getPublicUrl(name);
      await supabase
          .from('users')
          .update({'avatar_url': url})
          .eq('id', widget.receiverId);
      setState(() => _receiverAvatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _editReceiverName() async {
    final c = TextEditingController(text: _receiverName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await supabase
          .from('users')
          .update({'name': result})
          .eq('id', widget.receiverId);
      setState(() => _receiverName = result);
    }
  }

  // ══════════════════════════════════════════════════════
  // APPEL
  // ══════════════════════════════════════════════════════



  Future<void> _startCall(String type) async {
  final channelId = const Uuid().v4();
  
  // 1. هنا نقوم باستقبال الـ callId الذي يعود من قاعدة البيانات
  // افترض أن دالة startCall تعيد الـ ID الخاص بالمكالمة (أو قم بتعديلها لتعيده)
  final callId = await CallService().startCall(
    callerId: _myId,
    receiverId: widget.receiverId,
    channelId: channelId,
    type: type,
  );

  if (!mounted) return;

  // 2. هنا نقوم بتمرير الـ callId إلى صفحة الفيديو
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoCallPage(
        channelId: channelId,
        appId: 'feaef859a6c740ee9880322144128c96',
        callId: callId ?? '' ,
        isVoiceOnly: type == 'audio',
      ),
    ),
  );
}

  // ══════════════════════════════════════════════════════
  // MENU PIÈCES JOINTES
  // ══════════════════════════════════════════════════════

  void _toggleAttachMenu() {
    setState(() => _showAttachMenu = !_showAttachMenu);
    if (_showAttachMenu) {
      _attachMenuController.forward();
    } else {
      _attachMenuController.reverse();
    }
  }

  void _hideAttachMenu() {
    if (_showAttachMenu) {
      setState(() => _showAttachMenu = false);
      _attachMenuController.reverse();
    }
  }

  // ══════════════════════════════════════════════════════
  // CONSTRUCTION UI
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: _hideAttachMenu,
        child: Column(
          children: [
            // ── Indicateur de téléchargement ───────────────────────
            if (_isUploading)
              LinearProgressIndicator(
                backgroundColor: _primary.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(_primary),
                minHeight: 3,
              ),

            // ── Messages ───────────────────────────────
            Expanded(child: _buildMessageList()),

            // ── Bannière mode modification ───────────────────────
            if (_editingMessageId != null) _buildEditBanner(),

            // ── Menu pièces jointes ──────────────────────
            if (_showAttachMenu) _buildAttachMenu(),

            // ── Barre de saisie ──────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Barre supérieure ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBg,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _showProfileSheet,
        child: Row(
          children: [
            // ── Avatar avec bouton modification ────────────────
            Stack(
              children: [
                GestureDetector(
                  onTap: _changeReceiverAvatar,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    backgroundImage: _receiverAvatarUrl != null
                        ? NetworkImage(_receiverAvatarUrl!)
                        : null,
                    child: _receiverAvatarUrl == null
                        ? Text(
                            _receiverName.isNotEmpty
                                ? _receiverName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                // ── Icône caméra superposée ──────────────
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 10,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // ── Nom et statut ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: _receiverOnline
                              ? const Color(0xFF4ADE80)
                              : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _receiverOnline ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          fontSize: 11,
                          color: _receiverOnline
                              ? const Color(0xFF4ADE80)
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // ── Appel vocal ──────────────────────────────
        _AppBarAction(
          icon: Icons.call_outlined,
          onTap: () => _startCall('audio'),
        ),
        // ── Appel vidéo ──────────────────────────────
        _AppBarAction(
          icon: Icons.videocam_outlined,
          onTap: () => _startCall('video'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Fiche profil (appui sur nom/avatar) ─────────────
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        name: _receiverName,
        avatarUrl: _receiverAvatarUrl,
        isOnline: _receiverOnline,
        onChangeName: _editReceiverName,
        onChangeAvatar: _changeReceiverAvatar,
      ),
    );
  }

  // ── Liste des messages ─────────────────────────────────────
  Widget _buildMessageList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _primary),
          );
        }
        final msgs = snapshot.data!;
        if (msgs.isEmpty) {
          return _buildEmptyState();
        }
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: false),
        );
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final showDate = i == 0 ||
                _isDifferentDay(msgs[i - 1]['created_at'], msgs[i]['created_at']);
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
    if (dt.day == today.day && dt.month == today.month) {
      label = 'Aujourd\'hui';
    } else if (dt.day == today.day - 1 && dt.month == today.month) {
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
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
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
            child: const Icon(Icons.chat_bubble_outline,
                size: 36, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun message pour l\'instant',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Commencez la conversation',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Bulle de message ────────────────────────────────────
  Widget _buildBubble(Map msg) {
    final bool isMe = msg['sender_id'] == _myId;
    final bool isDeleted = msg['is_deleted'] == true;
    final bool isEdited = msg['is_edited'] == true;
    final bool isSeen = msg['is_seen'] == true;
    final String? reaction = msg['reaction'];
    final String msgId = msg['id'].toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(msg),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 60 : 0,
                  right: isMe ? 0 : 60,
                  bottom: reaction != null ? 10 : 0,
                ),
                decoration: BoxDecoration(
                  color: isMe ? _bubbleMe : _bubbleOther,
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
                  padding: _contentPadding(msg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBubbleContent(msg, isMe, isDeleted, msgId),
                      const SizedBox(height: 4),
                      _buildBubbleMeta(msg, isMe, isEdited, isSeen),
                    ],
                  ),
                ),
              ),
              // ── Badge de réaction ─────────────────────
              if (reaction != null)
                Positioned(
                  bottom: 0,
                  right: isMe ? 6 : null,
                  left: isMe ? null : 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Text(reaction, style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _contentPadding(Map msg) {
    if (msg['type'] == 'image') {
      return EdgeInsets.zero;
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  }

  Widget _buildBubbleContent(
      Map msg, bool isMe, bool isDeleted, String msgId) {
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
              fontSize: 13,
            ),
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
            height: 1.4,
          ),
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
            msg['media_url'],
            width: 220,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    width: 220,
                    height: 160,
                    color: Colors.grey.shade100,
                    child:
                        const Center(child: CircularProgressIndicator()),
                  ),
          ),
        );

      case 'audio':
        return _buildAudioPlayer(msg, isMe, msgId);

      default:
        return const SizedBox();
    }
  }

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
        // ── Barres de forme d'onde ────────────────────────────
        Row(
          children: List.generate(14, (i) {
            final heights = [10.0, 16.0, 8.0, 20.0, 12.0, 18.0, 10.0, 22.0, 14.0, 10.0, 18.0, 8.0, 16.0, 12.0];
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

  Widget _buildBubbleMeta(
      Map msg, bool isMe, bool isEdited, bool isSeen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEdited)
          Text(
            'modifié · ',
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white54 : Colors.grey.shade400,
            ),
          ),
        Text(
          _formatTime(msg['created_at']),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white54 : Colors.grey.shade400,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            isSeen ? Icons.done_all : Icons.done,
            size: 13,
            color: isSeen
                ? const Color(0xFF93C5FD)
                : Colors.white54,
          ),
        ],
      ],
    );
  }

  // ── Options de message ───────────────────────────────────
  void _showMessageOptions(Map msg) {
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
            // ── Poignée de glissement ───────────────────────────
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Rangée de réactions ──────────────────────────
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
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(e,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // ── Actions ───────────────────────────────
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
                      duration: Duration(seconds: 2),
                    ),
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

  // ── Bannière de modification ───────────────────────────────────────
  Widget _buildEditBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        border: Border(
          left: BorderSide(color: _primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 15, color: _primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Modifier le message',
              style: TextStyle(
                  color: _primary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
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

  // ── Menu pièces jointes ───────────────────────────────────────
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

  // ── Barre de saisie ─────────────────────────────────────────
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
          // ── Bouton pièces jointes ─────────────────────────
          _InputIcon(
            icon: _showAttachMenu ? Icons.close : Icons.add,
            color: _showAttachMenu ? Colors.red : _primary,
            onTap: _toggleAttachMenu,
          ),

          const SizedBox(width: 6),

          // ── Champ de texte ────────────────────────────
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
                  hintText: 'Écrire un message...',
                  hintStyle:
                      TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Bouton enregistrement vocal ───────────────────
          GestureDetector(
            onLongPressStart: (_) => _startRecord(),
            onLongPressEnd: (_) => _stopRecord(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : _primary.withOpacity(0.12),
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

          // ── Bouton envoyer ───────────────────────────
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilitaires ────────────────────────────────────────────
  String _formatTime(String? s) {
    if (s == null) return '';
    final dt = DateTime.tryParse(s)?.toLocal();
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }
}

// ══════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════

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

class _InputIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _InputIcon({required this.icon, required this.color, required this.onTap});

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
          style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 14)),
    );
  }
}

// ── Avatar Source Sheet ───────────────────────────────
class _AvatarSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Changer la photo de l\'utilisateur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Caméra',
                color: const Color(0xFF0EA5E9),
                value: ImageSource.camera,
              ),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Galerie',
                color: const Color(0xFF8B5CF6),
                value: ImageSource.gallery,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ImageSource value;
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Profile Sheet ─────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback onChangeName;
  final VoidCallback onChangeAvatar;

  const _ProfileSheet({
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.onChangeName,
    required this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Big avatar ──────────────────────────────
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFEDE9FE),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onChangeAvatar();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  color: isOnline
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          // ── Actions ──────────────────────────────────
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Color(0xFF6C63FF), size: 20),
            ),
            title: const Text('Modifier le nom',
                style:
                    TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              onChangeName();
            },
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF0EA5E9), size: 20),
            ),
            title: const Text('Changer la photo',
                style:
                    TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              onChangeAvatar();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}



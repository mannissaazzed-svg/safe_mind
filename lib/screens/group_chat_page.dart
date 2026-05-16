import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

import 'package:safemind/screens/voice_recorder.dart';
import 'package:safemind/screens/call_service.dart';
import 'package:safemind/screens/video_call_page.dart';
import 'package:safemind/screens/permissions.dart';

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

class _GroupChatPageState extends State<GroupChatPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final VoiceRecorder _recorder = VoiceRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isUploading = false;
  String? _playingId;

  // خريطة بيانات المرسلين لعرض الأسماء والصور
  Map<String, Map<String, dynamic>> _sendersInfo = {};

  String get _myId => supabase.auth.currentUser!.id;

  // ✅ Stream صحيح — يقرأ من جدول group_messages
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _bg = Color(0xFFF5F4FA);

  @override
  void initState() {
    super.initState();

    // ✅ الجدول الصحيح للرسائل
    _messagesStream = supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', widget.groupId)
        .order('created_at', ascending: true);

    _chargerInfoMembres();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // تحميل بيانات الأعضاء (الأسماء والصور)
  // ══════════════════════════════════════════════════════

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

      if (mounted) setState(() => _sendersInfo = map);
    } catch (e) {
      debugPrint('Erreur chargement membres: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // ENVOYER TEXTE
  // ══════════════════════════════════════════════════════

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    try {
      // ✅ يكتب في جدول group_messages
      await supabase.from('group_messages').insert({
        'group_id': widget.groupId,
        'sender_id': _myId,
        'content': text,
        'type': 'text',
        'created_at': DateTime.now().toIso8601String(),
      });

      _scrollBottom();
    } catch (e) {
      debugPrint('Erreur envoi texte: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // ENVOYER IMAGE
  // ══════════════════════════════════════════════════════

  Future<void> _sendImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(img.path);
      final name = 'group_img_${const Uuid().v4()}.jpg';

      await supabase.storage.from('chat-media').upload(name, file);
      final url = supabase.storage.from('chat-media').getPublicUrl(name);

      // ✅ يكتب في جدول group_messages
      await supabase.from('group_messages').insert({
        'group_id': widget.groupId,
        'sender_id': _myId,
        'media_url': url,
        'type': 'image',
        'created_at': DateTime.now().toIso8601String(),
      });

      _scrollBottom();
    } catch (e) {
      debugPrint('Erreur image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ══════════════════════════════════════════════════════
  // تسجيل الصوت
  // ══════════════════════════════════════════════════════

  Future<void> _startRecord() async {
    final ok = await Permissions.mic();
    if (!ok) return;
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

      // ✅ يكتب في جدول group_messages
      await supabase.from('group_messages').insert({
        'group_id': widget.groupId,
        'sender_id': _myId,
        'media_url': url,
        'type': 'audio',
        'created_at': DateTime.now().toIso8601String(),
      });

      _scrollBottom();
    } catch (e) {
      debugPrint('Erreur audio: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ══════════════════════════════════════════════════════
  // APPEL
  // ══════════════════════════════════════════════════════

  Future<void> _call(String type) async {
    final channelId = const Uuid().v4();

    final callId = await CallService().startCall(
      callerId: _myId,
      receiverId: widget.groupId,
      channelId: channelId,
      type: type,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallPage(
          channelId: channelId,
          appId: 'feaef859a6c740ee9880322144128c96',
          callId: callId ?? '',
          isVoiceOnly: type == 'audio',
        ),
      ),
    );
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.groupName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('${_sendersInfo.length} membres',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _call('audio'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _call('video'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(color: _primary),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                // ✅ جميع السجلات هي رسائل (لا توجد سجلات عضوية هنا)
                final msgs = snapshot.data ?? [];

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline,
                              size: 40, color: _primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun message pour l\'instant\nSoyez le premier a ecrire !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final isMe = m['sender_id'] == _myId;
                    final senderId = m['sender_id']?.toString() ?? '';
                    final senderInfo = _sendersInfo[senderId] ?? {};
                    final senderName = (senderInfo['name'] ??
                            senderInfo['full_name'] ??
                            'Membre')
                        .toString();
                    final senderAvatar =
                        senderInfo['avatar_url']?.toString();

                    return _buildMessageBubble(
                      m: m,
                      isMe: isMe,
                      senderName: senderName,
                      senderAvatar: senderAvatar,
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          _buildInputBar(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // MESSAGE BUBBLE
  // ══════════════════════════════════════════════════════

  Widget _buildMessageBubble({
    required Map m,
    required bool isMe,
    required String senderName,
    String? senderAvatar,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildMiniAvatar(senderName, senderAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(m, isMe),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(m['created_at']?.toString()),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // أنواع الرسائل
  // ══════════════════════════════════════════════════════

  Widget _buildMessageContent(Map m, bool isMe) {
    switch (m['type']) {
      case 'text':
        return Text(
          m['content'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );

      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            m['media_url'] ?? '',
            width: 200,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                  width: 200,
                  height: 150,
                  child: Center(
                      child: CircularProgressIndicator(color: _primary)));
            },
            errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey),
          ),
        );

      case 'audio':
        final msgId = m['id']?.toString() ?? '';
        final isPlaying = _playingId == msgId;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                if (isPlaying) {
                  await _player.stop();
                  setState(() => _playingId = null);
                } else {
                  await _player.play(UrlSource(m['media_url']));
                  setState(() => _playingId = msgId);
                  _player.onPlayerComplete.listen((_) {
                    if (mounted) setState(() => _playingId = null);
                  });
                }
              },
              child: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: isMe ? Colors.white : _primary,
                size: 36,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'En cours...' : 'Message vocal',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isPlaying)
                  Text(
                    'Appuyez pour ecouter',
                    style: TextStyle(
                      color: isMe
                          ? Colors.white70
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════
  // INPUT BAR
  // ══════════════════════════════════════════════════════

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _sendImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: _primary, size: 22),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _isRecording ? _stopRecord : _startRecord,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.withOpacity(0.1)
                      : _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  color: _isRecording ? Colors.red : _primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Message au groupe...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: _bg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendText(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendText,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
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

  Widget _buildMiniAvatar(String nom, String? avatarUrl) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _primary.withOpacity(0.2),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            )
          : null,
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

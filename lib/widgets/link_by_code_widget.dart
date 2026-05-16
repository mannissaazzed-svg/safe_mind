import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkByCodeWidget extends StatefulWidget {
  final SupabaseClient supabase;
  final String currentRole;
  final Future<void> Function() onLinked; 

  const LinkByCodeWidget({
    super.key,
    required this.supabase,
    required this.currentRole,
    required this.onLinked,
  });

  @override
  State<LinkByCodeWidget> createState() => _LinkByCodeWidgetState();
}

class _LinkByCodeWidgetState extends State<LinkByCodeWidget> {
  final _codeCtrl = TextEditingController();
  bool _isLinking = false;
  String? _error;
  String? _successName;

  Future<void> _link() async {
  final code = _codeCtrl.text.trim().toUpperCase();
  if (code.length != 8) {
    setState(() => _error = '');
    return;
  }

  setState(() { _isLinking = true; _error = null; _successName = null; });

  try {
    final myId = widget.supabase.auth.currentUser?.id;
    if (myId == null) return;

    final targetRole = widget.currentRole == 'caregiver' ? 'patient' : 'caregiver';

    final results = await widget.supabase
        .from('users')
        .select('id, full_name, role')
        .eq('role', targetRole);

    
    final list = results as List;
    Map<String, dynamic>? match;
    for (final u in list) {
      final uid = u['id'] as String;
      if (uid.length >= 8 && uid.substring(0, 8).toUpperCase() == code) {
        match = u as Map<String, dynamic>;
        break;
      }
    }

    if (match == null) {
      setState(() => _error = 'Aucun utilisateur n a été trouvé avec ce code');
      return;
    }

    final targetId   = match['id'] as String;
    final targetName = match['full_name'] as String? ?? 'utilisateur';

   
    await widget.supabase
        .from('users')
        .update({'linked_to': targetId})
        .eq('id', myId);

    await widget.supabase
        .from('users')
        .update({'linked_to': myId})
        .eq('id', targetId);

    setState(() => _successName = targetName);
    _codeCtrl.clear();
    await widget.onLinked();

  } catch (e) {
    
    setState(() => _error = ' erreur : ${e.toString()}' );
  } finally {
    if (mounted) setState(() => _isLinking = false);
  }
}

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isCaregiver = widget.currentRole == 'caregiver';
    final color = isCaregiver ? const Color(0xFF419AFF) : const Color(0xFF1D9E75);
    final hint  = isCaregiver ? 'Saisir le code patient ' : 'Saisir le code accompagnateur ';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                maxLength: 8,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() { _error = null; _successName = null; }),
                decoration: InputDecoration(
                  hintText: hint,
                  counterText: '',
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: color),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLinking ? null : _link,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLinking
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.link, color: Colors.white),
              ),
            ),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13))),
          ]),
        ],

        if (_successName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ' Lié avec succès à $_successName',
                  style: const TextStyle(
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
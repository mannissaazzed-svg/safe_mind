import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════
// Page Fichiers Patient — SafeMind
// Rфuploader PDF, Excel, Images et tous types de fichiers
// ═══════════════════════════════════════════════════════

class PatientFilesPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  const PatientFilesPage({super.key, required this.patient});

  @override
  State<PatientFilesPage> createState() => _PatientFilesPageState();
}

class _PatientFilesPageState extends State<PatientFilesPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _files   = [];
  bool _isLoading   = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  static const Color _primary = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('patient_files')
          .select()
          .eq('patient_id', widget.patient['id'])
          .order('created_at', ascending: false);
      setState(() {
        _files    = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Upload fichier ─────────────────────────────────
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final uid = _supabase.auth.currentUser!.id;
      final total = result.files.length;

      for (int i = 0; i < total; i++) {
        final f    = result.files[i];
        final file = File(f.path!);
        final ext  = f.extension?.toLowerCase() ?? '';
        final name = '${widget.patient['id']}_${DateTime.now().millisecondsSinceEpoch}_${f.name}';
        final type = _getFileType(ext);

        // Upload vers Storage
        await _supabase.storage
            .from('patient-files')
            .upload(name, file);
        final url = _supabase.storage
            .from('patient-files')
            .getPublicUrl(name);

        // Taille lisible
        final size = _formatSize(f.size);

        // Enregistrer en DB
        await _supabase.from('patient_files').insert({
          'medecin_id':   uid,
          'patient_id':   widget.patient['id'],
          'patient_name': widget.patient['name'],
          'file_name':    f.name,
          'file_url':     url,
          'file_type':    type,
          'file_size':    size,
        });

        setState(() => _uploadProgress = (i + 1) / total);
      }

      _showSuccess('${total} fichier(s) téléchargé(s) avec succès !');
      _loadFiles();
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() { _isUploading = false; _uploadProgress = 0; });
    }
  }

  // ── Ouvrir fichier ─────────────────────────────────
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Supprimer fichier ──────────────────────────────
  Future<void> _deleteFile(Map<String, dynamic> f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${f['file_name']}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _supabase
        .from('patient_files')
        .delete()
        .eq('id', f['id']);
    _loadFiles();
  }

  // ── Helpers ────────────────────────────────────────
  String _getFileType(String ext) {
    if (['pdf'].contains(ext)) return 'pdf';
    if (['xls', 'xlsx', 'csv'].contains(ext)) return 'excel';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['doc', 'docx'].contains(ext)) return 'word';
    return 'other';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _fileColor(String type) {
    switch (type) {
      case 'pdf':   return Colors.red.shade600;
      case 'excel': return Colors.green.shade600;
      case 'image': return Colors.blue.shade600;
      case 'word':  return Colors.blue.shade800;
      default:      return Colors.grey.shade600;
    }
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf':   return Icons.picture_as_pdf_outlined;
      case 'excel': return Icons.table_chart_outlined;
      case 'image': return Icons.image_outlined;
      case 'word':  return Icons.description_outlined;
      default:      return Icons.insert_drive_file_outlined;
    }
  }

  String _fileLabel(String type) {
    switch (type) {
      case 'pdf':   return 'PDF';
      case 'excel': return 'Excel';
      case 'image': return 'Image';
      case 'word':  return 'Word';
      default:      return 'Fichier';
    }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fichiers',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            Text(widget.patient['name'] ?? '',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre upload ──────────────────────────
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: _primary, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Téléchargement... ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                          color: _primary, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: _primary.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation(_primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

          // ── Stats types de fichiers ───────────────
          if (!_isLoading && _files.isNotEmpty) _buildStats(),

          // ── Liste fichiers ────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _files.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: _loadFiles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _files.length,
                          itemBuilder: (_, i) =>
                              _buildFileCard(_files[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: _isUploading ? null : _pickAndUpload,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Ajouter fichiers',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────
  Widget _buildStats() {
    final types = ['pdf', 'excel', 'image', 'word', 'other'];
    final counts = {
      for (var t in types)
        t: _files.where((f) => f['file_type'] == t).length
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: types
            .where((t) => (counts[t] ?? 0) > 0)
            .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _fileColor(t).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(_fileIcon(t),
                          color: _fileColor(t), size: 14),
                      const SizedBox(width: 4),
                      Text('${counts[t]} ${_fileLabel(t)}',
                          style: TextStyle(
                              color: _fileColor(t),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Carte fichier ──────────────────────────────────
  Widget _buildFileCard(Map<String, dynamic> f) {
    final type    = f['file_type'] ?? 'other';
    final color   = _fileColor(type);
    final icon    = _fileIcon(type);
    final dt      = DateTime.tryParse(f['created_at'] ?? '')?.toLocal();
    final dateStr = dt != null
        ? DateFormat('d MMM yyyy — HH:mm').format(dt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          f['file_name'] ?? 'Fichier',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_fileLabel(type),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              if (f['file_size'] != null)
                Text(f['file_size'],
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            Text(dateStr,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ouvrir ────────────────────────────
            GestureDetector(
              onTap: () => _openFile(f['file_url'] ?? ''),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_new,
                    color: _primary, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            // ── Supprimer ─────────────────────────
            GestureDetector(
              onTap: () => _deleteFile(f),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined,
                size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucun fichier',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Ajoutez des PDF, Excel, images...',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.upload_file,
                color: Colors.white, size: 18),
            label: const Text('Ajouter des fichiers',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
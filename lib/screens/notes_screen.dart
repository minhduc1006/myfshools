import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import 'notes_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;

  const NotesScreen({
    super.key,
    required this.apiClient,
    required this.token,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool loading = true;
  String? error;
  List<NoteDto> notes = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.apiClient.getNotes(widget.token);
      if (!mounted) return;
      setState(() => notes = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openEditor([NoteDto? note]) async {
    final result = await Navigator.of(context).push<NoteDto>(
      MaterialPageRoute(
        builder: (_) => NotesEditorScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          note: note,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      final idx = notes.indexWhere((n) => n.id == result.id);
      if (idx >= 0) {
        final updated = [...notes];
        updated[idx] = result;
        notes = updated;
      } else {
        notes = [result, ...notes];
      }
    });
  }

  Future<void> _deleteNote(NoteDto note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: Text('Bạn có chắc muốn xóa "${note.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.apiClient.deleteNote(widget.token, note.id);
      if (!mounted) return;
      setState(() => notes = notes.where((n) => n.id != note.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa ghi chú.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openNoteMenu(NoteDto note) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.edit2),
              title: const Text('Sửa ghi chú'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('Xóa ghi chú', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (selected == 'edit') {
      _openEditor(note);
    } else if (selected == 'delete') {
      _deleteNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            title: 'Ghi chú',
            showBack: true,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error!),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _reload, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          itemCount: notes.length,
                          itemBuilder: (context, i) {
                            final n = notes[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(LucideIcons.stickyNote, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _openEditor(n),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 4),
                                            Text(
                                              n.preview,
                                              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      children: [
                                        Text(n.date, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                        IconButton(
                                          onPressed: () => _openNoteMenu(n),
                                          icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppColors.mutedForeground),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

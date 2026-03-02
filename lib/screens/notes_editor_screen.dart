import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

class NotesEditorScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final NoteDto? note;

  const NotesEditorScreen({
    super.key,
    required this.apiClient,
    required this.token,
    this.note,
  });

  @override
  State<NotesEditorScreen> createState() => _NotesEditorScreenState();
}

class _NotesEditorScreenState extends State<NotesEditorScreen> {
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    bodyCtrl = TextEditingController(text: widget.note?.content ?? widget.note?.preview ?? '');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = titleCtrl.text.trim();
    final content = bodyCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => error = 'Vui lòng nhập đầy đủ tiêu đề và nội dung.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final saved = widget.note == null
          ? await widget.apiClient.createNote(widget.token, title, content)
          : await widget.apiClient.updateNote(widget.token, widget.note!.id, title, content);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Không thể lưu ghi chú.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppTopBar(title: 'Chỉnh sửa ghi chú', showBack: true, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(hintText: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: bodyCtrl,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(hintText: 'Nội dung ghi chú...'),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: Text(error!, style: const TextStyle(color: Colors.red))),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.save, size: 18),
                  label: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

class ChatDetailScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final Map<String, dynamic> thread;

  const ChatDetailScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.thread,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ctrl = TextEditingController();
  bool loading = true;
  bool sending = false;
  String? error;
  List<ChatMessageDto> messages = const [];

  int get threadId => (widget.thread['id'] as num).toInt();
  bool get isGroup => widget.thread['isGroup'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.apiClient.getChatMessages(widget.token, threadId);
      if (!mounted) return;
      setState(() => messages = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      final msg = await widget.apiClient.sendChatMessage(widget.token, threadId, text);
      ctrl.clear();
      if (!mounted) return;
      setState(() => messages = [...messages, msg]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _inviteMember() async {
    final ctrl = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mời thành viên'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Nhập số điện thoại'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Mời')),
        ],
      ),
    );

    if (phone == null || phone.isEmpty) return;
    try {
      await widget.apiClient.inviteToGroup(widget.token, threadId, phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mời vào nhóm')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.thread['name'] ?? 'Chat').toString();
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          AppTopBar(title: name, showBack: true, onBack: () => Navigator.of(context).pop()),
          if (isGroup)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _inviteMember,
                    icon: const Icon(LucideIcons.userPlus2, size: 16),
                    label: const Text('Mời vào nhóm'),
                  ),
                ],
              ),
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
                            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m.fromMe;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 320),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: isMe ? null : Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(m.text, style: TextStyle(color: isMe ? Colors.white : AppColors.foreground, height: 1.35)),
                                  const SizedBox(height: 6),
                                  Text(
                                    m.time,
                                    style: TextStyle(
                                      color: (isMe ? Colors.white : AppColors.mutedForeground).withOpacity(0.75),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: AppColors.muted,
                        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      onPressed: sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

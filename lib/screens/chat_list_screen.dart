import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

class ChatListScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final void Function(String screen, [dynamic data]) onNavigate;

  const ChatListScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onNavigate,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatThreadDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getChatThreads(widget.token);
  }

  Future<void> _reload() async {
    setState(() => _future = widget.apiClient.getChatThreads(widget.token));
  }

  Future<void> _createDirect() async {
    try {
      final users = await widget.apiClient.getChatUsers(widget.token);
      if (!mounted) return;

      final selected = await showDialog<ChatUserDto>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn người để chat'),
          content: SizedBox(
            width: 420,
            child: users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Không có người dùng nào khác trong hệ thống.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.10),
                          child: Text(
                            user.avatarInitial.isEmpty ? '?' : user.avatarInitial,
                            style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text('${user.className} • ${user.phone}'),
                        onTap: () => Navigator.pop(context, user),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        ),
      );

      if (selected == null) return;

      final thread = await widget.apiClient.createDirectChat(widget.token, selected.phone);
      if (!mounted) return;
      widget.onNavigate('chat-detail', {'id': thread.id, 'name': thread.name, 'isGroup': thread.isGroup});
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    final membersCtrl = TextEditingController();

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo nhóm chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Tên nhóm'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: membersCtrl,
              decoration: const InputDecoration(hintText: 'SĐT thành viên (phân tách dấu phẩy)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameCtrl.text.trim(),
              'members': membersCtrl.text.trim(),
            }),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (data == null) return;
    final name = (data['name'] ?? '').trim();
    if (name.isEmpty) return;
    final phones = ((data['members'] ?? '').split(',')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    try {
      final thread = await widget.apiClient.createGroupChat(widget.token, name, phones);
      if (!mounted) return;
      widget.onNavigate('chat-detail', {'id': thread.id, 'name': thread.name, 'isGroup': thread.isGroup});
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Chat', showSearch: true),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createDirect,
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text('Chọn người chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(LucideIcons.users, size: 16),
                    label: const Text('Tạo nhóm'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ChatThreadDto>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snapshot.error.toString()),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: _reload, child: const Text('Thử lại')),
                      ],
                    ),
                  );
                }

                final threads = snapshot.data ?? const [];
                if (threads.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 92),
                      children: const [
                        AppCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(LucideIcons.messagesSquare, color: AppColors.mutedForeground),
                                SizedBox(height: 12),
                                Text(
                                  'Chưa có cuộc trò chuyện nào.\nHãy chọn một người dùng để bắt đầu chat.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 92),
                    itemCount: threads.length,
                    itemBuilder: (context, i) {
                      final t = threads[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => widget.onNavigate('chat-detail', {
                            'id': t.id,
                            'name': t.name,
                            'isGroup': t.isGroup,
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AppCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.secondary.withValues(alpha: 0.10),
                                  child: Text(
                                    t.participantInitial.isEmpty ? '?' : t.participantInitial,
                                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                                          if (t.isGroup)
                                            const Icon(LucideIcons.users, size: 14, color: AppColors.mutedForeground),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t.lastMessage.isEmpty ? 'Chưa có tin nhắn' : t.lastMessage,
                                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(t.lastTime, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    if (t.unreadCount > 0)
                                      AppBadge('${t.unreadCount}', textColor: Colors.white, background: AppColors.primary),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.mutedForeground),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

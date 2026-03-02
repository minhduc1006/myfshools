import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

class HomeworkScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final void Function(String screen, [dynamic data]) onNavigate;

  const HomeworkScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onNavigate,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  int tab = 0;
  bool loading = true;
  String? error;
  List<HomeworkItemDto> items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.apiClient.getHomeworks(widget.token);
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<HomeworkItemDto> get filtered {
    if (tab == 1) return items.where((i) => i.status == 'pending' || i.status == 'overdue').toList();
    if (tab == 2) return items.where((i) => i.status == 'submitted').toList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Bài tập', showSearch: true),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                _TabPill(label: 'Tất cả', active: tab == 0, onTap: () => setState(() => tab = 0)),
                const SizedBox(width: 10),
                _TabPill(label: 'Đang làm', active: tab == 1, onTap: () => setState(() => tab = 1)),
                const SizedBox(width: 10),
                _TabPill(label: 'Đã nộp', active: tab == 2, onTap: () => setState(() => tab = 2)),
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
                            ElevatedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 92),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final it = filtered[index];
                            final color = it.status == 'submitted'
                                ? AppColors.accent
                                : (it.status == 'overdue' ? AppColors.destructive : AppColors.primary);
                            final badgeText = it.status == 'submitted' ? 'Đã nộp' : (it.status == 'overdue' ? 'Quá hạn' : 'Chưa nộp');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => widget.onNavigate('homework-detail', it.toMap()),
                                borderRadius: BorderRadius.circular(12),
                                child: AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(it.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                const SizedBox(height: 4),
                                                Text(it.subject, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          AppBadge(badgeText, textColor: color, background: color.withOpacity(0.10)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
                                          const SizedBox(width: 6),
                                          Text('Hạn: ${it.due}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                                          const Spacer(),
                                          Text(it.progress, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                                          const SizedBox(width: 6),
                                          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.mutedForeground),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: active ? Colors.white : AppColors.foreground, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

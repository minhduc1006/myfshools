import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

class HomeworkDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const HomeworkDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] as String?) ?? 'pending';
    final color = status == 'submitted' ? AppColors.accent : (status == 'overdue' ? AppColors.destructive : AppColors.primary);
    final badgeText = status == 'submitted' ? 'Đã nộp' : (status == 'overdue' ? 'Quá hạn' : 'Chưa nộp');

    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          AppTopBar(title: 'Chi tiết bài tập', showBack: true, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(item['subject'] ?? '', style: const TextStyle(color: AppColors.mutedForeground)),
                                ],
                              ),
                            ),
                            AppBadge(badgeText, textColor: color, background: color.withOpacity(0.10)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
                            const SizedBox(width: 8),
                            Text('Hạn nộp: ${item['due']}', style: const TextStyle(color: AppColors.mutedForeground)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const AppCard(
                    child: Text(
                      'Nộp báo cáo (PDF) và source code (nếu có). Trình bày rõ ràng theo yêu cầu môn học.',
                      style: TextStyle(color: AppColors.mutedForeground, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tệp đính kèm', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Row(
                      children: const [
                        Icon(LucideIcons.fileText, size: 18, color: AppColors.secondary),
                        SizedBox(width: 10),
                        Expanded(child: Text('assignment_requirements.pdf', style: TextStyle(fontWeight: FontWeight.w700))),
                        Icon(LucideIcons.download, size: 18, color: AppColors.mutedForeground),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Nộp bài'),
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

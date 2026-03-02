import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;

  const BottomNav({super.key, required this.activeTab, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      ('dashboard', LucideIcons.home, 'Trang chủ'),
      ('timetable', LucideIcons.calendar, 'Thời khóa biểu'),
      ('homework', LucideIcons.clipboardList, 'Bài tập'),
      ('chat', LucideIcons.messageSquare, 'Chat'),
      ('profile', LucideIcons.user, 'Cá nhân'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          final isActive = activeTab == t.$1;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTabChange(t.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t.$2,
                    size: 20,
                    color: isActive ? AppColors.primary : AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.$3,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppColors.primary : AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

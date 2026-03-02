import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onSkip, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int current = 0;

  static const slides = [
    _Slide(LucideIcons.bookOpen, 'Quản lý bài tập dễ dàng', 'Theo dõi tất cả bài tập, deadline và nộp bài trực tuyến', AppColors.primary),
    _Slide(LucideIcons.calendar, 'Thời khóa biểu thông minh', 'Nhận thông báo lịch học, phòng học và giảng viên', AppColors.secondary),
    _Slide(LucideIcons.messageSquare, 'Kết nối cùng lớp', 'Chat nhóm, chia sẻ tài liệu và hỗ trợ lẫn nhau', AppColors.accent),
  ];

  void next() {
    if (current < slides.length - 1) {
      setState(() => current++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = slides[current];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s.icon, size: 128, color: s.color),
                    const SizedBox(height: 32),
                    Text(s.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Text(
                      s.desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final active = i == current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: active ? 32 : 8,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.muted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (current > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => current--),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('Quay lại'),
                          ),
                        ),
                      if (current > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(current == slides.length - 1 ? 'Bắt đầu' : 'Tiếp theo'),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronRight, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (current == 0) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: const Text('Bỏ qua', style: TextStyle(color: AppColors.mutedForeground)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Slide(this.icon, this.title, this.desc, this.color);
}

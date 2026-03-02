import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color? background;

  const AppBadge(this.text, {super.key, this.textColor, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppColors.accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.accent,
        ),
      ),
    );
  }
}

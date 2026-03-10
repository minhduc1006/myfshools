import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showSearch;
  final bool showMenu;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onMenu;
  final VoidCallback? onMore;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSearch = false,
    this.showMenu = false,
    this.onBack,
    this.onSearch,
    this.onMenu,
    this.onMore,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                if (showMenu && onMenu != null)
                  IconButton(
                    icon: const Icon(LucideIcons.menu, color: Colors.white),
                    onPressed: onMenu,
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (showSearch && onSearch != null)
                  IconButton(
                    icon: const Icon(LucideIcons.search, color: Colors.white, size: 20),
                    onPressed: onSearch,
                  ),
                if (onMore != null)
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, color: Colors.white, size: 20),
                    onPressed: onMore,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

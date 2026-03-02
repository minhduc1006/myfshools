import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFF37021); // FPT Orange
  static const secondary = Color(0xFF0054A6); // FPT Blue
  static const accent = Color(0xFF00A651); // FPT Green

  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF2C2C2C);

  static const muted = Color(0xFFF8F9FA);
  static const mutedForeground = Color(0xFF717182);

  static const border = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const destructive = Color(0xFFD4183D);

  static const sidebar = muted;
}

class AppTheme {
  static const radius = 12.0; // rounded-xl like Tailwind (approx)

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        background: AppColors.background,
        surface: AppColors.background,
        error: AppColors.destructive,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: AppColors.foreground,
        onSurface: AppColors.foreground,
      ),
      scaffoldBackgroundColor: AppColors.muted,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.foreground,
        displayColor: AppColors.foreground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.foreground,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radius)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F3F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}

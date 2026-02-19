import 'package:flutter/material.dart';

class AppPalette {
  static const teal = Color(0xFF0DF2DF);
  static const tealDark = Color(0xFF0ABFB0);
  static const success = Color(0xFF22C55E);

  static const darkBg = Color(0xFF081010);
  static const darkSurface = Color(0xFF102321);
  static const darkCard = Color(0xFF162A28);

  static const lightBg = Color(0xFFF2F7F7);
  static const lightSurface = Color(0xFFDDEBED);
  static const lightCard = Color(0xFFF9FCFC);

  static const danger = Color(0xFFFF6C8E);

  static const glassBorderDark = Color.fromRGBO(255, 255, 255, 0.11);
  static const glassBorderLight = Color.fromRGBO(8, 34, 30, 0.14);
}

extension AppThemeTokens on ThemeData {
  bool get isDark => brightness == Brightness.dark;

  Color get tealAccent => AppPalette.teal;

  Color get appBackground => isDark ? AppPalette.darkBg : AppPalette.lightBg;

  Color get appSurface =>
      isDark ? AppPalette.darkSurface : AppPalette.lightSurface;

  Color get glassBorder =>
      isDark ? AppPalette.glassBorderDark : AppPalette.glassBorderLight;

  Color get glassFill => isDark
      ? const Color.fromRGBO(255, 255, 255, 0.04)
      : const Color.fromRGBO(255, 255, 255, 0.64);

  Color get subduedText =>
      isDark ? const Color(0xFF8EA3AF) : const Color(0xFF627482);

  Color get taskCardTint => isDark
      ? const Color.fromRGBO(8, 25, 22, 0.65)
      : const Color.fromRGBO(255, 255, 255, 0.75);
}

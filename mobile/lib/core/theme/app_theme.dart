import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.tealDark,
      onPrimary: Color(0xFF002322),
      secondary: AppPalette.success,
      onSecondary: Color(0xFF032016),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: AppPalette.lightSurface,
      onSurface: Color(0xFF0D2230),
      tertiary: Color(0xFF6FE6DD),
      onTertiary: Color(0xFF052522),
      surfaceContainerHighest: Color(0xFFE6EFF1),
      onSurfaceVariant: Color(0xFF607684),
      outline: Color(0xFF9CB2BA),
      outlineVariant: Color(0xFFC3D2D8),
      inverseSurface: Color(0xFF16302F),
      onInverseSurface: Color(0xFFE8F4F4),
      inversePrimary: Color(0xFF4CF0E2),
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppPalette.teal,
    );

    return _buildBaseTheme(scheme, Brightness.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.teal,
      onPrimary: Color(0xFF002A26),
      secondary: AppPalette.success,
      onSecondary: Color(0xFF042214),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: AppPalette.darkSurface,
      onSurface: Color(0xFFE4F0EE),
      tertiary: Color(0xFF75F1E8),
      onTertiary: Color(0xFF003734),
      surfaceContainerHighest: Color(0xFF1A2F2D),
      onSurfaceVariant: Color(0xFF9FB4B1),
      outline: Color(0xFF486260),
      outlineVariant: Color(0xFF2E4543),
      inverseSurface: Color(0xFFE1F0EE),
      onInverseSurface: Color(0xFF122A28),
      inversePrimary: Color(0xFF007E77),
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppPalette.teal,
    );

    return _buildBaseTheme(scheme, Brightness.dark);
  }

  static ThemeData _buildBaseTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? AppPalette.darkBg
          : AppPalette.lightBg,
      fontFamily: 'Inter',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? const Color.fromRGBO(20, 37, 35, 0.72)
            : const Color.fromRGBO(255, 255, 255, 0.78),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: brightness == Brightness.dark
                ? const Color.fromRGBO(255, 255, 255, 0.10)
                : const Color.fromRGBO(18, 50, 47, 0.12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color.fromRGBO(0, 0, 0, 0.22)
            : const Color.fromRGBO(255, 255, 255, 0.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? const Color.fromRGBO(255, 255, 255, 0.10)
                : const Color.fromRGBO(15, 50, 47, 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: brightness == Brightness.dark
                ? const Color.fromRGBO(255, 255, 255, 0.10)
                : const Color.fromRGBO(15, 50, 47, 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppPalette.teal, width: 1.4),
        ),
        hintStyle: TextStyle(
          color: brightness == Brightness.dark
              ? const Color(0xFF7D9397)
              : const Color(0xFF73848E),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        color: WidgetStatePropertyAll(
          brightness == Brightness.dark
              ? const Color.fromRGBO(255, 255, 255, 0.05)
              : const Color.fromRGBO(255, 255, 255, 0.75),
        ),
        side: BorderSide(
          color: brightness == Brightness.dark
              ? const Color.fromRGBO(255, 255, 255, 0.08)
              : const Color.fromRGBO(16, 52, 48, 0.16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF102625)
            : const Color(0xFF113836),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      dividerColor: brightness == Brightness.dark
          ? const Color.fromRGBO(255, 255, 255, 0.08)
          : const Color.fromRGBO(17, 55, 50, 0.12),
    );
  }
}

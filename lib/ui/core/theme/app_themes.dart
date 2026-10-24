import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Curated calm Material 3 seeds (flutter-ai-ui-skill palettes + journal-friendly).
enum AppThemeId {
  tealFocus,
  wellnessPurple,
  softEarth,
  oceanBlue,
  charcoalMinimal,
  warmSand,
}

class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.nameZh,
    required this.seed,
  });

  final AppThemeId id;
  final String nameZh;
  final Color seed;
}

class AppThemes {
  static const List<AppThemeOption> all = [
    AppThemeOption(
      id: AppThemeId.tealFocus,
      nameZh: '青绿专注',
      seed: Color(0xFF0D9488),
    ),
    AppThemeOption(
      id: AppThemeId.wellnessPurple,
      nameZh: '静心紫',
      seed: Color(0xFF7C3AED),
    ),
    AppThemeOption(
      id: AppThemeId.softEarth,
      nameZh: '柔和泥土',
      seed: Color(0xFF15803D),
    ),
    AppThemeOption(
      id: AppThemeId.oceanBlue,
      nameZh: '海洋蓝',
      seed: Color(0xFF0369A1),
    ),
    AppThemeOption(
      id: AppThemeId.charcoalMinimal,
      nameZh: '炭黑极简',
      seed: Color(0xFF18181B),
    ),
    AppThemeOption(
      id: AppThemeId.warmSand,
      nameZh: '暖沙',
      seed: Color(0xFFCA8A04),
    ),
  ];

  static AppThemeOption byId(AppThemeId id) =>
      all.firstWhere((o) => o.id == id, orElse: () => all.first);

  static ThemeData light(AppThemeId id) =>
      _base(byId(id).seed, Brightness.light);

  static ThemeData dark(AppThemeId id) =>
      _base(byId(id).seed, Brightness.dark);

  static ThemeData _base(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final baseText = GoogleFonts.mulishTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    // Soft Rounded pairing (skill): Quicksand display + Mulish body.
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.1,
        color: scheme.onSurface,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      bodyLarge: GoogleFonts.mulish(fontSize: 16, height: 1.45),
      bodyMedium: GoogleFonts.mulish(fontSize: 14, height: 1.4),
      bodySmall: GoogleFonts.mulish(fontSize: 12, height: 1.35),
      labelLarge: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'catppuccin.dart';

class AppTheme {
  AppTheme._();

  // status colors
  static const Color online = Colors.green;
  static const Color offline = Colors.red;

  static CatppuccinPalette getPalette(String flavor) {
    switch (flavor.toLowerCase()) {
      case 'latte':
        return CatppuccinPalette.latte;
      case 'frappe':
        return CatppuccinPalette.frappe;
      case 'macchiato':
        return CatppuccinPalette.macchiato;
      case 'mocha':
      default:
        return CatppuccinPalette.mocha;
    }
  }

  static ThemeData getTheme(
    String flavor,
    String accentName, {
    Color? customAccent,
    bool usePureBlack = false,
  }) {
    final palette = getPalette(flavor);
    final accentColor = customAccent ?? palette.getColorByName(accentName);
    return fromPalette(
      palette,
      accent: accentColor,
      usePureBlack: usePureBlack,
    );
  }

  // default theme
  static ThemeData get darkTheme => getTheme('mocha', 'mauve');

  // accent overrides which palette color to use as the primary accent
  // defaults to palette.mauve
  static ThemeData fromPalette(
    CatppuccinPalette palette, {
    Color? accent,
    bool usePureBlack = false,
  }) {
    final primary = accent ?? palette.mauve;
    final isDark = palette.brightness == Brightness.dark;

    final Color resolvedBase = (isDark && usePureBlack)
        ? Colors.black
        : palette.base;
    final Color resolvedSurface = (isDark && usePureBlack)
        ? const Color(0xFF0F0F12)
        : palette.surface0;
    final Color resolvedMantle = (isDark && usePureBlack)
        ? Colors.black
        : palette.mantle;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: resolvedBase,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: primary,
        onPrimary: isDark ? palette.crust : palette.base,
        secondary: palette.sapphire,
        onSecondary: isDark ? palette.crust : palette.base,
        tertiary: palette.peach,
        onTertiary: isDark ? palette.crust : palette.base,
        error: palette.red,
        onError: isDark ? palette.crust : palette.base,
        surface: resolvedBase,
        onSurface: palette.text,
        onSurfaceVariant: palette.subtext0,
        surfaceContainerHighest: resolvedSurface,
        outline: palette.overlay0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: resolvedBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: palette.text,
        ),
        iconTheme: IconThemeData(color: palette.text),
      ),
      cardTheme: CardThemeData(
        color: resolvedSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: resolvedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(color: palette.overlay1, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? palette.crust : palette.base,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: isDark ? palette.crust : palette.base,
        elevation: 4,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: resolvedMantle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: resolvedSurface,
        contentTextStyle: GoogleFonts.inter(color: palette.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: palette.surface1, thickness: 0.5),
      textTheme: _buildTextTheme(palette),
      iconTheme: IconThemeData(color: palette.subtext0),
    );
  }

  static TextTheme _buildTextTheme(CatppuccinPalette p) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: p.subtext1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: p.text,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: p.subtext0,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: p.overlay1,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
    );
  }
}

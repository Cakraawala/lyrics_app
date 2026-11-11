import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimal light / OLED-dark themes tuned for long reading sessions.
class AppTheme {
  const AppTheme._();

  static const accent = Color(0xFF7C6CF0);
  static const accentDark = Color(0xFF9D90FF);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ).copyWith(
          primary: accent,
          surface: const Color(0xFFFAFAF8),
          onSurface: const Color(0xFF1D1D21),
          onSurfaceVariant: const Color(0xFF6B6B74),
          surfaceContainerHighest: const Color(0xFFEFEFF2),
          outlineVariant: const Color(0xFFE3E3E8),
        ),
      );

  /// True-black background for OLED; text is soft off-white, not pure white,
  /// to reduce glare during long reads.
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accentDark,
          surface: Colors.black,
          onSurface: const Color(0xFFDCDCE1),
          onSurfaceVariant: const Color(0xFF8E8E98),
          surfaceContainerHighest: const Color(0xFF16161A),
          outlineVariant: const Color(0xFF232328),
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Soft, highly legible serif for the lyric body.
  static TextStyle readerStyle(BuildContext context, double size) =>
      GoogleFonts.literata(
        fontSize: size,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

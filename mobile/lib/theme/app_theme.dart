import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lime accent shared by both themes, matching the assistant mock.
const limeAccent = Color(0xFFC6F533);

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.muted,
    required this.bubbleMine,
    required this.bubbleMineText,
    required this.bubbleTheirs,
    required this.bubbleTheirsText,
  });

  final Color background;
  final Color surface;
  final Color muted;
  final Color bubbleMine;
  final Color bubbleMineText;
  final Color bubbleTheirs;
  final Color bubbleTheirsText;

  static const dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1E1E1E),
    muted: Color(0xFF9A9A9A),
    bubbleMine: limeAccent,
    bubbleMineText: Color(0xFF111111),
    bubbleTheirs: Color(0xFF1E1E1E),
    bubbleTheirsText: Color(0xFFFFFFFF),
  );

  static const light = AppPalette(
    background: Color(0xFFF6F7F4),
    surface: Color(0xFFFFFFFF),
    muted: Color(0xFF6B6B6B),
    bubbleMine: limeAccent,
    bubbleMineText: Color(0xFF111111),
    bubbleTheirs: Color(0xFFE8E8E8),
    bubbleTheirsText: Color(0xFF111111),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppPalette.dark;
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? muted,
    Color? bubbleMine,
    Color? bubbleMineText,
    Color? bubbleTheirs,
    Color? bubbleTheirsText,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      muted: muted ?? this.muted,
      bubbleMine: bubbleMine ?? this.bubbleMine,
      bubbleMineText: bubbleMineText ?? this.bubbleMineText,
      bubbleTheirs: bubbleTheirs ?? this.bubbleTheirs,
      bubbleTheirsText: bubbleTheirsText ?? this.bubbleTheirsText,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      bubbleMine: Color.lerp(bubbleMine, other.bubbleMine, t)!,
      bubbleMineText: Color.lerp(bubbleMineText, other.bubbleMineText, t)!,
      bubbleTheirs: Color.lerp(bubbleTheirs, other.bubbleTheirs, t)!,
      bubbleTheirsText: Color.lerp(bubbleTheirsText, other.bubbleTheirsText, t)!,
    );
  }
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light, AppPalette.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark, AppPalette.dark);

ThemeData _buildTheme(Brightness brightness, AppPalette palette) {
  final isDark = brightness == Brightness.dark;
  final onBg = isDark ? Colors.white : const Color(0xFF111111);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: limeAccent,
      brightness: brightness,
      primary: limeAccent,
      onPrimary: const Color(0xFF111111),
      secondary: limeAccent,
      surface: palette.surface,
      onSurface: onBg,
    ),
    extensions: [palette],
  );
  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: onBg,
    displayColor: onBg,
  );
  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      elevation: 0,
      foregroundColor: onBg,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onBg,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      labelStyle: TextStyle(color: onBg),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: limeAccent,
        foregroundColor: const Color(0xFF111111),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: limeAccent),
    ),
    iconTheme: IconThemeData(color: onBg),
    dividerColor: palette.muted.withOpacity(0.24),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// App Theme Configuration
class AppTheme {
  // Brand colours (Spendroo Business Files/Brand/Spendroo Logo/README.md)
  static const Color primaryColor = Color(0xFF0B2D5E); // Trust Navy
  static const Color secondaryColor = Color(0xFF2DB86F); // Money Green
  static const Color accentColor = Color(0xFFF5B530); // Prosperity Gold
  static const Color mintColor = Color(0xFF5BE3A0); // Growth Mint
  /// Navy is too dark to read on the dark theme's background; this lighter
  /// shade of it takes the primary role there.
  static const Color darkPrimaryColor = Color(0xFF8FB2EA);

  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = secondaryColor;
  static const Color warningColor = accentColor;

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF111827);
  static const Color darkSurfaceColor = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Covers Bengali and Latin
  static const String fontFamily = 'HindSiliguri';

  static ThemeData lightTheme = _build(
    brightness: Brightness.light,
    background: backgroundColor,
    scheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
  );

  static ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    background: darkBackgroundColor,
    scheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: darkSurfaceColor,
      error: errorColor,
      onPrimary: primaryColor,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onError: Colors.white,
    ),
  );

  static ThemeData _build({required Brightness brightness, required Color background, required ColorScheme scheme}) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/fields.dart';
import 'design/tokens.dart';

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

  static const Color backgroundColor = Color(0xFFF2F5FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFD93F4C);
  static const Color successColor = secondaryColor;
  static const Color warningColor = accentColor;

  // Text Colors
  static const Color textPrimary = Color(0xFF0E1B30);
  static const Color textSecondary = Color(0xFF5B6B84);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF0A1322);
  static const Color darkSurfaceColor = Color(0xFF131F33);
  static const Color darkTextPrimary = Color(0xFFF1F5FB);

  /// Drawn for Bangla and Latin together, so both languages read as one family
  static const String fontFamily = 'AnekBangla';

  static ThemeData lightTheme = _build(
    colors: AppColors.light,
    scheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE7F8),
      onPrimaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCE7F8),
      onSecondaryContainer: primaryColor,
      tertiary: accentColor,
      onTertiary: primaryColor,
      surface: surfaceColor,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Color(0xFFF7F9FC),
      surfaceContainerHigh: Color(0xFFF2F5FA),
      surfaceContainerHighest: Color(0xFFE9EEF6),
      outline: Color(0xFFB9C4D6),
      outlineVariant: Color(0xFFE2E8F1),
      error: errorColor,
      onError: Colors.white,
      errorContainer: Color(0xFFFCE4E6),
      onErrorContainer: Color(0xFF8E1B26),
    ),
  );

  static ThemeData darkTheme = _build(
    colors: AppColors.dark,
    scheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      onPrimary: primaryColor,
      primaryContainer: Color(0xFF1D355C),
      onPrimaryContainer: Color(0xFFD6E3F9),
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1D355C),
      onSecondaryContainer: Color(0xFFD6E3F9),
      tertiary: accentColor,
      onTertiary: primaryColor,
      surface: darkSurfaceColor,
      onSurface: darkTextPrimary,
      onSurfaceVariant: Color(0xFF9FB0C8),
      surfaceContainerLowest: Color(0xFF0A1322),
      surfaceContainerLow: darkSurfaceColor,
      surfaceContainer: Color(0xFF17253C),
      surfaceContainerHigh: Color(0xFF1B2A43),
      surfaceContainerHighest: Color(0xFF22324D),
      outline: Color(0xFF41536F),
      outlineVariant: Color(0xFF22324D),
      error: Color(0xFFFF7A84),
      onError: Color(0xFF4A0A12),
      errorContainer: Color(0xFF4A1820),
      onErrorContainer: Color(0xFFFFD9DC),
    ),
  );

  static TextTheme _textTheme(Color ink, Color muted) {
    TextStyle style(double size, FontWeight weight, {double height = 1.35, Color? color, double spacing = 0}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? ink,
        );
    return TextTheme(
      displaySmall: style(40, FontWeight.w700, height: 1.1, spacing: -0.5),
      headlineMedium: style(32, FontWeight.w700, height: 1.15, spacing: -0.3),
      headlineSmall: style(26, FontWeight.w700, height: 1.2, spacing: -0.2),
      titleLarge: style(20, FontWeight.w600, height: 1.25),
      titleMedium: style(16, FontWeight.w600, height: 1.3),
      titleSmall: style(14, FontWeight.w600, height: 1.3),
      bodyLarge: style(16, FontWeight.w400, height: 1.45),
      bodyMedium: style(14, FontWeight.w400, height: 1.45),
      bodySmall: style(12, FontWeight.w400, height: 1.4, color: muted),
      labelLarge: style(15, FontWeight.w600, height: 1.2),
      labelMedium: style(13, FontWeight.w500, height: 1.2, color: muted),
      labelSmall: style(12, FontWeight.w500, height: 1.2, color: muted),
    );
  }

  static ThemeData _build({required ColorScheme scheme, required AppColors colors}) {
    final dark = scheme.brightness == Brightness.dark;
    final text = _textTheme(scheme.onSurface, colors.muted);
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    // A hairline at rest; the accent colour and a soft ring around it on focus or error
    FieldBorder fieldBorder(Color color, {bool active = false}) => FieldBorder(
          borderSide: BorderSide(color: color, width: active ? 1.5 : 1),
          glow: active ? color.withValues(alpha: dark ? 0.24 : 0.14) : color.withValues(alpha: 0),
        );
    Color byState(Set<WidgetState> states, Color rest) => states.contains(WidgetState.error)
        ? scheme.error
        : (states.contains(WidgetState.focused) ? scheme.primary : rest);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: colors.paper,
      fontFamily: fontFamily,
      colorScheme: scheme,
      textTheme: text,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: controlShape,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.gold,
        foregroundColor: colors.onGold,
        elevation: 3,
        highlightElevation: 1,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // A focused field lifts off the tint to the plain sheet colour
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? colors.sheet : colors.field,
        ),
        border: fieldBorder(colors.hairline),
        enabledBorder: fieldBorder(colors.hairline),
        disabledBorder: fieldBorder(colors.hairline),
        focusedBorder: fieldBorder(scheme.primary, active: true),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, active: true),
        contentPadding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        labelStyle: text.bodyLarge?.copyWith(color: colors.muted),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => text.bodyLarge!.copyWith(color: byState(states, colors.muted), fontWeight: FontWeight.w500),
        ),
        hintStyle: text.bodyLarge?.copyWith(color: colors.muted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w500),
        prefixIconColor: WidgetStateColor.resolveWith((states) => byState(states, colors.muted)),
        suffixIconColor: colors.muted,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.sheet,
        modalBackgroundColor: colors.sheet,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFFE9EEF6) : const Color(0xFF0E1B30),
        contentTextStyle: text.bodyMedium?.copyWith(color: dark ? const Color(0xFF0E1B30) : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.muted,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall?.copyWith(fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: colors.field,
        side: BorderSide.none,
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: colors.muted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colors.hairline,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? secondaryColor : scheme.surfaceContainerHighest,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        refreshBackgroundColor: colors.sheet,
      ),
    );
  }
}

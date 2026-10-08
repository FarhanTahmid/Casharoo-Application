import 'package:flutter/material.dart';

/// Colours the Material scheme has no slot for. Read them with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.header,
    required this.headerEnd,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.paper,
    required this.sheet,
    required this.field,
    required this.moneyIn,
    required this.moneyOut,
    required this.gold,
    required this.onGold,
    required this.mint,
    required this.muted,
    required this.hairline,
    required this.shadow,
  });

  /// The navy field at the top of every main screen.
  final Color header;
  final Color headerEnd;
  final Color onHeader;
  final Color onHeaderMuted;

  /// Screen background, and the cards and sheets that sit on it.
  final Color paper;
  final Color sheet;
  final Color field;

  /// Text-safe green and red: money in, money out.
  final Color moneyIn;
  final Color moneyOut;

  /// The Add action, and "close to the limit".
  final Color gold;
  final Color onGold;

  /// Money in, on the navy header.
  final Color mint;
  final Color muted;
  final Color hairline;
  final Color shadow;

  static const light = AppColors(
    header: Color(0xFF0B2D5E),
    headerEnd: Color(0xFF071D3F),
    onHeader: Colors.white,
    onHeaderMuted: Color(0xFFB4C6E4),
    paper: Color(0xFFF2F5FA),
    sheet: Colors.white,
    field: Color(0xFFF2F5FA),
    moneyIn: Color(0xFF17804A),
    moneyOut: Color(0xFFD93F4C),
    gold: Color(0xFFF5B530),
    onGold: Color(0xFF0B2D5E),
    mint: Color(0xFF5BE3A0),
    muted: Color(0xFF5B6B84),
    hairline: Color(0xFFE2E8F1),
    shadow: Color(0x240B2D5E),
  );

  static const dark = AppColors(
    header: Color(0xFF0E2647),
    headerEnd: Color(0xFF0A1A33),
    onHeader: Colors.white,
    onHeaderMuted: Color(0xFFA9BCDC),
    paper: Color(0xFF0A1322),
    sheet: Color(0xFF131F33),
    field: Color(0xFF1B2A43),
    moneyIn: Color(0xFF5BE3A0),
    moneyOut: Color(0xFFFF7A84),
    gold: Color(0xFFF5B530),
    onGold: Color(0xFF0B2D5E),
    mint: Color(0xFF5BE3A0),
    muted: Color(0xFF9FB0C8),
    hairline: Color(0xFF22324D),
    shadow: Color(0x66000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => other is AppColors && t >= 0.5 ? other : this;
}

class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Side gutter of every screen.
  static const double page = 16;
}

/// Bigger surfaces get bigger corners: sheet, card, control, chip.
class AppRadius {
  static const double sheet = 28;
  static const double card = 20;
  static const double control = 14;
  static const double pill = 999;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasised = Duration(milliseconds: 320);

  /// How long a figure takes to count to its new value.
  static const Duration count = Duration(milliseconds: 400);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Digits of equal width, so amounts line up in a column and do not jitter while counting.
const tabularFigures = [FontFeature.tabularFigures()];

extension DesignContext on BuildContext {
  AppColors get colors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ?? (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  }

  /// True when the person asked the system for less motion; animations then jump to their end.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// [duration], or none under "reduce motion".
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}

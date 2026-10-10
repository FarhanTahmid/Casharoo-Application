import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'design/tokens.dart';
import 'money.dart';
import 'theme.dart';

export 'package:flutter/services.dart' show HapticFeedback, SystemUiOverlayStyle;

export 'design/amounts.dart';
export 'design/avatar.dart';
export 'design/buttons.dart';
export 'design/category_color.dart';
export 'design/fields.dart';
export 'design/keypad.dart';
export 'design/layout.dart';
export 'design/loaders.dart';
export 'design/motion.dart';
export 'design/password_field.dart';
export 'design/rows.dart';
export 'design/segmented.dart';
export 'design/select_field.dart';
export 'design/sheets.dart';
export 'design/tokens.dart';
export 'theme.dart';

extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get languageCode => Localizations.localeOf(this).languageCode;

  /// Amount for display in the current language.
  String money(int amountMinor, String currency) => Money.format(amountMinor, currency, locale: languageCode);

  /// Text-safe green for money in, red for money out.
  Color amountColor(bool isIn) => isIn ? colors.moneyIn : colors.moneyOut;

  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Turns the 'offline' marker from the auth controller into a sentence.
String authErrorText(BuildContext context, String error) => error == 'offline' ? context.l10n.offlineError : error;

/// Which arrangement of the logo: the wallet alone, or with the name beside or under it.
enum BrandLayout { mark, horizontal, stacked }

/// The Spendroo logo from assets/brand, used as the logo kit's README says:
/// the mark where space is tight, the horizontal logo in headers (never under
/// 120 wide), the stacked one for splash screens. On the navy header or the
/// dark theme ([onDark]) the "reverse" artwork with the white wordmark is used.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 64, this.layout = BrandLayout.mark, this.onDark});

  final double height;
  final BrandLayout layout;

  /// Null follows the theme; pass true on the navy header.
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final reverse = (onDark ?? Theme.of(context).brightness == Brightness.dark) ? '-reverse' : '';
    final asset = switch (layout) {
      BrandLayout.mark => 'assets/brand/spendroo-mark-512w.png',
      BrandLayout.horizontal => 'assets/brand/spendroo-logo-horizontal$reverse-800w.png',
      BrandLayout.stacked => 'assets/brand/spendroo-logo-stacked$reverse-800w.png',
    };
    return Image.asset(asset, height: height, semanticLabel: context.l10n.appName);
  }
}

/// Fill colours: green for money in, red for money out. For text use `context.amountColor`.
Color amountColor(bool isIn) => isIn ? AppTheme.successColor : AppTheme.errorColor;

/// "1 Oct 2026", with Bengali month names and digits in Bangla.
String formatDate(BuildContext context, String isoDate) =>
    MaterialLocalizations.of(context).formatMediumDate(DateTime.parse(isoDate));

/// "Today", "Yesterday", or the date.
String friendlyDate(BuildContext context, String isoDate) {
  final today = todayIso();
  if (isoDate == today) return context.l10n.today;
  final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
  return isoDate == yesterday ? context.l10n.yesterday : formatDate(context, isoDate);
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

import 'package:intl/intl.dart';

/// Money is an integer count of minor units (paisa, cents) plus an ISO 4217
/// code, exactly as the server stores it. Doubles never hold an amount.
class Money {
  static const _exponents = {
    'BIF': 0, 'CLP': 0, 'DJF': 0, 'GNF': 0, 'ISK': 0, 'JPY': 0, 'KMF': 0, 'KRW': 0,
    'PYG': 0, 'RWF': 0, 'UGX': 0, 'VND': 0, 'VUV': 0, 'XAF': 0, 'XOF': 0, 'XPF': 0,
    'BHD': 3, 'IQD': 3, 'JOD': 3, 'KWD': 3, 'LYD': 3, 'OMR': 3, 'TND': 3,
  };
  static const _symbols = {'BDT': '৳', 'USD': r'$', 'INR': '₹', 'EUR': '€', 'GBP': '£'};

  /// Currencies whose users group digits as 1,00,000 (lakh) instead of 100,000.
  static const _lakhCurrencies = {'BDT', 'INR', 'PKR', 'NPR', 'LKR'};

  static const _bengaliDigits = '০১২৩৪৫৬৭৮৯';

  static int exponent(String currency) => _exponents[currency] ?? 2;

  static String symbol(String currency) => _symbols[currency] ?? '$currency ';

  /// "৳ 1,23,456.50" in English, "৳ ১,২৩,৪৫৬.৫০" in Bangla.
  static String format(int amountMinor, String currency, {String locale = 'en', bool withSymbol = true}) {
    final digits = exponent(currency);
    final scale = _pow10(digits);
    final negative = amountMinor < 0;
    final absolute = amountMinor.abs();

    final bangla = locale.startsWith('bn');
    final numberLocale = bangla ? 'bn' : (_lakhCurrencies.contains(currency) ? 'en_IN' : 'en_US');
    var text = NumberFormat.decimalPattern(numberLocale).format(absolute ~/ scale);
    if (digits > 0) {
      final fraction = (absolute % scale).toString().padLeft(digits, '0');
      text = '$text.${bangla ? toBengaliDigits(fraction) : fraction}';
    }
    return '${negative ? '-' : ''}${withSymbol ? symbol(currency) : ''}$text';
  }

  /// Plain text for an input field: "1234.50". No grouping, ASCII digits.
  static String toInput(int amountMinor, String currency) {
    final digits = exponent(currency);
    final scale = _pow10(digits);
    final absolute = amountMinor.abs();
    final whole = '${amountMinor < 0 ? '-' : ''}${absolute ~/ scale}';
    return digits == 0 ? whole : '$whole.${(absolute % scale).toString().padLeft(digits, '0')}';
  }

  /// Parses what a person typed ("1,250.5", "১২৫০.৫০") into minor units.
  /// Returns null when it is not a non-negative amount the currency can hold.
  static int? parse(String input, String currency) {
    final text = toAsciiDigits(input).replaceAll(',', '').replaceAll(' ', '');
    final match = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(text);
    if (match == null) return null;
    final whole = match.group(1) ?? '';
    final fraction = match.group(2) ?? '';
    final digits = exponent(currency);
    if ((whole.isEmpty && fraction.isEmpty) || fraction.length > digits || whole.length > 15) return null;
    return int.parse('${whole.isEmpty ? '0' : whole}${fraction.padRight(digits, '0')}');
  }

  static String toAsciiDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final index = _bengaliDigits.runes.toList().indexOf(rune);
      buffer.write(index >= 0 ? '$index' : String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  static String toBengaliDigits(String text) =>
      text.replaceAllMapped(RegExp(r'\d'), (m) => _bengaliDigits[int.parse(m[0]!)]);

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

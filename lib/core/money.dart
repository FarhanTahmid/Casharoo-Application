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

  /// Currencies offered in pickers, most used here first: code -> English name.
  /// Any other ISO 4217 code a row already carries still formats and parses.
  static const currencies = {
    'BDT': 'Bangladeshi Taka',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'INR': 'Indian Rupee',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'MYR': 'Malaysian Ringgit',
    'SGD': 'Singapore Dollar',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'PKR': 'Pakistani Rupee',
    'NPR': 'Nepalese Rupee',
    'LKR': 'Sri Lankan Rupee',
    'QAR': 'Qatari Riyal',
    'KWD': 'Kuwaiti Dinar',
    'OMR': 'Omani Rial',
    'BHD': 'Bahraini Dinar',
    'TRY': 'Turkish Lira',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'KRW': 'South Korean Won',
    'HKD': 'Hong Kong Dollar',
    'NZD': 'New Zealand Dollar',
    'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona',
    'ZAR': 'South African Rand',
    'EGP': 'Egyptian Pound',
  };

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

  /// Short whole-unit amount for tight spaces such as a calendar cell: "850",
  /// "1.2k", "12k", "1.5L" (lakh, for lakh currencies) or "1.5M". No symbol.
  static String compact(int amountMinor, String currency, {String locale = 'en'}) {
    final bangla = locale.startsWith('bn');
    final whole = amountMinor.abs() ~/ _pow10(exponent(currency));
    final lakh = _lakhCurrencies.contains(currency);
    String scaled(int unit, String suffix) {
      final value = whole / unit;
      final digits = value >= 10 ? value.round().toString() : value.toStringAsFixed(1).replaceAll('.0', '');
      return '$digits$suffix';
    }

    final text = switch (whole) {
      < 1000 => '$whole',
      < 100000 => scaled(1000, bangla ? 'হা' : 'k'),
      _ when lakh && whole < 10000000 => scaled(100000, bangla ? 'লা' : 'L'),
      _ when lakh => scaled(10000000, bangla ? 'কো' : 'Cr'),
      < 1000000 => scaled(1000, bangla ? 'হা' : 'k'),
      _ => scaled(1000000, 'M'),
    };
    return '${amountMinor < 0 ? '-' : ''}${bangla ? toBengaliDigits(text) : text}';
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

  static final _operatorPattern = RegExp(r'[-+*/%()]');

  static String _normalise(String input) => toAsciiDigits(input)
      .replaceAll(RegExp(r'[,\s]'), '')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-');

  /// True when [input] is a sum to work out ("1200+350") and not a plain amount.
  static bool isExpression(String input) => _operatorPattern.hasMatch(_normalise(input));

  /// Works out what a person typed on the keypad ("1200+350×2", "850−10%")
  /// into minor units, rounding half up. A plain amount goes through [parse].
  /// An operator left at the end is ignored, so "1200+" is 1200 while typing.
  /// Returns null when it cannot be worked out or is not a non-negative amount
  /// the currency can hold. Exact fractions throughout: no doubles.
  static int? evaluate(String input, String currency) {
    final text = _normalise(input).replaceFirst(RegExp(r'[-+*/(.]+$'), '');
    if (!_operatorPattern.hasMatch(text)) return parse(text, currency);
    if (text.length > 64) return null;
    final _Fraction value;
    try {
      value = _Calculator(text).run();
    } on FormatException {
      return null;
    }
    if (value.numerator.isNegative) return null;
    final digits = exponent(currency);
    final two = BigInt.two;
    final minor = (value.numerator * BigInt.from(_pow10(digits)) * two + value.denominator) ~/ (value.denominator * two);
    // The same ceiling as parse: 15 whole digits
    if (minor >= BigInt.from(10).pow(15 + digits)) return null;
    return minor.toInt();
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

/// An exact number: [numerator] over a positive [denominator], in lowest terms.
class _Fraction {
  _Fraction._(this.numerator, this.denominator);

  factory _Fraction(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) throw const FormatException('division by zero');
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final divisor = numerator.gcd(denominator);
    return divisor <= BigInt.one
        ? _Fraction._(numerator, denominator)
        : _Fraction._(numerator ~/ divisor, denominator ~/ divisor);
  }

  final BigInt numerator;
  final BigInt denominator;

  static final hundred = _Fraction(BigInt.from(100), BigInt.one);

  _Fraction operator +(_Fraction o) =>
      _Fraction(numerator * o.denominator + o.numerator * denominator, denominator * o.denominator);
  _Fraction operator -(_Fraction o) =>
      _Fraction(numerator * o.denominator - o.numerator * denominator, denominator * o.denominator);
  _Fraction operator *(_Fraction o) => _Fraction(numerator * o.numerator, denominator * o.denominator);
  _Fraction operator /(_Fraction o) => _Fraction(numerator * o.denominator, denominator * o.numerator);
  _Fraction operator -() => _Fraction._(-numerator, denominator);
}

/// Reads "1200+350*2" the way a calculator does: × and ÷ before + and −,
/// brackets first, and "850-10%" taking ten percent of the 850.
class _Calculator {
  _Calculator(this.text);

  final String text;
  int _at = 0;

  /// Set by [_value] when what it just read ended in a percent sign.
  bool _percent = false;

  String? get _next => _at < text.length ? text[_at] : null;

  _Fraction run() {
    final value = _sum();
    if (_at != text.length) throw const FormatException('unexpected character');
    return value;
  }

  _Fraction _sum() {
    var total = _product();
    while (_next == '+' || _next == '-') {
      final minus = text[_at++] == '-';
      final from = _at;
      var term = _product();
      // "a + b%": the percent is of a, when b% stands alone as the term
      if (_percent && _isLonePercent(from)) term = total * term;
      total = minus ? total - term : total + term;
    }
    return total;
  }

  bool _isLonePercent(int from) => RegExp(r'^[\d.]+%$').hasMatch(text.substring(from, _at));

  _Fraction _product() {
    var total = _signed();
    while (_next == '*' || _next == '/') {
      final divide = text[_at++] == '/';
      final factor = _signed();
      total = divide ? total / factor : total * factor;
    }
    return total;
  }

  _Fraction _signed() {
    if (_next == '-') {
      _at++;
      return -_signed();
    }
    return _value();
  }

  _Fraction _value() {
    _Fraction value;
    if (_next == '(') {
      _at++;
      value = _sum();
      // A bracket still open at the end closes itself
      if (_next == ')') {
        _at++;
      } else if (_at != text.length) {
        throw const FormatException('missing bracket');
      }
    } else {
      final match = RegExp(r'(\d*)(?:\.(\d*))?').matchAsPrefix(text, _at)!;
      final whole = match.group(1) ?? '';
      final fraction = match.group(2) ?? '';
      if (whole.isEmpty && fraction.isEmpty) throw const FormatException('number expected');
      _at = match.end;
      value = _Fraction(BigInt.parse('$whole$fraction'.padLeft(1, '0')), BigInt.from(10).pow(fraction.length));
    }
    _percent = _next == '%';
    if (_percent) {
      _at++;
      value = value / _Fraction.hundred;
    }
    return value;
  }
}

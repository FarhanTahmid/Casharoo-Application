import 'package:casharoo/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format', () {
    test('groups BDT in lakh and shows two decimals', () {
      expect(Money.format(12345650, 'BDT'), '৳1,23,456.50');
      expect(Money.format(5, 'BDT'), '৳0.05');
      expect(Money.format(-250000, 'BDT'), '-৳2,500.00');
    });

    test('uses western grouping and the currency exponent elsewhere', () {
      expect(Money.format(12345650, 'USD'), r'$123,456.50');
      expect(Money.format(1234567, 'JPY'), 'JPY 1,234,567');
      expect(Money.format(12345, 'KWD'), 'KWD 12.345');
    });

    test('Bangla locale uses Bengali digits', () {
      expect(Money.format(12345650, 'BDT', locale: 'bn'), '৳১,২৩,৪৫৬.৫০');
    });
  });

  group('Money.parse', () {
    test('reads typed amounts into minor units without floats', () {
      expect(Money.parse('1250', 'BDT'), 125000);
      expect(Money.parse('1,250.5', 'BDT'), 125050);
      expect(Money.parse('0.07', 'BDT'), 7);
      expect(Money.parse('.5', 'BDT'), 50);
      expect(Money.parse('19.99', 'USD'), 1999);
      expect(Money.parse('500', 'JPY'), 500);
      expect(Money.parse('1.234', 'KWD'), 1234);
    });

    test('accepts Bengali digits', () {
      expect(Money.parse('১২৫০.৫০', 'BDT'), 125050);
    });

    test('rejects what the currency cannot hold', () {
      expect(Money.parse('', 'BDT'), isNull);
      expect(Money.parse('abc', 'BDT'), isNull);
      expect(Money.parse('-5', 'BDT'), isNull);
      expect(Money.parse('1.234', 'BDT'), isNull);
      expect(Money.parse('1.5', 'JPY'), isNull);
      expect(Money.parse('1.2.3', 'BDT'), isNull);
    });
  });

  test('toInput round-trips through parse', () {
    for (final (amount, currency) in [(125050, 'BDT'), (7, 'USD'), (500, 'JPY'), (1234, 'KWD')]) {
      expect(Money.parse(Money.toInput(amount, currency), currency), amount);
    }
  });
}

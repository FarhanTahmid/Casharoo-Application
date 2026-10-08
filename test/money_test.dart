import 'package:spendroo/core/money.dart';
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

  group('Money.evaluate', () {
    test('works sums out with × and ÷ before + and −', () {
      expect(Money.evaluate('1200+350×2', 'BDT'), 190000);
      expect(Money.evaluate('1200 + 350 * 2', 'BDT'), 190000);
      expect(Money.evaluate('(1200+350)×2', 'BDT'), 310000);
      expect(Money.evaluate('100−30.5', 'BDT'), 6950);
      expect(Money.evaluate('১০০+৫০', 'BDT'), 15000);
      expect(Money.evaluate('0.1+0.2', 'BDT'), 30); // exact, where doubles give 0.30000000000000004
    });

    test('rounds half up to what the currency holds', () {
      expect(Money.evaluate('100÷3', 'BDT'), 3333);
      expect(Money.evaluate('200÷3', 'BDT'), 6667);
      expect(Money.evaluate('0.01÷2', 'BDT'), 1);
      expect(Money.evaluate('100÷3', 'JPY'), 33);
      expect(Money.evaluate('100÷3', 'KWD'), 33333);
    });

    test('takes a percent of the amount before it', () {
      expect(Money.evaluate('850−10%', 'BDT'), 76500);
      expect(Money.evaluate('1000+15%', 'BDT'), 115000);
      expect(Money.evaluate('200×15%', 'BDT'), 3000);
      expect(Money.evaluate('50%', 'BDT'), 50);
    });

    test('ignores an operator left at the end', () {
      expect(Money.evaluate('1200+', 'BDT'), 120000);
      expect(Money.evaluate('1200+350×', 'BDT'), 155000);
      expect(Money.evaluate('(1200+350', 'BDT'), 155000);
    });

    test('a plain amount is parsed as before', () {
      expect(Money.evaluate('1,250.5', 'BDT'), 125050);
      expect(Money.evaluate('1.234', 'BDT'), isNull);
      expect(Money.evaluate('', 'BDT'), isNull);
      expect(Money.isExpression('1250.50'), isFalse);
      expect(Money.isExpression('1250+'), isTrue);
    });

    test('rejects what is not a non-negative amount', () {
      expect(Money.evaluate('5÷0', 'BDT'), isNull);
      expect(Money.evaluate('5−10', 'BDT'), isNull);
      expect(Money.evaluate('-5', 'BDT'), isNull);
      expect(Money.evaluate('5++2', 'BDT'), isNull);
      expect(Money.evaluate('2(3)', 'BDT'), isNull);
      expect(Money.evaluate('999999999999999×10', 'BDT'), isNull);
    });
  });

  test('toInput round-trips through parse', () {
    for (final (amount, currency) in [(125050, 'BDT'), (7, 'USD'), (500, 'JPY'), (1234, 'KWD')]) {
      expect(Money.parse(Money.toInput(amount, currency), currency), amount);
    }
  });
}

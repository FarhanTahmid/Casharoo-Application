import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strings that read the same in both languages on purpose (language names in the picker).
const sameInBoth = {'english', 'bangla', '@@locale'};

Map<String, dynamic> strings(String locale) {
  final all = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in all.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value,
  };
}

/// Names in "{name}" and "{name, plural, ...}"; plural branch text such as "=1{1 entry}" is not a name.
Set<String> placeholders(String text) =>
    RegExp(r'\{([A-Za-z_]\w*)[,}]').allMatches(text).map((m) => m[1]!).toSet();

void main() {
  final en = strings('en');
  final bn = strings('bn');

  test('every English string has a Bangla translation and nothing extra', () {
    expect(bn.keys.toSet().difference(en.keys.toSet()), isEmpty, reason: 'only in app_bn.arb');
    expect(en.keys.toSet().difference(bn.keys.toSet()), isEmpty, reason: 'missing from app_bn.arb');
  });

  test('Bangla strings are translated, not copied', () {
    final copied = [
      for (final key in en.keys)
        if (!sameInBoth.contains(key) && en[key] == bn[key]) key,
    ];
    expect(copied, isEmpty);
  });

  test('both languages use the same placeholders', () {
    for (final key in en.keys) {
      final names = placeholders(en[key] as String);
      final bnNames = placeholders(bn[key] as String);
      expect(bnNames, names, reason: key);
    }
  });
}

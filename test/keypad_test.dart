import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendroo/core/providers.dart';

import 'app_flow_test.dart' show FakeServer, Harness;

/// The amount keypad, as opposed to any other text on screen.
final _keypad = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_Keypad');

Finder _key(String label) => find.descendant(of: _keypad, matching: find.text(label));

void main() {
  testWidgets('a sum typed on the keypad is worked out and saved', (tester) async {
    final app = Harness(tester, FakeServer());
    await app.start();
    await app.logIn();
    await tester.tap(find.text('Try a demo business'));
    await app.settle();
    await app.settle();
    await tester.tap(find.text('Shop cash'));
    await app.settle();

    expect(_keypad, findsNothing);
    await tester.tap(find.text('Cash in'));
    await app.settle();
    // The amount has focus when the form opens, and brings the keypad with it
    expect(_keypad, findsOneWidget);
    expect(_key('BDT'), findsNothing);
    expect(_key('৳  BDT'), findsOneWidget);

    for (final label in ['1', '2', '0', '0', '+', '+', '3', '5', '0', '×', '2']) {
      await tester.tap(_key(label));
      await tester.pump();
    }
    final field = tester.widget<TextFormField>(find.byType(TextFormField).first).controller!;
    expect(field.text, '1200+350×2'); // the second + replaced the first
    await app.settle();
    expect(find.text('= ৳1,900.00'), findsOneWidget);
    // Typing did not take focus from the field
    expect(_keypad, findsOneWidget);

    await tester.tap(_key('='));
    await app.settle();
    expect(field.text, '1900.00');
    expect(find.text('= ৳1,900.00'), findsNothing);

    // Only two decimals fit a taka, and one point a number
    for (final label in ['.', '5', '+', '0', '.', '2', '5', '9', '⌫']) {
      if (label == '⌫') {
        await tester.tap(find.descendant(of: _keypad, matching: find.byIcon(Icons.backspace_outlined)));
      } else {
        await tester.tap(_key(label));
      }
      await tester.pump();
    }
    expect(field.text, '1900.00+0.2');

    // Saving works the sum out without pressing "="
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    await app.settle();
    expect(_keypad, findsNothing);
    expect(find.text('৳16,900.20'), findsWidgets);

    await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
    expect((app.server.pushed.single['data'] as Map)['amount_minor'], 190020);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('a cashbook can be made in another currency', (tester) async {
    final app = Harness(tester, FakeServer());
    await app.start();
    await app.logIn();
    await tester.tap(find.text('Try a demo business'));
    await app.settle();
    await app.settle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add cashbook'));
    await app.settle();
    await tester.enterText(find.byType(TextFormField), 'Dollar till');
    await tester.tap(find.text('BDT · Bangladeshi Taka'));
    await app.settle();
    await tester.tap(find.text('USD · US Dollar'));
    await app.settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    await app.settle();

    final book = (await app.run(app.db.select(app.db.cashbooks).get())).singleWhere((b) => b.bookName == 'Dollar till');
    expect(book.currency, 'USD');
    expect(find.textContaining('· USD'), findsOneWidget); // marked on the list: it is not in the BDT total
    expect(find.text('৳15,000.00'), findsWidgets);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('the default currency is changed in settings', (tester) async {
    final app = Harness(tester, FakeServer(onboardedAt: '2026-10-01T00:00:00Z'));
    await app.start();
    await app.logIn();
    expect(find.text('৳500.00'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await app.settle();
    await tester.tap(find.text('Default currency'));
    await app.settle();
    await tester.tap(find.text('USD · US Dollar'));
    await app.settle();
    await app.settle();
    expect(app.server.personalCurrency, 'USD');

    await tester.tap(find.byType(BackButton));
    await app.settle();
    await app.settle();
    // The taka account is still listed, but the total is now in dollars
    expect(find.text(r'$0.00'), findsWidgets);
    expect(find.text('৳500.00'), findsOneWidget);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/design/category_color.dart';
import 'package:spendroo/core/theme.dart';
import 'package:spendroo/features/personal/ledger_repository.dart';
import 'package:spendroo/features/personal/spending_breakdown.dart';
import 'package:spendroo/l10n/app_localizations.dart';

final month = MonthSummary(6500000, 3198900, [
  CategorySpend('d6f66675-d5ad-4bb5-a17a-957cb30cec94', 'Housing', '#2F6FD0', 1800000,
      count: 1, largestMinor: 1800000, previousMinor: 1800000),
  CategorySpend('5c400cbb-0e38-4a22-b29a-703460e191d6', 'Other', '#6B7C93', 480000, count: 3, largestMinor: 220000),
  CategorySpend('9bf9c576-60c6-4079-bc6c-1173267a845d', 'Shopping', '#E05C9A', 344000,
      count: 2, largestMinor: 300000, previousMinor: 200000),
  CategorySpend('8a2e94e5-f126-4f18-98e7-a59a3cbf097f', 'Utilities', '#F5B530', 255000, count: 3, largestMinor: 145000),
  CategorySpend('9ac3bf4f-a7d9-4e17-837a-4505da505ef3', 'Transport', '#3B9EE5', 158000, count: 6, largestMinor: 45000),
  CategorySpend('115235ab-0605-4170-830e-18c0f1659b0f', 'Food', '#F08A3C', 154000, count: 5, largestMinor: 61000),
  CategorySpend('3e847aa9-041b-44da-86fa-cee4957fdfd2', 'Health', '#D9485F', 5600, count: 1, largestMinor: 5600),
  CategorySpend('2b0adcd7-14fe-49ea-9536-b154562eb465', 'Education', '#7A5AF8', 2300, count: 1, largestMinor: 2300),
]);

final shoppingBudget = BudgetProgress(
  const Budget(
    id: 'b1',
    workspaceId: 'ws1',
    version: 1,
    serverSeq: 1,
    createdAt: '2026-10-01T00:00:00Z',
    updatedAt: '2026-10-01T00:00:00Z',
    categoryId: '9bf9c576-60c6-4079-bc6c-1173267a845d',
    amountMinor: 600000,
    currency: 'BDT',
  ),
  'Shopping',
  344000,
);

Future<void> show(WidgetTester tester, {ThemeData? theme}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SpendingBreakdown(month: month, currency: 'BDT', budgets: [shoppingBudget]),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the ring and the rows carry the colours of the categories themselves', (tester) async {
    await show(tester);
    final dots = tester.widgetList<ColorDot>(find.byType(ColorDot)).map((d) => d.color).toList();
    expect(dots, [for (final s in month.byCategory.take(5)) categoryFill(s.color, s.categoryId)]);
    expect(dots.take(3), const [Color(0xFF2F6FD0), Color(0xFF6B7C93), Color(0xFFE05C9A)]);
  });

  testWidgets('says what stands out, and a tapped category opens its details', (tester) async {
    await show(tester);
    expect(find.text('Housing takes 56% of what you spent.'), findsOneWidget);
    expect(find.text('Shopping is up 72% on last month.'), findsOneWidget);
    expect(find.text('Tap a category for details'), findsOneWidget);
    // The small ones wait behind a button
    expect(find.text('Health'), findsNothing);
    await tester.tap(find.text('3 more'));
    await tester.pumpAndSettle();
    expect(find.text('Health'), findsOneWidget);

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();
    expect(find.text('11% of spending'), findsOneWidget);
    expect(find.text('+72% vs last month'), findsOneWidget);
    expect(find.text('Largest'), findsOneWidget);
    expect(find.text('৳3,000.00'), findsOneWidget);
    expect(find.text('৳1,720.00'), findsOneWidget); // average of the two
    expect(find.text('৳3,440.00 of ৳6,000.00'), findsOneWidget);
    expect(find.text('Tap a category for details'), findsNothing);

    // Tapping it again lets go
    await tester.tap(find.text('Shopping').last);
    await tester.pumpAndSettle();
    expect(find.text('Largest'), findsNothing);
  });

  testWidgets('a tap on the ring picks the slice under the finger', (tester) async {
    await show(tester);
    final ring = tester.getRect(find.byKey(const ValueKey('spending-ring')));
    // To the right of the middle is Housing, which runs from the top to past the bottom
    await tester.tapAt(ring.center + const Offset(84, 0));
    await tester.pumpAndSettle();
    expect(find.text('56% of spending'), findsOneWidget);
    // The middle lets go
    await tester.tapAt(ring.center);
    await tester.pumpAndSettle();
    expect(find.text('56% of spending'), findsNothing);
  });
}

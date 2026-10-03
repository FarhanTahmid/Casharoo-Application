import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/db/local_store.dart';
import 'package:spendroo/core/providers.dart';
import 'package:spendroo/core/theme.dart';
import 'package:spendroo/features/personal/budget_calendar_page.dart';
import 'package:spendroo/features/personal/categories_page.dart';
import 'package:spendroo/features/personal/ledger_repository.dart';
import 'package:spendroo/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

const workspace = Workspace(
  id: '00000000-0000-0000-0000-000000000001',
  name: 'Personal',
  kind: 'personal',
  defaultCurrency: 'BDT',
  isDemo: false,
  role: 'owner',
);

/// A personal screen on an in-memory database, with the month fixed to October 2026.
class ScreenHarness {
  ScreenHarness(this.tester) {
    useHostSqlite();
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    store = LocalStore(db);
    ledger = LedgerRepository(db, store);
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      localStoreProvider.overrideWithValue(store),
    ]);
    container.read(selectedMonthProvider.notifier).set(DateTime(2026, 10));
  }

  final WidgetTester tester;
  late final AppDatabase db;
  late final LocalStore store;
  late final LedgerRepository ledger;
  late final ProviderContainer container;

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<T> run<T>(Future<T> Function() action) async => (await tester.runAsync(action)) as T;

  Future<void> show(Widget child) async {
    await db.into(db.workspaces).insert(workspace);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ));
    await settle();
  }

  Future<void> stop() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(db.close);
  }
}

void main() {
  testWidgets('budget calendar: daily spend, colours, a day sheet and month switching', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final app = ScreenHarness(tester);
    await app.run(() async {
      await app.db.into(app.db.workspaces).insert(workspace);
      await app.ledger.addAccount(workspace.id, name: 'Cash', kind: 'cash', currency: 'BDT');
      final cash = (await app.ledger.watchAccounts(workspace.id).first).single.account;
      final food = await app.ledger.addCategory(workspace.id, 'Food', 'expense');
      // 3,100 a month is 100 a day in October
      await app.ledger.setBudget(workspace.id, food, 310000, 'BDT');
      await app.ledger.addTransaction(cash, kind: 'expense', amountMinor: 8000, occurredOn: '2026-10-02',
          categoryId: food, note: 'Groceries');
      await app.ledger.addTransaction(cash, kind: 'expense', amountMinor: 250000, occurredOn: '2026-10-05',
          categoryId: food, note: 'Party');
      await app.db.delete(app.db.workspaces).go(); // show() inserts it again
    });

    await app.show(const Scaffold(body: BudgetCalendarPage(workspace: workspace)));
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('80'), findsOneWidget); // day 2, within the daily allowance
    expect(find.text('2.5k'), findsOneWidget); // day 5, far over it
    expect(find.text('৳2,580.00 of ৳3,100.00'), findsOneWidget);

    Color? shade(int day) =>
        tester.widget<Material>(find.byKey(ValueKey('day-$day'))).color;
    expect(shade(2), AppTheme.successColor.withValues(alpha: 0.18));
    expect(shade(5), AppTheme.errorColor.withValues(alpha: 0.25));
    expect(shade(3), Colors.transparent);

    await tester.tap(find.byKey(const ValueKey('day-5')));
    await app.settle();
    expect(find.text('Party'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await app.settle();

    await tester.tap(find.byTooltip('Previous month'));
    await app.settle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('2.5k'), findsNothing);
    await app.stop();
  });

  testWidgets('categories: add, rename and delete', (tester) async {
    final app = ScreenHarness(tester);
    await app.run(() async {
      await app.db.into(app.db.workspaces).insert(workspace);
      await app.container.read(currentWorkspaceIdProvider.notifier).select(workspace.id);
      await app.ledger.addCategory(workspace.id, 'Food', 'expense');
      await app.ledger.addCategory(workspace.id, 'Salary', 'income');
      await app.db.delete(app.db.workspaces).go();
    });

    await app.show(const CategoriesPage());
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Salary'), findsNothing); // on the income tab

    await tester.tap(find.text('Food'));
    await app.settle();
    await tester.enterText(find.byType(TextField), 'Groceries');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('New category'));
    await app.settle();
    await tester.enterText(find.byType(TextField), 'Transport');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    expect(find.text('Transport'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await app.settle();
    expect(find.textContaining('Delete "Groceries"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await app.settle();
    expect(find.text('Groceries'), findsNothing);

    await tester.tap(find.text('Income'));
    await app.settle();
    expect(find.text('Salary'), findsOneWidget);
    await app.stop();
  });
}

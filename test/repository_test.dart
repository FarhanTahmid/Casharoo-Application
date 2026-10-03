import 'dart:convert';

import 'package:casharoo/core/db/database.dart';
import 'package:casharoo/core/db/local_store.dart';
import 'package:casharoo/features/cashbook/cashbook_repository.dart';
import 'package:casharoo/features/personal/ledger_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  late AppDatabase db;
  late LocalStore store;
  var changes = 0;

  setUp(() {
    db = memoryDatabase();
    changes = 0;
    store = LocalStore(db, onChange: () => changes++);
  });
  tearDown(() => db.close());

  Future<List<OutboxData>> outbox() => db.select(db.outbox).get();

  group('cashbook', () {
    late CashbookRepository repo;
    setUp(() => repo = CashbookRepository(db, store));

    test('a new book is usable at once and queued with its defaults', () async {
      final bookId = await repo.createCashbook('ws1', 'Till', 'BDT');

      final books = await repo.watchCashbooks('ws1').first;
      expect(books.single.book.bookName, 'Till');
      expect(books.single.balanceMinor, 0);
      expect((await repo.watchCategories(bookId).first).length, defaultEntryCategories.length);
      expect((await repo.watchPaymentMethods(bookId).first).length, defaultPaymentMethods.length);

      final queued = await outbox();
      // The book goes first: the server applies mutations in order
      expect(queued.first.tableName_, 'cashbooks');
      expect(queued.length, 1 + defaultEntryCategories.length + defaultPaymentMethods.length);
      expect(changes, greaterThan(0));
    });

    test('entries change the balance and edits queue only changed fields', () async {
      final bookId = await repo.createCashbook('ws1', 'Till', 'BDT');
      final book = (await repo.watchCashbook(bookId).first)!.book;
      final entryId = await repo.addEntry(book, entryType: 'cash_in', amountMinor: 10000, entryDate: '2026-10-01');
      await repo.addEntry(book, entryType: 'cash_out', amountMinor: 2500, entryDate: '2026-10-02', title: 'Tea');

      var summary = (await repo.watchCashbook(bookId).first)!;
      expect((summary.cashInMinor, summary.cashOutMinor, summary.balanceMinor, summary.entryCount),
          (10000, 2500, 7500, 2));

      final entries = await repo.watchEntries(bookId).first;
      expect(entries.first.entry.title, 'Tea'); // newest date first
      expect(entries.first.entry.currency, 'BDT'); // known locally before any sync

      final original = entries.firstWhere((e) => e.entry.id == entryId).entry;
      await repo.updateEntry(original, amountMinor: 12000, entryDate: original.entryDate);
      final edit = (await outbox()).last;
      expect((edit.op, edit.rowId), ('upsert', entryId));
      expect(jsonDecode(edit.data), {'amount_minor': 12000});

      await repo.deleteEntry(entryId);
      summary = (await repo.watchCashbook(bookId).first)!;
      expect((summary.balanceMinor, summary.entryCount), (-2500, 1));
      expect((await outbox()).last.op, 'delete');
    });

    test('an edit that changes nothing queues nothing', () async {
      final bookId = await repo.createCashbook('ws1', 'Till', 'BDT');
      final book = (await repo.watchCashbook(bookId).first)!.book;
      await repo.addEntry(book, entryType: 'cash_in', amountMinor: 100, entryDate: '2026-10-01');
      final entry = (await repo.watchEntries(bookId).first).single.entry;
      final before = (await outbox()).length;
      await repo.updateEntry(entry, amountMinor: 100, entryDate: '2026-10-01');
      expect((await outbox()).length, before);
    });

    test('breakdown totals per category', () async {
      final bookId = await repo.createCashbook('ws1', 'Till', 'BDT');
      final book = (await repo.watchCashbook(bookId).first)!.book;
      final food = (await repo.watchCategories(bookId).first).firstWhere((c) => c.categoryName == 'Food');
      await repo.addEntry(book, entryType: 'cash_out', amountMinor: 300, entryDate: '2026-10-01', categoryId: food.id);
      await repo.addEntry(book, entryType: 'cash_out', amountMinor: 200, entryDate: '2026-10-01', categoryId: food.id);
      await repo.addEntry(book, entryType: 'cash_in', amountMinor: 900, entryDate: '2026-10-01');

      final rows = await repo.watchBreakdown(bookId, byCategory: true).first;
      expect(rows.firstWhere((r) => r.name == 'Food').cashOutMinor, 500);
      expect(rows.firstWhere((r) => r.name == null).cashInMinor, 900);
    });
  });

  group('cashbook delete', () {
    test('deleting a book hides its rows at once and queues only the book', () async {
      final repo = CashbookRepository(db, store);
      final bookId = await repo.createCashbook('ws1', 'Till', 'BDT');
      final book = (await repo.watchCashbook(bookId).first)!.book;
      await repo.addEntry(book, entryType: 'cash_in', amountMinor: 500, entryDate: '2026-10-01');
      await db.delete(db.outbox).go();

      await repo.deleteCashbook(bookId);
      expect(await repo.watchCashbooks('ws1').first, isEmpty);
      expect(await repo.watchEntries(bookId).first, isEmpty);
      expect(await repo.watchCategories(bookId).first, isEmpty);
      expect((await outbox()).map((o) => (o.tableName_, o.op)).toList(), [('cashbooks', 'delete')]);
    });
  });

  group('personal ledger', () {
    late LedgerRepository repo;
    late Account cash;
    late Account bank;

    setUp(() async {
      repo = LedgerRepository(db, store);
      await repo.addAccount('ws1', name: 'Cash', kind: 'cash', currency: 'BDT', openingBalanceMinor: 100000);
      await repo.addAccount('ws1', name: 'Bank', kind: 'bank', currency: 'BDT');
      final accounts = await repo.watchAccounts('ws1').first;
      cash = accounts.firstWhere((a) => a.account.name == 'Cash').account;
      bank = accounts.firstWhere((a) => a.account.name == 'Bank').account;
    });

    Future<Map<String, int>> balances() async =>
        {for (final a in await repo.watchAccounts('ws1').first) a.account.name: a.balanceMinor};

    test('expenses subtract, income adds, transfers move money between accounts', () async {
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 2500, occurredOn: '2026-10-01');
      await repo.addTransaction(bank, kind: 'income', amountMinor: 500000, occurredOn: '2026-10-01');
      await repo.addTransfer(bank, cash, amountMinor: 30000, occurredOn: '2026-10-02');
      expect(await balances(), {'Cash': 127500, 'Bank': 470000});

      // Removing one leg of the transfer removes both
      final transfer = (await repo.watchTransactions('ws1').first)
          .firstWhere((t) => t.transaction.kind == 'transfer')
          .transaction;
      await repo.deleteTransaction(transfer);
      expect(await balances(), {'Cash': 97500, 'Bank': 500000});
    });

    test('month summary and budget progress', () async {
      final foodId = await repo.addCategory('ws1', 'Food', 'expense');
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 4000, occurredOn: '2026-10-05', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 1000, occurredOn: '2026-10-20', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 700, occurredOn: '2026-10-21');
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 9999, occurredOn: '2026-09-30', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'income', amountMinor: 80000, occurredOn: '2026-10-01');
      await repo.addTransfer(cash, bank, amountMinor: 5000, occurredOn: '2026-10-03');

      final month = await repo.watchMonth('ws1', DateTime(2026, 10, 15), 'BDT').first;
      expect((month.incomeMinor, month.expenseMinor), (80000, 5700)); // transfers are neither
      expect(month.byCategory.map((e) => (e.key, e.value)).toList(), [('Food', 5000), (null, 700)]);

      await repo.setBudget('ws1', foodId, 4500, 'BDT');
      await repo.setBudget('ws1', foodId, 4800, 'BDT'); // same category: updates, does not duplicate
      final budgets = await repo.watchBudgets('ws1', DateTime(2026, 10, 15)).first;
      expect(budgets.single.budget.amountMinor, 4800);
      expect((budgets.single.spentMinor, budgets.single.isOver), (5000, true));
    });

    test('a one-month override replaces the recurring budget for that month only', () async {
      final foodId = await repo.addCategory('ws1', 'Food', 'expense');
      await repo.setBudget('ws1', foodId, 5000, 'BDT');
      await repo.setBudget('ws1', foodId, 9000, 'BDT', month: '2026-12-01');
      await repo.setBudget('ws1', foodId, 9500, 'BDT', month: '2026-12-01'); // same month: updates

      final december = await repo.watchBudgets('ws1', DateTime(2026, 12, 10)).first;
      expect(december.single.budget.amountMinor, 9500);
      expect((december.single.isOverride, december.single.recurring?.amountMinor), (true, 5000));
      final november = await repo.watchBudgets('ws1', DateTime(2026, 11, 10)).first;
      expect((november.single.budget.amountMinor, november.single.isOverride), (5000, false));

      final queued = (await outbox()).where((o) => o.tableName_ == 'budgets').toList();
      expect(queued.map((o) => jsonDecode(o.data)['month']).toList(), [null, '2026-12-01', null]);

      // Removing the override brings the usual limit back
      await repo.deleteBudget(december.single.budget.id);
      expect((await repo.watchBudgets('ws1', DateTime(2026, 12, 10)).first).single.budget.amountMinor, 5000);
    });

    test('daily spend, six-month totals and top categories', () async {
      final foodId = await repo.addCategory('ws1', 'Food', 'expense');
      final rentId = await repo.addCategory('ws1', 'Rent', 'expense');
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 1000, occurredOn: '2026-10-03', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 500, occurredOn: '2026-10-03', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 20000, occurredOn: '2026-10-01', categoryId: rentId);
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 1000, occurredOn: '2026-09-12', categoryId: foodId);
      await repo.addTransaction(cash, kind: 'income', amountMinor: 50000, occurredOn: '2026-08-31');
      await repo.addTransfer(cash, bank, amountMinor: 3000, occurredOn: '2026-10-03');

      expect(await repo.watchDailySpend('ws1', DateTime(2026, 10), 'BDT').first, {1: 20000, 3: 1500});

      final trend = await repo.watchMonthlyTotals('ws1', DateTime(2026, 10), 'BDT').first;
      expect(trend.map((m) => m.month.month).toList(), [5, 6, 7, 8, 9, 10]);
      expect(trend.map((m) => (m.incomeMinor, m.expenseMinor)).toList().sublist(3),
          [(50000, 0), (0, 1000), (0, 21500)]);

      final top = await repo.watchTopCategories('ws1', DateTime(2026, 10), 'BDT').first;
      expect(top.map((c) => (c.categoryName, c.thisMonthMinor, c.changePercent)).toList(),
          [('Rent', 20000, null), ('Food', 1500, 50)]);

      expect((await repo.watchTransactions('ws1', day: '2026-10-03').first).length, 4); // 2 expenses + 2 legs
      expect((await repo.watchTransactions('ws1', month: DateTime(2026, 9)).first).length, 1);
    });

    test('deleting a category keeps its transactions, uncategorised, and drops its budgets', () async {
      final foodId = await repo.addCategory('ws1', 'Food', 'expense');
      await repo.addTransaction(cash, kind: 'expense', amountMinor: 1000, occurredOn: '2026-10-03', categoryId: foodId);
      await repo.setBudget('ws1', foodId, 5000, 'BDT');
      final food = (await repo.watchCategories('ws1').first).single;
      expect(await repo.transactionCount(foodId), 1);

      await repo.renameCategory(food, 'Groceries');
      expect((await repo.watchCategories('ws1').first).single.name, 'Groceries');

      await repo.deleteCategory(food);
      expect(await repo.watchCategories('ws1').first, isEmpty);
      final remaining = await repo.watchTransactions('ws1').first;
      expect((remaining.single.transaction.categoryId, remaining.single.categoryName), (null, null));
      expect(await repo.watchBudgets('ws1', DateTime(2026, 10)).first, isEmpty);

      final queued = (await outbox()).map((o) => '${o.tableName_} ${o.op} ${o.data}').toList();
      expect(queued.sublist(queued.length - 3), [
        'transactions upsert {"category_id":null}',
        'budgets delete {}',
        'categories delete {}',
      ]);
    });
  });
}

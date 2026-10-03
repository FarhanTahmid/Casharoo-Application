import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/providers.dart';

class AccountBalance {
  AccountBalance(this.account, this.balanceMinor);

  final Account account;

  /// Opening balance plus every transaction on the account.
  final int balanceMinor;
}

class TransactionView {
  TransactionView(this.transaction, this.accountName, this.categoryName);

  final Transaction transaction;
  final String accountName;
  final String? categoryName;
}

class BudgetProgress {
  BudgetProgress(this.budget, this.categoryName, this.spentMinor, {this.recurring});

  /// The limit in force for the month: its override if there is one, else the recurring budget.
  final Budget budget;
  final String categoryName;

  /// Spent in the category during the month, as a positive number.
  final int spentMinor;

  /// The every-month budget of the category, when [budget] is a one-month override of it.
  final Budget? recurring;

  bool get isOverride => budget.month != null;
  bool get isOver => spentMinor > budget.amountMinor;
}

/// Income and expense of one month, both positive.
class MonthTotals {
  MonthTotals(this.month, this.incomeMinor, this.expenseMinor);

  final DateTime month;
  final int incomeMinor;
  final int expenseMinor;
}

/// Spending in a category this month against the month before.
class CategoryChange {
  CategoryChange(this.categoryName, this.thisMonthMinor, this.lastMonthMinor);

  /// Null: uncategorised.
  final String? categoryName;
  final int thisMonthMinor;
  final int lastMonthMinor;

  /// Percentage change, or null when there was nothing to compare with.
  int? get changePercent =>
      lastMonthMinor == 0 ? null : ((thisMonthMinor - lastMonthMinor) * 100 / lastMonthMinor).round();
}

class MonthSummary {
  MonthSummary(this.incomeMinor, this.expenseMinor, this.byCategory);

  final int incomeMinor;

  /// Positive number.
  final int expenseMinor;

  /// Expense per category name (null key: uncategorised), largest first.
  final List<MapEntry<String?, int>> byCategory;
}

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// First and last day of the month containing [date], as ISO dates.
(String, String) monthRange(DateTime date) =>
    (isoDate(DateTime(date.year, date.month, 1)), isoDate(DateTime(date.year, date.month + 1, 0)));

/// The month containing [date], as its first day: the form budgets store ("2026-10-01").
String monthKey(DateTime date) => isoDate(DateTime(date.year, date.month, 1));

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

class LedgerRepository {
  LedgerRepository(this.db, this.store);

  final AppDatabase db;
  final LocalStore store;

  Stream<List<AccountBalance>> watchAccounts(String workspaceId) => db
      .customSelect(
        'SELECT a.*, a.opening_balance_minor + COALESCE(SUM(t.amount_minor), 0) AS balance FROM accounts a '
        'LEFT JOIN transactions t ON t.account_id = a.id AND t.deleted_at IS NULL '
        'WHERE a.workspace_id = ? AND a.deleted_at IS NULL GROUP BY a.id ORDER BY a.is_archived, a.created_at',
        variables: [Variable<String>(workspaceId)],
        readsFrom: {db.accounts, db.transactions},
      )
      .watch()
      .map((rows) => [for (final row in rows) AccountBalance(db.accounts.map(row.data), row.read<int>('balance'))]);

  Stream<List<Category>> watchCategories(String workspaceId) => (db.select(db.categories)
        ..where((c) => c.workspaceId.equals(workspaceId) & c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  /// Newest first. Limited to the month of [month], or to the single [day] (ISO date), when given.
  Stream<List<TransactionView>> watchTransactions(String workspaceId, {DateTime? month, String? day}) {
    final (first, last) =
        day != null ? (day, day) : (month != null ? monthRange(month) : ('0000-01-01', '9999-12-31'));
    return db
        .customSelect(
          'SELECT t.*, a.name AS a_name, c.name AS c_name FROM transactions t '
          'JOIN accounts a ON a.id = t.account_id LEFT JOIN categories c ON c.id = t.category_id AND c.deleted_at IS NULL '
          'WHERE t.workspace_id = ? AND t.deleted_at IS NULL AND t.occurred_on BETWEEN ? AND ? '
          'ORDER BY t.occurred_on DESC, t.created_at DESC',
          variables: [Variable<String>(workspaceId), Variable<String>(first), Variable<String>(last)],
          readsFrom: {db.transactions, db.accounts, db.categories},
        )
        .watch()
        .map((rows) => [
              for (final row in rows)
                TransactionView(
                  db.transactions.map(row.data),
                  row.read<String>('a_name'),
                  row.readNullable<String>('c_name'),
                ),
            ]);
  }

  /// The budget in force for each category in [month], with what was spent.
  /// A one-month override replaces the category's recurring budget for that month.
  Stream<List<BudgetProgress>> watchBudgets(String workspaceId, DateTime month) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT b.*, c.name AS c_name, COALESCE((SELECT -SUM(t.amount_minor) FROM transactions t '
          "WHERE t.category_id = b.category_id AND t.kind = 'expense' AND t.deleted_at IS NULL "
          'AND t.occurred_on BETWEEN ? AND ?), 0) AS spent FROM budgets b '
          'JOIN categories c ON c.id = b.category_id AND c.deleted_at IS NULL '
          'WHERE b.workspace_id = ? AND b.deleted_at IS NULL AND (b.month IS NULL OR b.month = ?) ORDER BY c.name',
          variables: [
            Variable<String>(first),
            Variable<String>(last),
            Variable<String>(workspaceId),
            Variable<String>(monthKey(month)),
          ],
          readsFrom: {db.budgets, db.categories, db.transactions},
        )
        .watch()
        .map((rows) {
      final recurring = <String, Budget>{};
      final overrides = <String, (Budget, String, int)>{};
      final order = <String, (String, int)>{};
      for (final row in rows) {
        final budget = db.budgets.map(row.data);
        final name = row.read<String>('c_name');
        final spent = row.read<int>('spent');
        order[budget.categoryId] = (name, spent);
        if (budget.month == null) {
          recurring[budget.categoryId] = budget;
        } else {
          overrides[budget.categoryId] = (budget, name, spent);
        }
      }
      return [
        for (final MapEntry(key: categoryId, value: (name, spent)) in order.entries)
          if (overrides[categoryId] case (final override, _, _))
            BudgetProgress(override, name, spent, recurring: recurring[categoryId])
          else
            BudgetProgress(recurring[categoryId]!, name, spent),
      ];
    });
  }

  /// Expense per day of [month] in [currency]: day of month -> amount spent (positive).
  Stream<Map<int, int>> watchDailySpend(String workspaceId, DateTime month, String currency) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT occurred_on AS day, -SUM(amount_minor) AS spent FROM transactions '
          "WHERE workspace_id = ? AND deleted_at IS NULL AND kind = 'expense' AND currency = ? "
          'AND occurred_on BETWEEN ? AND ? GROUP BY occurred_on',
          variables: [
            Variable<String>(workspaceId),
            Variable<String>(currency),
            Variable<String>(first),
            Variable<String>(last),
          ],
          readsFrom: {db.transactions},
        )
        .watch()
        .map((rows) => {
              for (final row in rows) DateTime.parse(row.read<String>('day')).day: row.read<int>('spent'),
            });
  }

  /// Income and expense for the [count] months ending with [month], oldest first.
  Stream<List<MonthTotals>> watchMonthlyTotals(String workspaceId, DateTime month, String currency, {int count = 6}) {
    final start = DateTime(month.year, month.month - count + 1, 1);
    final (_, last) = monthRange(month);
    return db
        .customSelect(
          "SELECT substr(occurred_on, 1, 7) AS ym, kind, SUM(amount_minor) AS total FROM transactions "
          "WHERE workspace_id = ? AND deleted_at IS NULL AND kind != 'transfer' AND currency = ? "
          'AND occurred_on BETWEEN ? AND ? GROUP BY ym, kind',
          variables: [
            Variable<String>(workspaceId),
            Variable<String>(currency),
            Variable<String>(isoDate(start)),
            Variable<String>(last),
          ],
          readsFrom: {db.transactions},
        )
        .watch()
        .map((rows) {
      final income = <String, int>{}, expense = <String, int>{};
      for (final row in rows) {
        final key = row.read<String>('ym');
        final total = row.read<int>('total');
        if (row.read<String>('kind') == 'income') {
          income[key] = (income[key] ?? 0) + total;
        } else {
          expense[key] = (expense[key] ?? 0) - total;
        }
      }
      return [
        for (var i = 0; i < count; i++)
          () {
            final m = DateTime(start.year, start.month + i, 1);
            final key = monthKey(m).substring(0, 7);
            return MonthTotals(m, income[key] ?? 0, expense[key] ?? 0);
          }(),
      ];
    });
  }

  /// The categories spent on most in [month], each with the month before for comparison.
  Stream<List<CategoryChange>> watchTopCategories(String workspaceId, DateTime month, String currency,
      {int limit = 5}) {
    final (first, last) = monthRange(month);
    final (previousFirst, _) = monthRange(DateTime(month.year, month.month - 1, 1));
    return db
        .customSelect(
          'SELECT c.name AS c_name, '
          'SUM(CASE WHEN t.occurred_on >= ? THEN -t.amount_minor ELSE 0 END) AS this_month, '
          'SUM(CASE WHEN t.occurred_on < ? THEN -t.amount_minor ELSE 0 END) AS last_month '
          'FROM transactions t LEFT JOIN categories c ON c.id = t.category_id AND c.deleted_at IS NULL '
          "WHERE t.workspace_id = ? AND t.deleted_at IS NULL AND t.kind = 'expense' AND t.currency = ? "
          'AND t.occurred_on BETWEEN ? AND ? GROUP BY c.name HAVING this_month > 0 '
          'ORDER BY this_month DESC LIMIT ?',
          variables: [
            Variable<String>(first),
            Variable<String>(first),
            Variable<String>(workspaceId),
            Variable<String>(currency),
            Variable<String>(previousFirst),
            Variable<String>(last),
            Variable<int>(limit),
          ],
          readsFrom: {db.transactions, db.categories},
        )
        .watch()
        .map((rows) => [
              for (final row in rows)
                CategoryChange(row.readNullable<String>('c_name'), row.read<int>('this_month'), row.read<int>('last_month')),
            ]);
  }

  /// Income, expense and expense-by-category for one month, in one currency.
  Stream<MonthSummary> watchMonth(String workspaceId, DateTime month, String currency) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT t.kind AS kind, c.name AS c_name, SUM(t.amount_minor) AS total FROM transactions t '
          'LEFT JOIN categories c ON c.id = t.category_id AND c.deleted_at IS NULL '
          "WHERE t.workspace_id = ? AND t.deleted_at IS NULL AND t.kind != 'transfer' AND t.currency = ? "
          'AND t.occurred_on BETWEEN ? AND ? GROUP BY t.kind, c.name',
          variables: [
            Variable<String>(workspaceId),
            Variable<String>(currency),
            Variable<String>(first),
            Variable<String>(last),
          ],
          readsFrom: {db.transactions, db.categories},
        )
        .watch()
        .map((rows) {
      var income = 0, expense = 0;
      final byCategory = <String?, int>{};
      for (final row in rows) {
        final total = row.read<int>('total');
        if (row.read<String>('kind') == 'income') {
          income += total;
        } else {
          expense -= total;
          final name = row.readNullable<String>('c_name');
          byCategory[name] = (byCategory[name] ?? 0) - total;
        }
      }
      final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return MonthSummary(income, expense, sorted);
    });
  }

  Future<String> addAccount(String workspaceId, {
    required String name,
    required String kind,
    required String currency,
    int openingBalanceMinor = 0,
  }) =>
      store.create('accounts', workspaceId, {
        'name': name,
        'kind': kind,
        'currency': currency,
        'opening_balance_minor': openingBalanceMinor,
        'is_archived': false,
      });

  Future<void> updateAccount(Account original, {
    required String name,
    required String kind,
    required int openingBalanceMinor,
    required bool isArchived,
  }) =>
      store.update('accounts', original.id, {
        if (name != original.name) 'name': name,
        if (kind != original.kind) 'kind': kind,
        if (openingBalanceMinor != original.openingBalanceMinor) 'opening_balance_minor': openingBalanceMinor,
        if (isArchived != original.isArchived) 'is_archived': isArchived,
      });

  Future<String> addCategory(String workspaceId, String name, String kind) =>
      store.create('categories', workspaceId, {'name': name, 'kind': kind});

  Future<void> renameCategory(Category category, String name) =>
      name == category.name ? Future.value() : store.update('categories', category.id, {'name': name});

  /// Transactions filed under the category, for the warning before deleting it.
  Future<int> transactionCount(String categoryId) async {
    final count = db.transactions.id.count();
    final query = db.selectOnly(db.transactions)
      ..addColumns([count])
      ..where(db.transactions.categoryId.equals(categoryId) & db.transactions.deletedAt.isNull());
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// Its transactions stay, uncategorised; its budgets go with it.
  Future<void> deleteCategory(Category category) => db.transaction(() async {
        final transactions = await (db.select(db.transactions)
              ..where((t) => t.categoryId.equals(category.id) & t.deletedAt.isNull()))
            .get();
        for (final t in transactions) {
          await store.update('transactions', t.id, {'category_id': null});
        }
        final budgets = await (db.select(db.budgets)
              ..where((b) => b.categoryId.equals(category.id) & b.deletedAt.isNull()))
            .get();
        for (final b in budgets) {
          await store.remove('budgets', b.id);
        }
        await store.remove('categories', category.id);
      });

  /// [amountMinor] is what the user typed, always positive; the sign follows [kind].
  Future<String> addTransaction(Account account, {
    required String kind,
    required int amountMinor,
    required String occurredOn,
    String? categoryId,
    String note = '',
  }) =>
      store.create(
        'transactions',
        account.workspaceId,
        {
          'account_id': account.id,
          'category_id': categoryId,
          'kind': kind,
          'amount_minor': kind == 'expense' ? -amountMinor : amountMinor,
          'transfer_group_id': null,
          'occurred_on': occurredOn,
          'note': note,
          'source': 'manual',
        },
        localOnly: {'currency': account.currency},
      );

  /// Money moving between two of the user's own accounts: two legs that cancel out.
  Future<void> addTransfer(Account from, Account to, {
    required int amountMinor,
    required String occurredOn,
    String note = '',
  }) =>
      db.transaction(() async {
        final group = newId();
        for (final (account, signed) in [(from, -amountMinor), (to, amountMinor)]) {
          await store.create(
            'transactions',
            account.workspaceId,
            {
              'account_id': account.id,
              'category_id': null,
              'kind': 'transfer',
              'amount_minor': signed,
              'transfer_group_id': group,
              'occurred_on': occurredOn,
              'note': note,
              'source': 'manual',
            },
            localOnly: {'currency': account.currency},
          );
        }
      });

  Future<void> updateTransaction(Transaction original, {
    required int amountMinor,
    required String occurredOn,
    String? categoryId,
    String note = '',
  }) {
    final signed = original.amountMinor < 0 ? -amountMinor : amountMinor;
    return store.update('transactions', original.id, {
      if (signed != original.amountMinor) 'amount_minor': signed,
      if (occurredOn != original.occurredOn) 'occurred_on': occurredOn,
      if (categoryId != original.categoryId) 'category_id': categoryId,
      if (note != original.note) 'note': note,
    });
  }

  /// Deleting one leg of a transfer deletes the other as well.
  Future<void> deleteTransaction(Transaction transaction) => db.transaction(() async {
        final group = transaction.transferGroupId;
        if (group == null) {
          await store.remove('transactions', transaction.id);
          return;
        }
        final legs = await (db.select(db.transactions)
              ..where((t) => t.transferGroupId.equals(group) & t.deletedAt.isNull()))
            .get();
        for (final leg in legs) {
          await store.remove('transactions', leg.id);
        }
      });

  /// A category has one recurring budget and at most one override per month
  /// ([month] as from [monthKey]); setting either again changes its amount.
  Future<void> setBudget(String workspaceId, String categoryId, int amountMinor, String currency,
      {String? month}) async {
    final existing = await (db.select(db.budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              b.deletedAt.isNull() &
              (month == null ? b.month.isNull() : b.month.equals(month)))
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) {
      await store.create('budgets', workspaceId, {
        'category_id': categoryId,
        'amount_minor': amountMinor,
        'currency': currency,
        'month': month,
      });
    } else if (existing.amountMinor != amountMinor) {
      await store.update('budgets', existing.id, {'amount_minor': amountMinor});
    }
  }

  Future<void> deleteBudget(String budgetId) => store.remove('budgets', budgetId);
}

final ledgerRepositoryProvider = Provider<LedgerRepository>(
  (ref) => LedgerRepository(ref.watch(databaseProvider), ref.watch(localStoreProvider)),
);

final accountsProvider = StreamProvider.family<List<AccountBalance>, String>(
  (ref, workspaceId) => ref.watch(ledgerRepositoryProvider).watchAccounts(workspaceId),
);

final categoriesProvider = StreamProvider.family<List<Category>, String>(
  (ref, workspaceId) => ref.watch(ledgerRepositoryProvider).watchCategories(workspaceId),
);

/// The month the personal screens show; the overview, transactions and budget calendar share it.
class SelectedMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime month) => state = DateTime(month.year, month.month);
  void previous() => set(DateTime(state.year, state.month - 1));
  void next() => set(DateTime(state.year, state.month + 1));
}

final selectedMonthProvider = NotifierProvider<SelectedMonthController, DateTime>(SelectedMonthController.new);

final transactionsProvider = StreamProvider.family<List<TransactionView>, String>(
  (ref, workspaceId) =>
      ref.watch(ledgerRepositoryProvider).watchTransactions(workspaceId, month: ref.watch(selectedMonthProvider)),
);

final budgetsProvider = StreamProvider.family<List<BudgetProgress>, String>(
  (ref, workspaceId) => ref.watch(ledgerRepositoryProvider).watchBudgets(workspaceId, ref.watch(selectedMonthProvider)),
);

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/entitlements/plan_guard.dart';
import '../../core/providers.dart';

class AccountBalance {
  AccountBalance(this.account, this.balanceMinor);

  final Account account;

  /// Opening balance plus every transaction on the account.
  final int balanceMinor;
}

class TransactionView {
  TransactionView(this.transaction, this.accountName, this.categoryName, {this.categoryColor});

  final Transaction transaction;
  final String accountName;
  final String? categoryName;

  /// What the user chose for the category, if anything (see categoryFill).
  final String? categoryColor;
}

class BudgetProgress {
  BudgetProgress(this.budget, this.categoryName, this.spentMinor, {this.recurring, this.categoryColor});

  /// The limit in force for the month: its override if there is one, else the recurring budget.
  final Budget budget;
  final String categoryName;
  final String? categoryColor;

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

/// What one category took of a month's spending.
class CategorySpend {
  CategorySpend(this.categoryId, this.name, this.color, this.amountMinor,
      {this.count = 0, this.largestMinor = 0, this.previousMinor = 0});

  /// Null: uncategorised.
  final String? categoryId;
  final String? name;
  final String? color;

  /// Positive number.
  final int amountMinor;

  /// How many expenses make up [amountMinor], and the biggest of them (positive).
  final int count;
  final int largestMinor;

  /// Spent in the category the month before (positive).
  final int previousMinor;

  /// Percentage change on the month before, or null when there was nothing to compare with.
  int? get changePercent => previousMinor == 0 ? null : ((amountMinor - previousMinor) * 100 / previousMinor).round();
}

class MonthSummary {
  MonthSummary(this.incomeMinor, this.expenseMinor, this.byCategory);

  final int incomeMinor;

  /// Positive number.
  final int expenseMinor;

  /// Expense per category, largest first.
  final List<CategorySpend> byCategory;
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
  LedgerRepository(this.db, this.store, [this.plan]);

  final AppDatabase db;
  final LocalStore store;

  /// Refuses what the plan does not allow with a PlanLimitException, before
  /// anything is written. Without one nothing is checked here.
  final PlanGuard? plan;

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
          'SELECT t.*, a.name AS a_name, c.name AS c_name, c.color AS c_color FROM transactions t '
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
                  categoryColor: row.readNullable<String>('c_color'),
                ),
            ]);
  }

  /// The budget in force for each category in [month], with what was spent.
  /// A one-month override replaces the category's recurring budget for that month.
  Stream<List<BudgetProgress>> watchBudgets(String workspaceId, DateTime month) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT b.*, c.name AS c_name, c.color AS c_color, COALESCE((SELECT -SUM(t.amount_minor) FROM transactions t '
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
      final order = <String, (String, int, String?)>{};
      for (final row in rows) {
        final budget = db.budgets.map(row.data);
        final name = row.read<String>('c_name');
        final spent = row.read<int>('spent');
        order[budget.categoryId] = (name, spent, row.readNullable<String>('c_color'));
        if (budget.month == null) {
          recurring[budget.categoryId] = budget;
        } else {
          overrides[budget.categoryId] = (budget, name, spent);
        }
      }
      return [
        for (final MapEntry(key: categoryId, value: (name, spent, color)) in order.entries)
          if (overrides[categoryId] case (final override, _, _))
            BudgetProgress(override, name, spent, recurring: recurring[categoryId], categoryColor: color)
          else
            BudgetProgress(recurring[categoryId]!, name, spent, categoryColor: color),
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

  /// Income, expense and expense-by-category for one month, in one currency.
  /// Each category also carries what it took the month before.
  Stream<MonthSummary> watchMonth(String workspaceId, DateTime month, String currency) {
    final (first, last) = monthRange(month);
    final (previousFirst, _) = monthRange(DateTime(month.year, month.month - 1, 1));
    return db
        .customSelect(
          'SELECT t.kind AS kind, c.id AS c_id, c.name AS c_name, c.color AS c_color, '
          'SUM(CASE WHEN t.occurred_on >= ? THEN t.amount_minor ELSE 0 END) AS total, '
          'SUM(CASE WHEN t.occurred_on < ? THEN t.amount_minor ELSE 0 END) AS previous, '
          'SUM(CASE WHEN t.occurred_on >= ? THEN 1 ELSE 0 END) AS n, '
          // Expenses are negative, so the smallest is the biggest
          'MIN(CASE WHEN t.occurred_on >= ? THEN t.amount_minor END) AS largest '
          'FROM transactions t '
          'LEFT JOIN categories c ON c.id = t.category_id AND c.deleted_at IS NULL '
          "WHERE t.workspace_id = ? AND t.deleted_at IS NULL AND t.kind != 'transfer' AND t.currency = ? "
          'AND t.occurred_on BETWEEN ? AND ? GROUP BY t.kind, c.id',
          variables: [
            for (var i = 0; i < 4; i++) Variable<String>(first),
            Variable<String>(workspaceId),
            Variable<String>(currency),
            Variable<String>(previousFirst),
            Variable<String>(last),
          ],
          readsFrom: {db.transactions, db.categories},
        )
        .watch()
        .map((rows) {
      var income = 0, expense = 0;
      final byCategory = <CategorySpend>[];
      for (final row in rows) {
        final total = row.read<int>('total');
        final count = row.read<int>('n');
        if (count == 0) continue; // only the month before
        if (row.read<String>('kind') == 'income') {
          income += total;
        } else {
          expense -= total;
          byCategory.add(CategorySpend(
            row.readNullable<String>('c_id'),
            row.readNullable<String>('c_name'),
            row.readNullable<String>('c_color'),
            -total,
            count: count,
            largestMinor: -(row.readNullable<int>('largest') ?? 0),
            previousMinor: -row.read<int>('previous'),
          ));
        }
      }
      byCategory.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
      return MonthSummary(income, expense, byCategory);
    });
  }

  Future<String> addAccount(String workspaceId, {
    required String name,
    required String kind,
    required String currency,
    int openingBalanceMinor = 0,
  }) async {
    await plan?.roomFor(F.personalAccounts, workspaceId);
    return store.create('accounts', workspaceId, {
      'name': name,
      'kind': kind,
      'currency': currency,
      'opening_balance_minor': openingBalanceMinor,
      'is_archived': false,
    });
  }

  Future<void> updateAccount(Account original, {
    required String name,
    required String kind,
    required int openingBalanceMinor,
    required bool isArchived,
  }) async {
    // An archived account does not count, so bringing one back needs room like a new one
    if (original.isArchived && !isArchived) await plan?.roomFor(F.personalAccounts, original.workspaceId);
    // A locked account can still be archived, which is one way back under the limit
    if (!isArchived) plan?.writable(F.personalAccounts, original.id);
    await store.update('accounts', original.id, {
      if (name != original.name) 'name': name,
      if (kind != original.kind) 'kind': kind,
      if (openingBalanceMinor != original.openingBalanceMinor) 'opening_balance_minor': openingBalanceMinor,
      if (isArchived != original.isArchived) 'is_archived': isArchived,
    });
  }

  /// [color] is '#RRGGBB'; without one the app picks the colour (categoryFill).
  Future<String> addCategory(String workspaceId, String name, String kind, {String? color}) async {
    await plan?.roomFor(F.customCategories, workspaceId);
    return store.create('categories', workspaceId, {'name': name, 'kind': kind, if (color != null) 'color': color});
  }

  /// Sends only what differs from [category]. A null [color] hands the choice back to the app.
  Future<void> updateCategory(Category category, {required String name, required String? color}) async {
    final changes = {
      if (name != category.name) 'name': name,
      if (color != category.color) 'color': color,
    };
    if (changes.isEmpty) return;
    plan?.writable(F.customCategories, category.id);
    await store.update('categories', category.id, changes);
  }

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
  }) async {
    // A locked account is read-only, its transactions included
    plan?.writable(F.personalAccounts, account.id);
    return store.create(
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
  }

  /// Money moving between two of the user's own accounts: two legs that cancel out.
  Future<void> addTransfer(Account from, Account to, {
    required int amountMinor,
    required String occurredOn,
    String note = '',
  }) async {
    plan?.writable(F.personalAccounts, from.id);
    plan?.writable(F.personalAccounts, to.id);
    return _addTransfer(from, to, amountMinor: amountMinor, occurredOn: occurredOn, note: note);
  }

  Future<void> _addTransfer(Account from, Account to, {
    required int amountMinor,
    required String occurredOn,
    required String note,
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
  }) async {
    plan?.writable(F.personalAccounts, original.accountId);
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
    // The every-month budget is for everyone; a different limit for one month is a plan feature
    if (month != null) await plan?.require(F.budgetMonthOverride, workspaceId);
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
  (ref) => LedgerRepository(ref.watch(databaseProvider), ref.watch(localStoreProvider), ref.watch(planGuardProvider)),
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

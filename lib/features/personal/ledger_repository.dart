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
  BudgetProgress(this.budget, this.categoryName, this.spentMinor);

  final Budget budget;
  final String categoryName;

  /// Spent in the category this calendar month, as a positive number.
  final int spentMinor;

  bool get isOver => spentMinor > budget.amountMinor;
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

  Stream<List<TransactionView>> watchTransactions(String workspaceId) => db
      .customSelect(
        'SELECT t.*, a.name AS a_name, c.name AS c_name FROM transactions t '
        'JOIN accounts a ON a.id = t.account_id LEFT JOIN categories c ON c.id = t.category_id '
        'WHERE t.workspace_id = ? AND t.deleted_at IS NULL ORDER BY t.occurred_on DESC, t.created_at DESC',
        variables: [Variable<String>(workspaceId)],
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

  Stream<List<BudgetProgress>> watchBudgets(String workspaceId, DateTime month) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT b.*, c.name AS c_name, COALESCE(-SUM(t.amount_minor), 0) AS spent FROM budgets b '
          'JOIN categories c ON c.id = b.category_id '
          "LEFT JOIN transactions t ON t.category_id = b.category_id AND t.kind = 'expense' "
          'AND t.deleted_at IS NULL AND t.occurred_on BETWEEN ? AND ? '
          'WHERE b.workspace_id = ? AND b.deleted_at IS NULL GROUP BY b.id ORDER BY c.name',
          variables: [Variable<String>(first), Variable<String>(last), Variable<String>(workspaceId)],
          readsFrom: {db.budgets, db.categories, db.transactions},
        )
        .watch()
        .map((rows) => [
              for (final row in rows)
                BudgetProgress(db.budgets.map(row.data), row.read<String>('c_name'), row.read<int>('spent')),
            ]);
  }

  /// Income, expense and expense-by-category for one month, in one currency.
  Stream<MonthSummary> watchMonth(String workspaceId, DateTime month, String currency) {
    final (first, last) = monthRange(month);
    return db
        .customSelect(
          'SELECT t.kind AS kind, c.name AS c_name, SUM(t.amount_minor) AS total FROM transactions t '
          'LEFT JOIN categories c ON c.id = t.category_id '
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

  /// One budget per category: setting it again changes the amount.
  Future<void> setBudget(String workspaceId, String categoryId, int amountMinor, String currency) async {
    final existing = await (db.select(db.budgets)
          ..where((b) => b.categoryId.equals(categoryId) & b.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) {
      await store.create('budgets', workspaceId, {
        'category_id': categoryId,
        'amount_minor': amountMinor,
        'currency': currency,
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

final transactionsProvider = StreamProvider.family<List<TransactionView>, String>(
  (ref, workspaceId) => ref.watch(ledgerRepositoryProvider).watchTransactions(workspaceId),
);

final budgetsProvider = StreamProvider.family<List<BudgetProgress>, String>(
  (ref, workspaceId) => ref.watch(ledgerRepositoryProvider).watchBudgets(workspaceId, DateTime.now()),
);

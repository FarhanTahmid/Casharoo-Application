import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/local_store.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/entitlements/plan_guard.dart';
import '../../core/providers.dart';

/// Seeded into every new cashbook, same lists as the server uses.
const defaultEntryCategories = [
  'Housing', 'Transportation', 'Food', 'Utilities', 'Clothing', 'Medical/Healthcare',
  'Insurance', 'Household Items/Supplies', 'Personal', 'Debt', 'Retirement', 'Education',
  'Savings', 'Gifts/Donations', 'Entertainment', 'Income', 'Other',
];
const defaultPaymentMethods = [
  'Cash', 'Credit Card', 'Debit Card', 'bKash', 'Nagad', 'Rocket', 'Bank Transfer', 'Online', 'Other',
];

class CashbookSummary {
  CashbookSummary(this.book, this.cashInMinor, this.cashOutMinor, this.entryCount);

  final Cashbook book;
  final int cashInMinor;
  final int cashOutMinor;
  final int entryCount;

  int get balanceMinor => cashInMinor - cashOutMinor;
}

class EntryView {
  EntryView(this.entry, this.categoryName, this.paymentMethodName, {this.categoryColor});

  final Entry entry;
  final String? categoryName;

  /// What was chosen for the category, if anything (see categoryFill).
  final String? categoryColor;
  final String? paymentMethodName;

  bool get isCashIn => entry.entryType == 'cash_in';
}

class BreakdownRow {
  BreakdownRow(this.name, this.cashInMinor, this.cashOutMinor, {this.id, this.color});

  /// Null for entries without a category or payment method.
  final String? id;
  final String? name;

  /// A category's chosen colour; payment methods have none.
  final String? color;
  final int cashInMinor;
  final int cashOutMinor;
}

class CashbookRepository {
  CashbookRepository(this.db, this.store, [this.plan]);

  final AppDatabase db;
  final LocalStore store;

  /// Refuses what the plan does not allow with a PlanLimitException, before
  /// anything is written. Without one nothing is checked here.
  final PlanGuard? plan;

  static const _totals = "COALESCE(SUM(CASE WHEN e.entry_type = 'cash_in' THEN e.amount_minor END), 0) AS cash_in, "
      "COALESCE(SUM(CASE WHEN e.entry_type = 'cash_out' THEN e.amount_minor END), 0) AS cash_out";

  Stream<List<CashbookSummary>> watchCashbooks(String workspaceId) => db
      .customSelect(
        'SELECT b.*, $_totals, COUNT(e.id) AS entry_count FROM cashbooks b '
        'LEFT JOIN entries e ON e.cashbook_id = b.id AND e.deleted_at IS NULL '
        'WHERE b.workspace_id = ? AND b.deleted_at IS NULL GROUP BY b.id ORDER BY b.created_at DESC',
        variables: [Variable<String>(workspaceId)],
        readsFrom: {db.cashbooks, db.entries},
      )
      .watch()
      .map((rows) => [
            for (final row in rows)
              CashbookSummary(
                db.cashbooks.map(row.data),
                row.read<int>('cash_in'),
                row.read<int>('cash_out'),
                row.read<int>('entry_count'),
              ),
          ]);

  Stream<CashbookSummary?> watchCashbook(String bookId) => db
      .customSelect(
        'SELECT b.*, $_totals, COUNT(e.id) AS entry_count FROM cashbooks b '
        'LEFT JOIN entries e ON e.cashbook_id = b.id AND e.deleted_at IS NULL '
        'WHERE b.id = ? AND b.deleted_at IS NULL GROUP BY b.id',
        variables: [Variable<String>(bookId)],
        readsFrom: {db.cashbooks, db.entries},
      )
      .watchSingleOrNull()
      .map((row) => row == null
          ? null
          : CashbookSummary(
              db.cashbooks.map(row.data),
              row.read<int>('cash_in'),
              row.read<int>('cash_out'),
              row.read<int>('entry_count'),
            ));

  Stream<List<EntryView>> watchEntries(String bookId) => db
      .customSelect(
        'SELECT e.*, c.category_name AS c_name, c.color AS c_color, p.payment_method_name AS p_name FROM entries e '
        'LEFT JOIN entry_categories c ON c.id = e.category_id '
        'LEFT JOIN payment_methods p ON p.id = e.payment_method_id '
        'WHERE e.cashbook_id = ? AND e.deleted_at IS NULL ORDER BY e.entry_date DESC, e.created_at DESC',
        variables: [Variable<String>(bookId)],
        readsFrom: {db.entries, db.entryCategories, db.paymentMethods},
      )
      .watch()
      .map((rows) => [
            for (final row in rows)
              EntryView(
                db.entries.map(row.data),
                row.readNullable<String>('c_name'),
                row.readNullable<String>('p_name'),
                categoryColor: row.readNullable<String>('c_color'),
              ),
          ]);

  Stream<List<EntryCategory>> watchCategories(String bookId) => (db.select(db.entryCategories)
        ..where((c) => c.cashbookId.equals(bookId) & c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.categoryName)]))
      .watch();

  Stream<List<PaymentMethod>> watchPaymentMethods(String bookId) => (db.select(db.paymentMethods)
        ..where((p) => p.cashbookId.equals(bookId) & p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.paymentMethodName)]))
      .watch();

  /// Totals per category (or per payment method) for the report screen.
  Stream<List<BreakdownRow>> watchBreakdown(String bookId, {required bool byCategory}) {
    final join = byCategory
        ? 'LEFT JOIN entry_categories x ON x.id = e.category_id'
        : 'LEFT JOIN payment_methods x ON x.id = e.payment_method_id';
    final name = byCategory ? 'x.category_name' : 'x.payment_method_name';
    return db
        .customSelect(
          'SELECT x.id AS x_id, $name AS name, ${byCategory ? 'x.color' : 'NULL'} AS color, $_totals '
          'FROM entries e $join '
          'WHERE e.cashbook_id = ? AND e.deleted_at IS NULL GROUP BY x.id ORDER BY cash_out DESC, cash_in DESC',
          variables: [Variable<String>(bookId)],
          readsFrom: {db.entries, db.entryCategories, db.paymentMethods},
        )
        .watch()
        .map((rows) => [
              for (final row in rows)
                BreakdownRow(
                  row.readNullable<String>('name'),
                  row.read<int>('cash_in'),
                  row.read<int>('cash_out'),
                  id: row.readNullable<String>('x_id'),
                  color: row.readNullable<String>('color'),
                ),
            ]);
  }

  /// What the signed-in user may do in this book: 'admin', 'edit' or 'view'.
  Future<String> permissionFor(Cashbook book, Workspace workspace) async {
    if (workspace.role == 'owner' || workspace.role == 'admin') return 'admin';
    if (workspace.role == 'viewer') return 'view';
    // Staff only ever receive their own grants
    final grant = await (db.select(db.cashbookMembers)
          ..where((m) => m.cashbookId.equals(book.id) & m.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return switch (grant?.role) { 'admin' => 'admin', 'editor' => 'edit', _ => 'view' };
  }

  Future<String> createCashbook(String workspaceId, String name, String currency) async {
    await plan?.roomFor(F.businessCashbooks, workspaceId);
    return _createCashbook(workspaceId, name, currency);
  }

  Future<String> _createCashbook(String workspaceId, String name, String currency) => db.transaction(() async {
        final bookId = await store.create('cashbooks', workspaceId, {
          'book_name': name,
          'description': null,
          'currency': currency,
        });
        for (final category in defaultEntryCategories) {
          await store.create('entry_categories', workspaceId, {
            'cashbook_id': bookId,
            'category_name': category,
            'is_default': true,
          });
        }
        for (final method in defaultPaymentMethods) {
          await store.create('payment_methods', workspaceId, {
            'cashbook_id': bookId,
            'payment_method_name': method,
            'is_default': true,
          });
        }
        return bookId;
      });

  Future<void> renameCashbook(String bookId, String name) async {
    plan?.writable(F.businessCashbooks, bookId);
    await store.update('cashbooks', bookId, {'book_name': name});
  }

  /// The server tombstones the book's entries, categories, payment methods and
  /// grants with it; the same happens here at once, without queueing them.
  Future<void> deleteCashbook(String bookId) => db.transaction(() async {
        await store.remove('cashbooks', bookId);
        final now = nowIso();
        for (final table in const ['entries', 'entry_categories', 'payment_methods', 'cashbook_members']) {
          await db.customUpdate(
            'UPDATE "$table" SET deleted_at = ?, updated_at = ? WHERE cashbook_id = ? AND deleted_at IS NULL',
            variables: [Variable<String>(now), Variable<String>(now), Variable<String>(bookId)],
            updates: {db.tableByName(table)},
          );
        }
      });

  /// [color] is '#RRGGBB'; without one the app picks the colour (categoryFill).
  Future<String> addCategory(Cashbook book, String name, {String? color}) =>
      store.create('entry_categories', book.workspaceId, {
        'cashbook_id': book.id,
        'category_name': name,
        'is_default': false,
        if (color != null) 'color': color,
      });

  /// Sends only what differs from [category]. A null [color] hands the choice back to the app.
  Future<void> updateCategory(EntryCategory category, {required String name, required String? color}) async {
    final changes = {
      if (name != category.categoryName) 'category_name': name,
      if (color != category.color) 'color': color,
    };
    if (changes.isEmpty) return;
    // A locked book is read-only, its categories included
    plan?.writable(F.businessCashbooks, category.cashbookId);
    await store.update('entry_categories', category.id, changes);
  }

  Future<String> addPaymentMethod(Cashbook book, String name) => store.create('payment_methods', book.workspaceId, {
        'cashbook_id': book.id,
        'payment_method_name': name,
        'is_default': false,
      });

  Future<String> addEntry(
    Cashbook book, {
    required String entryType,
    required int amountMinor,
    required String entryDate,
    String? title,
    String? remarks,
    String? categoryId,
    String? paymentMethodId,
  }) async {
    // A locked book is read-only, entries included
    plan?.writable(F.businessCashbooks, book.id);
    return store.create(
      'entries',
      book.workspaceId,
      {
        'cashbook_id': book.id,
        'entry_type': entryType,
        'amount_minor': amountMinor,
        'entry_date': entryDate,
        'title': title,
        'remarks': remarks,
        'category_id': categoryId,
        'payment_method_id': paymentMethodId,
        'source': 'manual',
      },
      localOnly: {'currency': book.currency},
    );
  }

  /// Sends only the fields that differ from [original].
  Future<void> updateEntry(
    Entry original, {
    required int amountMinor,
    required String entryDate,
    String? title,
    String? remarks,
    String? categoryId,
    String? paymentMethodId,
  }) async {
    plan?.writable(F.businessCashbooks, original.cashbookId);
    return store.update('entries', original.id, {
      if (amountMinor != original.amountMinor) 'amount_minor': amountMinor,
      if (entryDate != original.entryDate) 'entry_date': entryDate,
      if (title != original.title) 'title': title,
      if (remarks != original.remarks) 'remarks': remarks,
      if (categoryId != original.categoryId) 'category_id': categoryId,
      if (paymentMethodId != original.paymentMethodId) 'payment_method_id': paymentMethodId,
    });
  }

  Future<void> deleteEntry(String entryId) => store.remove('entries', entryId);
}

final cashbookRepositoryProvider = Provider<CashbookRepository>(
  (ref) => CashbookRepository(ref.watch(databaseProvider), ref.watch(localStoreProvider), ref.watch(planGuardProvider)),
);

final cashbooksProvider = StreamProvider.family<List<CashbookSummary>, String>(
  (ref, workspaceId) => ref.watch(cashbookRepositoryProvider).watchCashbooks(workspaceId),
);

final cashbookProvider = StreamProvider.family<CashbookSummary?, String>(
  (ref, bookId) => ref.watch(cashbookRepositoryProvider).watchCashbook(bookId),
);

final entriesProvider = StreamProvider.family<List<EntryView>, String>(
  (ref, bookId) => ref.watch(cashbookRepositoryProvider).watchEntries(bookId),
);

final entryCategoriesProvider = StreamProvider.family<List<EntryCategory>, String>(
  (ref, bookId) => ref.watch(cashbookRepositoryProvider).watchCategories(bookId),
);

final paymentMethodsProvider = StreamProvider.family<List<PaymentMethod>, String>(
  (ref, bookId) => ref.watch(cashbookRepositoryProvider).watchPaymentMethods(bookId),
);

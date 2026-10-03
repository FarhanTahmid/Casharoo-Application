import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database.steps.dart';

part 'database.g.dart';

// Column names match the server's sync rows one to one (bookName -> book_name),
// so the sync engine can copy rows in without per-table code. Timestamps and
// dates stay as the ISO text the server sends.

/// Columns every synced row carries.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  IntColumn get serverSeq => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// From the REST API, not the change log.
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get defaultCurrency => text()();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();
  TextColumn get role => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Cashbooks extends Table with SyncColumns {
  TextColumn get bookName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currency => text()();
}

class EntryCategories extends Table with SyncColumns {
  TextColumn get cashbookId => text()();
  TextColumn get categoryName => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class PaymentMethods extends Table with SyncColumns {
  TextColumn get cashbookId => text()();
  TextColumn get paymentMethodName => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'entries_book_date', columns: {#cashbookId, #entryDate})
class Entries extends Table with SyncColumns {
  TextColumn get cashbookId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get paymentMethodId => text().nullable()();
  TextColumn get entryType => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get title => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get entryDate => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get createdById => text().nullable()();
}

class CashbookMembers extends Table with SyncColumns {
  TextColumn get cashbookId => text()();
  TextColumn get memberId => text()();
  TextColumn get role => text()();
}

class Accounts extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get currency => text()();
  IntColumn get openingBalanceMinor => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class Categories extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get kind => text()();
}

@TableIndex(name: 'transactions_account_date', columns: {#accountId, #occurredOn})
class Transactions extends Table with SyncColumns {
  TextColumn get accountId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get kind => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get transferGroupId => text().nullable()();
  TextColumn get occurredOn => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
}

/// No month: the limit for every month. A month (yyyy-MM-01): that month only.
class Budgets extends Table with SyncColumns {
  TextColumn get categoryId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get month => text().nullable()();
}

/// Local changes waiting to be pushed, oldest first.
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get mutationId => text()();
  TextColumn get workspaceId => text()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get op => text()();
  TextColumn get rowId => text()();

  /// JSON object of the columns this change set
  TextColumn get data => text()();
}

/// How far each workspace has been pulled.
class SyncCursors extends Table {
  TextColumn get workspaceId => text()();
  IntColumn get since => integer()();

  @override
  Set<Column> get primaryKey => {workspaceId};
}

/// Changes the server refused, shown to the user as "not synced".
class SyncFailures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get code => text()();
  TextColumn get detail => text()();
  TextColumn get createdAt => text()();
}

/// Set once the individual-or-business question is answered for the signed-in account.
const onboardedSettingKey = 'onboarded';

/// The onboarding answer ('personal' or 'business') until the server has it.
const onboardingUnsentKey = 'onboarding_unsent';

/// Server address chosen in Settings (test builds only); unset means AppConfig.apiUrl.
const serverUrlSettingKey = 'server_url';

/// Small per-device settings: language, theme, selected workspace.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Workspaces, Cashbooks, EntryCategories, PaymentMethods, Entries, CashbookMembers,
  Accounts, Categories, Transactions, Budgets, Outbox, SyncCursors, SyncFailures, Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'casharoo'));

  // Every change: bump this, run `dart run drift_dev make-migrations`, add the
  // step below. The generated tests in test/drift/ check each step.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: stepByStep(
          from1To2: (m, schema) async {
            await m.addColumn(schema.budgets, schema.budgets.month);
          },
        ),
      );

  /// Synced tables in the order rows must be applied: parents before children.
  static const syncedTables = [
    'cashbooks', 'entry_categories', 'payment_methods', 'entries', 'cashbook_members',
    'accounts', 'categories', 'transactions', 'budgets',
  ];

  TableInfo<Table, dynamic> tableByName(String name) => allTables.firstWhere((t) => t.actualTableName == name);

  /// Signing out or switching account: nothing of the previous user stays on the device.
  Future<void> wipe() => transaction(() async {
        for (final table in allTables) {
          if (table.actualTableName != 'settings') await delete(table).go();
        }
      });

  Future<String?> getSetting(String key) async =>
      (await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await (delete(settings)..where((s) => s.key.equals(key))).go();
    } else {
      await into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
    }
  }
}

// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldWorkspacesData = <v1.WorkspacesData>[];
    final expectedNewWorkspacesData = <v2.WorkspacesData>[];

    final oldCashbooksData = <v1.CashbooksData>[];
    final expectedNewCashbooksData = <v2.CashbooksData>[];

    final oldEntryCategoriesData = <v1.EntryCategoriesData>[];
    final expectedNewEntryCategoriesData = <v2.EntryCategoriesData>[];

    final oldPaymentMethodsData = <v1.PaymentMethodsData>[];
    final expectedNewPaymentMethodsData = <v2.PaymentMethodsData>[];

    final oldEntriesData = <v1.EntriesData>[];
    final expectedNewEntriesData = <v2.EntriesData>[];

    final oldCashbookMembersData = <v1.CashbookMembersData>[];
    final expectedNewCashbookMembersData = <v2.CashbookMembersData>[];

    final oldAccountsData = <v1.AccountsData>[];
    final expectedNewAccountsData = <v2.AccountsData>[];

    final oldCategoriesData = <v1.CategoriesData>[];
    final expectedNewCategoriesData = <v2.CategoriesData>[];

    final oldTransactionsData = <v1.TransactionsData>[];
    final expectedNewTransactionsData = <v2.TransactionsData>[];

    final oldBudgetsData = <v1.BudgetsData>[];
    final expectedNewBudgetsData = <v2.BudgetsData>[];

    final oldOutboxData = <v1.OutboxData>[];
    final expectedNewOutboxData = <v2.OutboxData>[];

    final oldSyncCursorsData = <v1.SyncCursorsData>[];
    final expectedNewSyncCursorsData = <v2.SyncCursorsData>[];

    final oldSyncFailuresData = <v1.SyncFailuresData>[];
    final expectedNewSyncFailuresData = <v2.SyncFailuresData>[];

    final oldSettingsData = <v1.SettingsData>[];
    final expectedNewSettingsData = <v2.SettingsData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.workspaces, oldWorkspacesData);
        batch.insertAll(oldDb.cashbooks, oldCashbooksData);
        batch.insertAll(oldDb.entryCategories, oldEntryCategoriesData);
        batch.insertAll(oldDb.paymentMethods, oldPaymentMethodsData);
        batch.insertAll(oldDb.entries, oldEntriesData);
        batch.insertAll(oldDb.cashbookMembers, oldCashbookMembersData);
        batch.insertAll(oldDb.accounts, oldAccountsData);
        batch.insertAll(oldDb.categories, oldCategoriesData);
        batch.insertAll(oldDb.transactions, oldTransactionsData);
        batch.insertAll(oldDb.budgets, oldBudgetsData);
        batch.insertAll(oldDb.outbox, oldOutboxData);
        batch.insertAll(oldDb.syncCursors, oldSyncCursorsData);
        batch.insertAll(oldDb.syncFailures, oldSyncFailuresData);
        batch.insertAll(oldDb.settings, oldSettingsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewWorkspacesData,
          await newDb.select(newDb.workspaces).get(),
        );
        expect(
          expectedNewCashbooksData,
          await newDb.select(newDb.cashbooks).get(),
        );
        expect(
          expectedNewEntryCategoriesData,
          await newDb.select(newDb.entryCategories).get(),
        );
        expect(
          expectedNewPaymentMethodsData,
          await newDb.select(newDb.paymentMethods).get(),
        );
        expect(expectedNewEntriesData, await newDb.select(newDb.entries).get());
        expect(
          expectedNewCashbookMembersData,
          await newDb.select(newDb.cashbookMembers).get(),
        );
        expect(
          expectedNewAccountsData,
          await newDb.select(newDb.accounts).get(),
        );
        expect(
          expectedNewCategoriesData,
          await newDb.select(newDb.categories).get(),
        );
        expect(
          expectedNewTransactionsData,
          await newDb.select(newDb.transactions).get(),
        );
        expect(expectedNewBudgetsData, await newDb.select(newDb.budgets).get());
        expect(expectedNewOutboxData, await newDb.select(newDb.outbox).get());
        expect(
          expectedNewSyncCursorsData,
          await newDb.select(newDb.syncCursors).get(),
        );
        expect(
          expectedNewSyncFailuresData,
          await newDb.select(newDb.syncFailures).get(),
        );
        expect(
          expectedNewSettingsData,
          await newDb.select(newDb.settings).get(),
        );
      },
    );
  });

  // Version 3 adds the server's "default" marker to categories. Rows already
  // on the phone were pulled without it, so the pull starts over to fetch it.
  test('migration from v2 to v3 keeps categories and pulls them again', () async {
    const food = v2.CategoriesData(
      id: 'c1',
      workspaceId: 'w1',
      version: 3,
      serverSeq: 12,
      createdAt: '2026-10-01T00:00:00Z',
      updatedAt: '2026-10-02T00:00:00Z',
      name: 'Food',
      kind: 'expense',
    );
    const unsent = v2.OutboxData(
      seq: 1,
      mutationId: 'm1',
      workspaceId: 'w1',
      tableName_: 'categories',
      op: 'upsert',
      rowId: 'c1',
      data: '{"name":"Food"}',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.categories, food);
        batch.insert(oldDb.outbox, unsent);
        batch.insert(
          oldDb.syncCursors,
          const v2.SyncCursorsData(workspaceId: 'w1', since: 40),
        );
        batch.insert(
          oldDb.settings,
          const v2.SettingsData(key: 'locale', value: 'bn'),
        );
      },
      validateItems: (newDb) async {
        final category = await newDb.select(newDb.categories).getSingle();
        expect((category.id, category.name, category.kind, category.serverSeq), ('c1', 'Food', 'expense', 12));
        // Unknown until the server says otherwise, which counts it as the user's own
        expect(category.isDefault, isFalse);
        expect(await newDb.select(newDb.syncCursors).get(), isEmpty);
        // What was waiting to be sent, and the settings, are untouched
        expect((await newDb.select(newDb.outbox).getSingle()).mutationId, 'm1');
        expect((await newDb.select(newDb.settings).getSingle()).value, 'bn');
      },
    );
  });
}

import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../db/database.dart';
import '../db/local_store.dart';

/// The server no longer accepts the session token.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

class SyncException implements Exception {
  SyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pushes queued local changes, then pulls what changed on the server.
///
/// Push comes first so the pull never overwrites an edit that is still waiting
/// to be sent. The server is the authority: each push result carries the row as
/// the server now holds it, and a refused change is rolled back locally and
/// recorded in sync_failures.
class SyncEngine {
  SyncEngine(this.db, this.api, this.store);

  final AppDatabase db;
  final ApiClient api;
  final LocalStore store;

  static const _pushBatchSize = 100;

  Future<void> sync() async {
    await refreshWorkspaces();
    final workspaces = await db.select(db.workspaces).get();
    for (final workspace in workspaces) {
      await _push(workspace.id);
      await _pull(workspace.id);
    }
  }

  /// Workspaces come from the REST API; rows of a workspace the user has left are dropped.
  Future<void> refreshWorkspaces() async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1;; page++) {
      final response = _check(await api.get('/api/v1/workspaces/', query: {'page': '$page'}));
      rows.addAll((response.json['results'] as List).cast<Map<String, dynamic>>());
      if (response.json['next'] == null) break;
    }
    await db.transaction(() async {
      final ids = rows.map((r) => r['id'] as String).toSet();
      final known = await db.select(db.workspaces).get();
      for (final gone in known.where((w) => !ids.contains(w.id))) {
        await _purgeWorkspace(gone.id);
      }
      for (final row in rows) {
        await db.into(db.workspaces).insertOnConflictUpdate(WorkspacesCompanion.insert(
              id: row['id'] as String,
              name: row['name'] as String,
              kind: row['kind'] as String,
              defaultCurrency: row['default_currency'] as String,
              isDemo: Value(row['is_demo'] as bool? ?? false),
              role: row['role'] as String? ?? 'viewer',
            ));
      }
    });
  }

  Future<void> _push(String workspaceId) async {
    while (true) {
      final batch = await (db.select(db.outbox)
            ..where((o) => o.workspaceId.equals(workspaceId))
            ..orderBy([(o) => OrderingTerm.asc(o.seq)])
            ..limit(_pushBatchSize))
          .get();
      if (batch.isEmpty) return;

      final response = _check(await api.post('/api/v1/sync/push/', {
        'workspace': workspaceId,
        'mutations': [
          for (final item in batch)
            {
              'id': item.mutationId,
              'table': item.tableName_,
              'op': item.op,
              'row_id': item.rowId,
              'data': jsonDecode(item.data),
            },
        ],
      }));
      final results = {
        for (final result in (response.json['results'] as List).cast<Map<String, dynamic>>()) result['id']: result,
      };

      await db.transaction(() async {
        for (final item in batch) {
          final result = results[item.mutationId];
          if (result == null) throw SyncException('Server did not answer mutation ${item.mutationId}.');
          await (db.delete(db.outbox)..where((o) => o.seq.equals(item.seq))).go();

          final rejected = result['status'] != 'applied';
          if (rejected) {
            final error = (result['error'] as Map?) ?? const {};
            await db.into(db.syncFailures).insert(SyncFailuresCompanion.insert(
                  tableName_: item.tableName_,
                  rowId: item.rowId,
                  code: '${error['code'] ?? 'rejected'}',
                  detail: '${error['detail'] ?? ''}',
                  createdAt: nowIso(),
                ));
          }
          // A newer local edit of the same row is still queued: keep it on screen
          if (await _hasPending(item.rowId)) continue;
          final row = result['row'] as Map<String, dynamic>?;
          if (row != null) {
            await store.upsertRow(item.tableName_, row);
          } else if (rejected) {
            // The server never had this row: undo the local create
            await _hardDelete(item.tableName_, item.rowId);
          }
        }
      });
    }
  }

  Future<void> _pull(String workspaceId) async {
    var since = (await (db.select(db.syncCursors)..where((c) => c.workspaceId.equals(workspaceId))).getSingleOrNull())
            ?.since ??
        0;
    var restarted = false;
    while (true) {
      final response = _check(await api.get('/api/v1/sync/pull/', query: {'workspace': workspaceId, 'since': '$since'}));
      final body = response.json;
      final changes = (body['changes'] as Map).cast<String, dynamic>();
      final accessible = (body['accessible_cashbook_ids'] as List).cast<String>().toSet();
      final nextSince = body['next_since'] as int;
      final hasMore = body['has_more'] as bool;

      var restart = false;
      await db.transaction(() async {
        for (final table in AppDatabase.syncedTables) {
          for (final row in ((changes[table] as List?) ?? const []).cast<Map<String, dynamic>>()) {
            if (await _hasPending(row['id'] as String)) continue;
            await store.upsertRow(table, row);
          }
        }
        await db.into(db.syncCursors)
            .insertOnConflictUpdate(SyncCursorsCompanion.insert(workspaceId: workspaceId, since: nextSince));

        if (!hasMore) {
          final localBooks = await (db.select(db.cashbooks)
                ..where((b) => b.workspaceId.equals(workspaceId) & b.deletedAt.isNull()))
              .get();
          final localIds = localBooks.map((b) => b.id).toSet();
          // Access to a book was withdrawn: it leaves the device
          for (final book in localBooks.where((b) => !accessible.contains(b.id))) {
            if (await _hasPending(book.id)) continue; // created here, not pushed yet
            await _purgeCashbook(book.id);
          }
          // Access to a book was granted after the cursor passed its rows: start over once
          if (!restarted && accessible.difference(localIds).isNotEmpty && since > 0) {
            restart = true;
            await db.into(db.syncCursors)
                .insertOnConflictUpdate(SyncCursorsCompanion.insert(workspaceId: workspaceId, since: 0));
          }
        }
      });

      if (restart) {
        restarted = true;
        since = 0;
        continue;
      }
      since = nextSince;
      if (!hasMore) return;
    }
  }

  ApiResponse _check(ApiResponse response) {
    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 410) {
      throw const SessionExpiredException();
    }
    if (!response.ok) throw SyncException('Server error ${response.statusCode}.');
    return response;
  }

  Future<bool> _hasPending(String rowId) async =>
      await (db.select(db.outbox)..where((o) => o.rowId.equals(rowId))..limit(1)).getSingleOrNull() != null;

  Future<void> _hardDelete(String table, String id) => db.customUpdate(
        'DELETE FROM "$table" WHERE id = ?',
        variables: [Variable<String>(id)],
        updates: {db.tableByName(table)},
        updateKind: UpdateKind.delete,
      );

  Future<void> _purgeCashbook(String bookId) async {
    for (final table in const ['entries', 'entry_categories', 'payment_methods', 'cashbook_members']) {
      await db.customUpdate(
        'DELETE FROM "$table" WHERE cashbook_id = ?',
        variables: [Variable<String>(bookId)],
        updates: {db.tableByName(table)},
        updateKind: UpdateKind.delete,
      );
    }
    await _hardDelete('cashbooks', bookId);
  }

  Future<void> _purgeWorkspace(String workspaceId) async {
    for (final table in [...AppDatabase.syncedTables, 'outbox', 'sync_cursors']) {
      await db.customUpdate(
        'DELETE FROM "$table" WHERE workspace_id = ?',
        variables: [Variable<String>(workspaceId)],
        updates: {db.tableByName(table)},
        updateKind: UpdateKind.delete,
      );
    }
    await (db.delete(db.workspaces)..where((w) => w.id.equals(workspaceId))).go();
  }
}

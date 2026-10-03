import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

const _uuid = Uuid();

/// Time-ordered ids, so rows created offline sort and index well on the server.
String newId() => _uuid.v7();

String nowIso() => DateTime.now().toUtc().toIso8601String();

Variable _variable(Object? value) => switch (value) {
      null => const Variable<String>(null),
      bool b => Variable<int>(b ? 1 : 0),
      int i => Variable<int>(i),
      String s => Variable<String>(s),
      _ => Variable<String>(value.toString()),
    };

/// Every write the user makes goes through here: the row changes in the local
/// database and the same change is queued for the server, in one transaction.
/// Screens never wait for the network.
class LocalStore {
  LocalStore(this.db, {this.onChange});

  final AppDatabase db;

  /// Called after each write so sync can be scheduled.
  final void Function()? onChange;

  /// [data] holds the columns that are sent to the server. [localOnly] holds
  /// columns the server fills in itself (an entry's currency, for example) that
  /// the device needs before the first sync.
  Future<String> create(
    String table,
    String workspaceId,
    Map<String, Object?> data, {
    String? id,
    Map<String, Object?> localOnly = const {},
  }) async {
    final rowId = id ?? newId();
    final now = nowIso();
    await db.transaction(() async {
      await upsertRow(table, {
        'id': rowId,
        'workspace_id': workspaceId,
        'version': 0,
        'server_seq': 0,
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
        ...data,
        ...localOnly,
      });
      await _enqueue(workspaceId, table, 'upsert', rowId, data);
    });
    onChange?.call();
    return rowId;
  }

  /// [changes] should hold only the columns that changed: the server merges
  /// per column, so two people editing different fields both keep their edit.
  Future<void> update(String table, String id, Map<String, Object?> changes) async {
    if (changes.isEmpty) return;
    await db.transaction(() async {
      final workspaceId = await _workspaceOf(table, id);
      final assignments = [...changes.keys, 'updated_at'].map((c) => '"$c" = ?').join(', ');
      await db.customUpdate(
        'UPDATE "$table" SET $assignments WHERE id = ?',
        variables: [...changes.values.map(_variable), _variable(nowIso()), _variable(id)],
        updates: {db.tableByName(table)},
      );
      await _enqueue(workspaceId, table, 'upsert', id, changes);
    });
    onChange?.call();
  }

  /// Marks the row deleted. It stays as a tombstone so the deletion syncs.
  Future<void> remove(String table, String id) async {
    await db.transaction(() async {
      final workspaceId = await _workspaceOf(table, id);
      await db.customUpdate(
        'UPDATE "$table" SET deleted_at = ?, updated_at = ? WHERE id = ?',
        variables: [_variable(nowIso()), _variable(nowIso()), _variable(id)],
        updates: {db.tableByName(table)},
      );
      await _enqueue(workspaceId, table, 'delete', id, const {});
    });
    onChange?.call();
  }

  /// Writes a full row as given. Used for local creates and for rows arriving from the server.
  Future<void> upsertRow(String table, Map<String, Object?> row) async {
    final info = db.tableByName(table);
    final columns = info.$columns.map((c) => c.name).where(row.containsKey).toList();
    await db.customInsert(
      'INSERT OR REPLACE INTO "$table" (${columns.map((c) => '"$c"').join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')})',
      variables: [for (final column in columns) _variable(row[column])],
      updates: {info},
    );
  }

  Future<String> _workspaceOf(String table, String id) async {
    final row = await db.customSelect('SELECT workspace_id FROM "$table" WHERE id = ?', variables: [_variable(id)])
        .getSingle();
    return row.read<String>('workspace_id');
  }

  Future<void> _enqueue(String workspaceId, String table, String op, String rowId, Map<String, Object?> data) =>
      db.into(db.outbox).insert(OutboxCompanion.insert(
            mutationId: newId(),
            workspaceId: workspaceId,
            tableName_: table,
            op: op,
            rowId: rowId,
            data: jsonEncode(data),
          ));
}

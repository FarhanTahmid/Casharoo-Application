import 'dart:convert';

import 'package:spendroo/core/api/api_client.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/db/local_store.dart';
import 'package:spendroo/core/sync/sync_engine.dart';
import 'package:spendroo/features/cashbook/cashbook_repository.dart';
import 'package:spendroo/features/personal/ledger_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_support.dart';

const shopId = '00000000-0000-0000-0000-0000000000b1';
const bookId = '00000000-0000-0000-0000-0000000000b2';
const entryId = '00000000-0000-0000-0000-0000000000b3';

Map<String, dynamic> serverRow(String id, int seq, Map<String, dynamic> fields, {String? deletedAt}) => {
      'id': id,
      'workspace_id': shopId,
      'version': 1,
      'server_seq': seq,
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
      'deleted_at': deletedAt,
      ...fields,
    };

void main() {
  late AppDatabase db;
  late LocalStore store;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request request) respond;

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  SyncEngine engine() => SyncEngine(
        db,
        ApiClient(
          baseUrl: 'http://api.test',
          tokenStore: MemoryTokenStore()..token = 'token',
          httpClient: MockClient((request) {
            requests.add(request);
            return respond(request);
          }),
        ),
        store,
      );

  setUp(() {
    db = memoryDatabase();
    store = LocalStore(db);
    requests = [];
  });
  tearDown(() => db.close());

  Map<String, dynamic> workspaces(String kind) => {
        'next': null,
        'results': [
          {'id': shopId, 'name': 'Shop', 'kind': kind, 'default_currency': 'BDT', 'is_demo': false, 'role': 'owner'},
        ],
      };

  Map<String, dynamic> emptyPull() =>
      {'changes': <String, dynamic>{}, 'next_since': 0, 'has_more': false, 'accessible_cashbook_ids': <String>[]};

  test('the onboarding answer reaches the server once, and waits while the server is unwell', () async {
    await db.setSetting(onboardingUnsentKey, 'business');
    var meStatus = 500;
    respond = (request) async => switch (request.url.path) {
          '/api/v1/me/' => json({'onboarded_at': '2026-10-03T00:00:00Z'}, meStatus),
          '/api/v1/workspaces/' => json({'next': null, 'results': []}),
          _ => json({}, 404),
        };

    await engine().sync();
    expect(await db.getSetting(onboardingUnsentKey), 'business'); // kept for the next run

    meStatus = 200;
    await engine().sync();
    expect(await db.getSetting(onboardingUnsentKey), isNull);
    final patches = requests.where((r) => r.method == 'PATCH').toList();
    expect(patches.length, 2);
    expect(jsonDecode(patches.last.body)['primary_mode'], 'business');

    await engine().sync();
    expect(requests.where((r) => r.method == 'PATCH').length, 2); // not sent again
  });

  test('tombstones pulled for a deleted book hide its entries', () async {
    var deleted = false;
    respond = (request) async {
      if (request.url.path == '/api/v1/workspaces/') return json(workspaces('business'));
      if (request.url.path != '/api/v1/sync/pull/') return json({}, 404);
      final stamp = deleted ? '2026-10-02T00:00:00Z' : null;
      final since = int.parse(request.url.queryParameters['since']!);
      if (deleted && since >= 2) {
        return json({
          'changes': {
            'cashbooks': [serverRow(bookId, 3, {'book_name': 'Till', 'description': null, 'currency': 'BDT'}, deletedAt: stamp)],
            'entries': [
              serverRow(entryId, 4, {
                'cashbook_id': bookId, 'category_id': null, 'payment_method_id': null, 'entry_type': 'cash_in',
                'amount_minor': 500, 'title': 'Sale', 'remarks': null, 'entry_date': '2026-10-01', 'source': 'manual',
                'currency': 'BDT', 'created_by_id': null,
              }, deletedAt: stamp),
            ],
          },
          'next_since': 4,
          'has_more': false,
          'accessible_cashbook_ids': <String>[],
        });
      }
      return json({
        'changes': {
          'cashbooks': [serverRow(bookId, 1, {'book_name': 'Till', 'description': null, 'currency': 'BDT'})],
          'entries': [
            serverRow(entryId, 2, {
              'cashbook_id': bookId, 'category_id': null, 'payment_method_id': null, 'entry_type': 'cash_in',
              'amount_minor': 500, 'title': 'Sale', 'remarks': null, 'entry_date': '2026-10-01', 'source': 'manual',
              'currency': 'BDT', 'created_by_id': null,
            }),
          ],
        },
        'next_since': 2,
        'has_more': false,
        'accessible_cashbook_ids': [bookId],
      });
    };
    final books = CashbookRepository(db, store);

    await engine().sync();
    expect((await books.watchEntries(bookId).first).single.entry.title, 'Sale');

    deleted = true;
    await engine().sync();
    expect(await books.watchCashbooks(shopId).first, isEmpty);
    expect(await books.watchEntries(bookId).first, isEmpty);
  });

  test('a transfer leg the server refuses is undone and reported', () async {
    respond = (request) async {
      if (request.url.path == '/api/v1/workspaces/') return json(workspaces('personal'));
      if (request.url.path == '/api/v1/sync/pull/') return json(emptyPull());
      if (request.url.path == '/api/v1/sync/push/') {
        final mutations = (jsonDecode(request.body)['mutations'] as List).cast<Map<String, dynamic>>();
        return json({
          'results': [
            for (final m in mutations)
              m['table'] == 'transactions' && (m['data'] as Map)['amount_minor'] as int > 0
                  ? {'id': m['id'], 'status': 'rejected', 'row': null,
                     'error': {'code': 'invalid', 'detail': 'The legs of a transfer must move money in opposite directions.'}}
                  : {'id': m['id'], 'status': 'applied', 'row': null},
          ],
        });
      }
      return json({}, 404);
    };
    final ledger = LedgerRepository(db, store);
    final cash = await ledger.addAccount(shopId, name: 'Cash', kind: 'cash', currency: 'BDT');
    final bank = await ledger.addAccount(shopId, name: 'Bank', kind: 'bank', currency: 'BDT');
    final accounts = {for (final a in await ledger.watchAccounts(shopId).first) a.account.id: a.account};
    await ledger.addTransfer(accounts[cash]!, accounts[bank]!, amountMinor: 1000, occurredOn: '2026-10-01');

    await engine().sync();
    final left = await ledger.watchTransactions(shopId).first;
    expect(left.map((t) => t.transaction.amountMinor).toList(), [-1000]);
    final failure = (await db.select(db.syncFailures).get()).single;
    expect((failure.tableName_, failure.code), ('transactions', 'invalid'));
    expect(await db.select(db.outbox).get(), isEmpty);
  });
}

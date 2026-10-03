import 'dart:convert';

import 'package:casharoo/app.dart';
import 'package:casharoo/core/api/api_client.dart';
import 'package:casharoo/core/config.dart';
import 'package:casharoo/core/db/database.dart';
import 'package:casharoo/core/providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_support.dart';

const personalId = '00000000-0000-0000-0000-000000000001';
const cashAccountId = '00000000-0000-0000-0000-0000000000a1';

/// A small stand-in for the Casharoo API: enough for login, workspaces and sync.
class FakeServer {
  final pushed = <Map<String, dynamic>>[];
  var loggedIn = false;

  Map<String, dynamic> row(String id, Map<String, dynamic> fields) => {
        'id': id,
        'workspace_id': personalId,
        'version': 1,
        'server_seq': 1,
        'created_at': '2026-10-01T00:00:00Z',
        'updated_at': '2026-10-01T00:00:00Z',
        'deleted_at': null,
        ...fields,
      };

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    http.Response json(Object body, [int status = 200]) =>
        http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

    if (path.endsWith('/auth/login')) {
      final body = jsonDecode(request.body) as Map;
      if (body['password'] != 'correct-horse') {
        return json({'status': 400, 'errors': [{'message': 'The email address and/or password you specified are not correct.'}]}, 400);
      }
      loggedIn = true;
      return json({'status': 200, 'meta': {'is_authenticated': true, 'session_token': 'token-1'}});
    }
    if (request.headers['X-Session-Token'] != 'token-1') return json({'detail': 'no'}, 401);
    if (path == '/api/v1/workspaces/') {
      return json({
        'next': null,
        'results': [
          {'id': personalId, 'name': 'Personal', 'kind': 'personal', 'default_currency': 'BDT', 'is_demo': false, 'role': 'owner'},
        ],
      });
    }
    if (path == '/api/v1/sync/push/') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final mutations = (body['mutations'] as List).cast<Map<String, dynamic>>();
      pushed.addAll(mutations);
      return json({
        'results': [
          for (final m in mutations) {'id': m['id'], 'status': 'applied', 'row': null},
        ],
      });
    }
    if (path == '/api/v1/sync/pull/') {
      final first = request.url.queryParameters['since'] == '0';
      return json({
        'changes': {
          'accounts': first
              ? [row(cashAccountId, {'name': 'Cash', 'kind': 'cash', 'currency': 'BDT', 'opening_balance_minor': 50000, 'is_archived': false})]
              : [],
          'categories': first
              ? [row('00000000-0000-0000-0000-0000000000c1', {'name': 'Food', 'kind': 'expense'})]
              : [],
        },
        'next_since': 1,
        'has_more': false,
        'accessible_cashbook_ids': [],
      });
    }
    return json({'detail': 'not found'}, 404);
  }
}

void main() {
  testWidgets('log in, choose personal, record an expense, switch to Bangla', (tester) async {
    useHostSqlite();
    final server = FakeServer();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      apiClientProvider.overrideWith((ref) => ApiClient(
            baseUrl: AppConfig.apiUrl,
            tokenStore: ref.watch(tokenStoreProvider),
            httpClient: MockClient(server.handle),
          )),
    ]);
    addTearDown(container.dispose);

    // Drift and the HTTP mock do real async work; let it run between frames
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Database work started from the test runs in the fake-clock zone, so it
    // must be pumped to completion rather than awaited directly
    Future<T> untilDone<T>(Future<T> future) async {
      var done = false;
      late T result;
      future.then((value) {
        result = value;
        done = true;
      });
      for (var i = 0; i < 100 && !done; i++) {
        await settle();
      }
      expect(done, isTrue, reason: 'operation did not finish');
      return result;
    }

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const CasharooApp()));
    await settle();

    // --- signed out: the login screen
    expect(find.text('Log in'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle();
    expect(find.textContaining('not correct'), findsOneWidget);
    expect(server.loggedIn, isFalse);

    await tester.enterText(find.byType(TextFormField).at(1), 'correct-horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle();

    // --- first run: onboarding question
    expect(find.text('How will you use Casharoo?'), findsOneWidget);
    await tester.tap(find.text('For myself'));
    await settle();

    // --- personal overview, filled by the first sync
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('৳500.00'), findsOneWidget);

    // --- record an expense; it shows at once, before any network round trip
    await tester.tap(find.text('Add transaction'));
    await settle();
    await tester.enterText(find.byType(TextFormField).first, '120.50');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle();
    expect(find.text('৳379.50'), findsOneWidget);

    // ... and is queued, then pushed by the background sync
    await untilDone(container.read(syncControllerProvider.notifier).syncNow());
    final expense = server.pushed.singleWhere((m) => m['table'] == 'transactions');
    expect((expense['data'] as Map)['amount_minor'], -12050);
    expect((expense['data'] as Map)['account_id'], cashAccountId);
    expect(await untilDone(db.select(db.outbox).get()), isEmpty);

    // --- Bangla: labels, digits and lakh grouping change together
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle();
    await tester.tap(find.text('বাংলা'));
    await settle();
    await tester.tap(find.byType(BackButton)); // pageBack() looks for the English tooltip
    await settle();
    expect(find.text('মোট ব্যালেন্স'), findsOneWidget);
    expect(find.text('৳৩৭৯.৫০'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await untilDone(db.close());
  }, timeout: const Timeout(Duration(seconds: 90)));
}

import 'dart:convert';

import 'package:spendroo/app.dart';
import 'package:spendroo/core/api/api_client.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/providers.dart';
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
const shopId = '00000000-0000-0000-0000-000000000002';
const shopBookId = '00000000-0000-0000-0000-0000000000b1';

/// A small stand-in for the Spendroo API: enough for login, workspaces and sync.
class FakeServer {
  FakeServer({this.onboardedAt});

  final pushed = <Map<String, dynamic>>[];
  var loggedIn = false;

  /// What /api/v1/me/ reports; set when the account was onboarded on another phone.
  String? onboardedAt;
  String? primaryMode;
  var demoCreated = false;

  Map<String, dynamic> row(String id, Map<String, dynamic> fields, {String workspace = personalId}) => {
        'id': id,
        'workspace_id': workspace,
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
    if (path == '/api/v1/me/') {
      if (request.method == 'PATCH') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        onboardedAt = body['onboarded_at'] as String?;
        primaryMode = body['primary_mode'] as String?;
      }
      return json({'email': 'alice@example.com', 'onboarded_at': onboardedAt, 'primary_mode': primaryMode ?? ''});
    }
    const shop = {'id': shopId, 'name': 'Demo shop', 'kind': 'business', 'default_currency': 'BDT', 'is_demo': true, 'role': 'owner'};
    if (path == '/api/v1/workspaces/demo/') {
      demoCreated = true;
      return json(shop, 201);
    }
    if (path == '/api/v1/workspaces/') {
      return json({
        'next': null,
        'results': [
          {'id': personalId, 'name': 'Personal', 'kind': 'personal', 'default_currency': 'BDT', 'is_demo': false, 'role': 'owner'},
          if (demoCreated) shop,
        ],
      });
    }
    if (path == '/api/v1/sync/pull/' && request.url.queryParameters['workspace'] == shopId) {
      final first = request.url.queryParameters['since'] == '0';
      return json({
        'changes': {
          'cashbooks': first
              ? [row(shopBookId, {'book_name': 'Shop cash', 'description': null, 'currency': 'BDT'}, workspace: shopId)]
              : [],
          'entries': first
              ? [
                  row('00000000-0000-0000-0000-0000000000b2', {
                    'cashbook_id': shopBookId, 'category_id': null, 'payment_method_id': null, 'entry_type': 'cash_in',
                    'amount_minor': 1500000, 'title': 'Opening cash', 'remarks': null, 'entry_date': '2026-10-01',
                    'source': 'manual', 'currency': 'BDT', 'created_by_id': null,
                  }, workspace: shopId),
                ]
              : [],
        },
        'next_since': 2,
        'has_more': false,
        'accessible_cashbook_ids': [shopBookId],
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

/// The app wired to [server], with helpers to let real async work finish under the fake clock.
class Harness {
  Harness(this.tester, this.server) {
    useHostSqlite();
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      apiClientProvider.overrideWith((ref) => ApiClient(
            baseUrl: ref.watch(serverUrlProvider),
            tokenStore: ref.watch(tokenStoreProvider),
            httpClient: MockClient(server.handle),
          )),
    ]);
  }

  final WidgetTester tester;
  final FakeServer server;
  late final AppDatabase db;
  late final ProviderContainer container;

  // Drift and the HTTP mock do real async work; let it run between frames
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> start() async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SpendrooApp()));
    await settle();
  }

  Future<void> logIn() async {
    await tester.enterText(find.byType(TextFormField).at(0), 'alice@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'correct-horse');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle();
  }

  /// Work started from the test runs in the fake-clock zone: pump until it completes.
  Future<T> run<T>(Future<T> future) async {
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

  Future<void> stop() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    var closed = false;
    db.close().then((_) => closed = true);
    for (var i = 0; i < 100 && !closed; i++) {
      await settle();
    }
  }
}

void main() {
  testWidgets('an account onboarded on another phone skips the question', (tester) async {
    final app = Harness(tester, FakeServer(onboardedAt: '2026-10-01T00:00:00Z'));
    await app.start();
    await app.logIn();
    expect(find.text('How will you use Spendroo?'), findsNothing);
    expect(find.text('Total balance'), findsOneWidget);

    // A test build can be pointed at another server; that signs out and clears the phone
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await app.settle();
    await tester.scrollUntilVisible(find.text('Server'), 100);
    await tester.tap(find.text('Server'));
    await app.settle();
    await tester.enterText(find.byType(TextFormField), 'ftp://nope');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    expect(find.text('Enter an address starting with http:// or https://'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'https://tunnel.example/');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save')); // confirm
    await app.settle();
    expect(find.text('Log in'), findsWidgets);
    expect(app.container.read(serverUrlProvider), 'https://tunnel.example');
    expect(app.container.read(apiClientProvider).baseUrl, 'https://tunnel.example');
    expect(await app.run(app.db.getSetting(serverUrlSettingKey)), 'https://tunnel.example');
    expect(await app.run(app.db.select(app.db.accounts).get()), isEmpty);
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('choose the demo business and record cash in', (tester) async {
    final app = Harness(tester, FakeServer());
    await app.start();
    await app.logIn();

    await tester.tap(find.text('Try a demo business'));
    await app.settle();
    await app.settle();
    expect(find.text('Demo shop'), findsOneWidget); // the switcher opened the new business
    await tester.tap(find.text('Shop cash'));
    await app.settle();
    expect(find.text('৳15,000.00'), findsWidgets);
    expect(find.text('Opening cash'), findsOneWidget);

    await tester.tap(find.text('Cash in'));
    await app.settle();
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await app.settle();
    expect(find.text('৳15,500.00'), findsWidgets); // balance and total in

    await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
    expect(app.server.pushed.single['table'], 'entries');
    expect(app.server.primaryMode, 'business');
    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('log in, choose personal, record an expense, switch to Bangla', (tester) async {
    final server = FakeServer();
    final app = Harness(tester, server);
    final db = app.db;
    final container = app.container;
    Future<void> settle() => app.settle();
    Future<T> untilDone<T>(Future<T> future) => app.run(future);
    await app.start();

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
    expect(find.text('How will you use Spendroo?'), findsOneWidget);
    await tester.tap(find.text('For myself'));
    await settle();

    // --- personal overview, filled by the first sync
    expect(find.text('Total balance'), findsOneWidget);
    // The total, and the Cash account under "Account balances"
    expect(find.text('৳500.00'), findsNWidgets(2));

    // --- record an expense; it shows at once, before any network round trip
    await tester.tap(find.text('Add transaction'));
    await settle();
    await tester.enterText(find.byType(TextFormField).first, '120.50');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle();
    expect(find.text('৳379.50'), findsWidgets);
    expect(find.text('৳120.50'), findsWidgets); // this month's expense

    // ... and is queued, then pushed by the background sync
    await untilDone(container.read(syncControllerProvider.notifier).syncNow());
    final expense = server.pushed.singleWhere((m) => m['table'] == 'transactions');
    expect((expense['data'] as Map)['amount_minor'], -12050);
    expect((expense['data'] as Map)['account_id'], cashAccountId);
    expect(await untilDone(db.select(db.outbox).get()), isEmpty);
    // The onboarding answer went to the account, for the next phone
    expect(server.primaryMode, 'personal');

    // --- Bangla: labels, digits and lakh grouping change together
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle();
    await tester.tap(find.text('বাংলা'));
    await settle();
    await tester.tap(find.byType(BackButton)); // pageBack() looks for the English tooltip
    await settle();
    expect(find.text('মোট ব্যালেন্স'), findsOneWidget);
    expect(find.text('৳৩৭৯.৫০'), findsWidgets);

    await app.stop();
  }, timeout: const Timeout(Duration(seconds: 90)));
}

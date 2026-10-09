import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spendroo/core/api/api_client.dart';
import 'package:spendroo/core/db/database.dart';
import 'package:spendroo/core/db/local_store.dart';
import 'package:spendroo/core/entitlements/entitlements.dart';
import 'package:spendroo/core/entitlements/entitlements_controller.dart';
import 'package:spendroo/core/entitlements/plan_guard.dart';
import 'package:spendroo/core/providers.dart';
import 'package:spendroo/core/sync/sync_engine.dart';
import 'package:spendroo/features/cashbook/cashbook_repository.dart';
import 'package:spendroo/features/personal/ledger_repository.dart';
import 'package:spendroo/features/plan/keep_page.dart';
import 'package:spendroo/features/plan/upgrade_sheet.dart';
import 'package:spendroo/features/shell/home_shell.dart';

import 'app_flow_test.dart' show FakeServer, Harness, cashAccountId, personalId;
import 'test_support.dart';

const bankAccountId = '00000000-0000-0000-0000-0000000000a2';
const shopId = '00000000-0000-0000-0000-0000000000d1';

/// What the server answers for a plan, shaped like billing/payload.py.
Map<String, dynamic> planFeatures(String plan) => plan == 'free'
    ? {
        F.personalAccounts: {'kind': 'limit', 'limit': 4, 'unlimited': false},
        F.customCategories: {'kind': 'limit', 'limit': 10, 'unlimited': false},
        F.budgetMonthOverride: {'kind': 'flag', 'enabled': false},
        F.businessWorkspaces: {'kind': 'limit', 'limit': 1, 'unlimited': false},
        F.businessCashbooks: {'kind': 'limit', 'limit': 2, 'unlimited': false},
        F.aiCredits: {'kind': 'quota', 'limit': 15, 'unlimited': false, 'used': 5, 'bonus': 2, 'remaining': 12},
        F.ads: {'kind': 'flag', 'enabled': true},
      }
    : {
        F.personalAccounts: {'kind': 'limit', 'limit': null, 'unlimited': true},
        F.customCategories: {'kind': 'limit', 'limit': null, 'unlimited': true},
        F.budgetMonthOverride: {'kind': 'flag', 'enabled': true},
        F.businessWorkspaces: {'kind': 'limit', 'limit': 2, 'unlimited': false},
        F.businessCashbooks: {'kind': 'limit', 'limit': null, 'unlimited': true},
        F.aiCredits: {'kind': 'quota', 'limit': 300, 'unlimited': false, 'used': 5, 'bonus': 0, 'remaining': 295},
        F.ads: {'kind': 'flag', 'enabled': false},
      };

Map<String, dynamic> answer({
  String plan = 'free',
  String? expiresAt,
  List<Map<String, dynamic>> locks = const [],
  List<Map<String, dynamic>> offers = const [],
  Map<String, dynamic> features = const {},
}) =>
    {
      'version': '$plan-${locks.length}-${offers.length}-${jsonEncode(features).length}-${jsonEncode(locks).length}',
      'server_time': '2026-10-10T00:00:00+00:00',
      'plan': {
        'code': plan,
        'name': plan == 'free' ? 'Free' : 'Plus',
        'name_bn': plan == 'free' ? 'ফ্রি' : 'প্লাস',
        'tagline': '',
        'tagline_bn': '',
        'rank': plan == 'free' ? 0 : 10,
      },
      'source': plan == 'free' ? 'default' : 'promo_code',
      'expires_at': expiresAt,
      'in_grace': false,
      'offline_grace_days': 7,
      'warn_at_percent': 80,
      'features': {...planFeatures(plan), ...features},
      'locks': locks,
      'ads': {'enabled': plan == 'free', 'starts_at': null, 'placements': <String>[]},
      'offers': offers,
      // A newer server may say more than this version of the app knows
      'something_new': {'a': 1},
    };

Entitlements entitlements({String plan = 'free', String? expiresAt, List<Map<String, dynamic>> locks = const []}) =>
    Entitlements(answer(plan: plan, expiresAt: expiresAt, locks: locks), fetchedAt: DateTime.utc(2026, 10, 10));

/// The fake API with a billing side: a plan, a code that moves it, and a server that can refuse.
class BillingServer extends FakeServer {
  BillingServer() : super(onboardedAt: '2026-10-01T00:00:00Z');

  var plan = 'free';
  var stamp = '1.1';
  var locks = <Map<String, dynamic>>[];
  var offers = <Map<String, dynamic>>[];
  var features = <String, dynamic>{};

  /// Tables whose pushed changes the server refuses with "not on your plan".
  final refuses = <String>{};
  var refusesNewBusiness = false;

  var fetches = 0;
  final codes = <String>[];
  final events = <Map<String, dynamic>>[];
  final kept = <Map<String, dynamic>>[];
  final claimed = <String>[];

  Map<String, dynamic> get body => answer(plan: plan, locks: locks, offers: offers, features: features);

  @override
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    http.Response json(Object body, [int status = 200]) =>
        http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
    final signedIn = request.headers['X-Session-Token'] == 'token-1';
    Map<String, dynamic> sent() => (jsonDecode(request.body) as Map).cast<String, dynamic>();

    if (signedIn && path.startsWith('/api/v1/billing/')) {
      switch (path.substring('/api/v1/billing/'.length)) {
        case 'entitlements/':
          fetches++;
          return json(body);
        case 'plans/':
          return json({
            'features': [
              for (final key in planFeatures('free').keys) {'key': key, 'kind': 'limit', 'name': key, 'unit': ''},
            ],
            'plans': [
              for (final code in const ['free', 'plus'])
                {...(answer(plan: code)['plan'] as Map), 'features': planFeatures(code)},
            ],
          });
        case 'promo/redeem/':
          final code = sent()['code'] as String;
          codes.add(code);
          if (code != 'WELCOME') return json({'code': ['This code is not valid.']}, 400);
          plan = 'plus';
          return json(body);
        case 'dev/simulate/':
          plan = sent()['action'] == 'purchase' ? sent()['plan'] as String : 'free';
          return json(body);
        case 'events/':
          events.add(sent());
          return http.Response('', 204);
        case 'keep/':
          return json([
            for (final lock in locks)
              {
                ...lock,
                'noun': 'account',
                'workspace_name': 'Personal',
                'items': [
                  {'id': cashAccountId, 'label': 'Cash', 'kept': (lock['kept'] as List).contains(cashAccountId)},
                  {'id': bankAccountId, 'label': 'Bank', 'kept': (lock['kept'] as List).contains(bankAccountId)},
                ],
              },
          ]);
        case 'keep/${F.personalAccounts}/':
          kept.add(sent());
          final ids = (sent()['ids'] as List).cast<String>();
          locks = [
            lock(kept: ids, locked: [cashAccountId, bankAccountId].where((id) => !ids.contains(id)).toList())
              ..['pending'] = false
              ..['can_change_at'] = '2026-11-09T00:00:00+00:00',
          ];
          return json(body);
      }
      if (path.endsWith('/claim/')) {
        final slug = path.split('/')[5];
        claimed.add(slug);
        offers = [
          for (final offer in offers) {...offer, if (offer['slug'] == slug) 'claimed': true, 'claimable': false},
        ];
        plan = 'plus';
        return json(body);
      }
    }
    if (signedIn && path == '/api/v1/workspaces/' && request.method == 'POST') {
      if (refusesNewBusiness) {
        return json({
          'code': 'plan_limit', 'detail': 'Business workspaces: the Free plan allows 1.',
          'feature': F.businessWorkspaces, 'reason': 'limit', 'limit': 1, 'current': 1, 'plan': 'free', 'upgrade_to': 'plus',
        }, 402);
      }
      return json({'id': shopId, 'name': sent()['name'], 'kind': 'business', 'default_currency': 'BDT', 'is_demo': false, 'role': 'owner'}, 201);
    }
    if (signedIn && path == '/api/v1/sync/push/' && refuses.isNotEmpty) {
      final mutations = (sent()['mutations'] as List).cast<Map<String, dynamic>>();
      pushed.addAll(mutations);
      return json({
        'results': [
          for (final m in mutations)
            refuses.contains(m['table'])
                ? {
                    'id': m['id'], 'status': 'rejected', 'row': null,
                    'error': {
                      'code': 'plan_limit', 'detail': 'Personal accounts: the Free plan allows 4.',
                      'meta': {'feature': F.personalAccounts, 'reason': 'limit', 'limit': 4, 'current': 4, 'plan': 'free', 'upgrade_to': 'plus'},
                    },
                  }
                : {'id': m['id'], 'status': 'applied', 'row': null},
        ],
      });
    }
    final response = await super.handle(request);
    if (path == '/api/v1/sync/pull/' && response.statusCode == 200) {
      return json({...(jsonDecode(response.body) as Map), 'billing_stamp': stamp});
    }
    return response;
  }
}

Map<String, dynamic> lock({required List<String> kept, required List<String> locked}) => {
      'feature': F.personalAccounts, 'scope': personalId, 'limit': 1,
      'kept': kept, 'locked': locked, 'pending': true, 'can_change_at': null,
    };

/// Signed in on a phone-sized screen.
Future<Harness> openApp(WidgetTester tester, BillingServer server) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final app = Harness(tester, server);
  await app.start();
  await app.logIn();
  return app;
}

Future<void> addAccounts(Harness app, int count) async {
  for (var i = 0; i < count; i++) {
    await app.run(app.container
        .read(ledgerRepositoryProvider)
        .addAccount(personalId, name: 'Extra $i', kind: 'bank', currency: 'BDT'));
  }
}

void main() {
  group('Entitlements', () {
    test('reads the answer, ignores what it does not know, and survives being stored', () {
      final plan = entitlements();
      expect((plan.plan.code, plan.plan.nameIn('en'), plan.plan.nameIn('bn'), plan.isDefaultPlan), ('free', 'Free', 'ফ্রি', true));
      expect(plan.limitOf(F.personalAccounts), 4);
      expect(plan.can(F.budgetMonthOverride), isFalse);
      expect(plan[F.aiCredits]!.remaining, 12);
      // A feature the server did not mention: no extras, and limits are left to the server
      expect(plan.can('something.unheard_of'), isFalse);
      expect(plan.limitOf('something.unheard_of'), isNull);

      final stored = Entitlements.decode(plan.encode())!;
      expect((stored.version, stored.limitOf(F.personalAccounts), stored.fetchedAt), (plan.version, 4, plan.fetchedAt));
      expect(stored.json['something_new'], {'a': 1});
      expect(Entitlements.decode('not json'), isNull);
      expect(Entitlements.decode('{"entitlements": 3}'), isNull);
    });

    test('a paid plan gives unlimited, and its switches', () {
      final plan = entitlements(plan: 'plus');
      expect(plan.limitOf(F.personalAccounts), isNull);
      expect(plan[F.personalAccounts]!.unlimited, isTrue);
      expect(plan.can(F.budgetMonthOverride), isTrue);
    });

    test('extras go off when the plan ended longer ago than the offline grace', () {
      final plan = entitlements(plan: 'plus', expiresAt: '2026-10-20T00:00:00+00:00');
      expect(plan.can(F.budgetMonthOverride, now: DateTime.utc(2026, 10, 19)), isTrue);
      // Ended, but the phone may simply not have heard of the renewal yet
      expect(plan.can(F.budgetMonthOverride, now: DateTime.utc(2026, 10, 26)), isTrue);
      expect(plan.isStale(DateTime.utc(2026, 10, 28)), isTrue);
      expect(plan.can(F.budgetMonthOverride, now: DateTime.utc(2026, 10, 28)), isFalse);
    });

    test('knows what a downgrade locked', () {
      final plan = entitlements(locks: [lock(kept: [cashAccountId], locked: [bankAccountId])]);
      expect((plan.isLocked(bankAccountId), plan.isLocked(cashAccountId), plan.hasPendingChoice), (true, false, true));
      expect(plan.lockFor(F.personalAccounts, personalId)!.limit, 1);
      expect(plan.lockFor(F.personalAccounts), isNull);
    });

    test('a refusal from the server is read from either place it arrives in', () {
      final refusal = PlanLimitException.fromJson(
          {'feature': F.personalAccounts, 'reason': 'limit', 'limit': 4, 'current': 4, 'upgrade_to': 'plus'});
      expect((refusal.feature, refusal.reason, refusal.limit, refusal.upgradeTo), (F.personalAccounts, 'limit', 4, 'plus'));
      expect(PlanLimitException.fromJson(const {}).reason, PlanLimitException.reasonLimit);
    });

    test('which plan gives more of a feature', () {
      final free = planFeatures('free').map((key, value) => MapEntry(key, FeatureValue.fromJson(value as Map<String, dynamic>)));
      final plus = planFeatures('plus').map((key, value) => MapEntry(key, FeatureValue.fromJson(value as Map<String, dynamic>)));
      for (final feature in free.keys) {
        expect(givesMore(feature, free[feature], plus[feature]!), isTrue, reason: feature);
        expect(givesMore(feature, plus[feature], free[feature]!), isFalse, reason: feature);
        expect(givesMore(feature, plus[feature], plus[feature]!), isFalse, reason: feature);
      }
    });
  });

  group('PlanGuard and the repositories', () {
    late AppDatabase db;
    late LocalStore store;
    late Entitlements? plan;
    late LedgerRepository ledger;
    late CashbookRepository cashbooks;
    late PlanGuard guard;

    Future<void> workspace(String id, {String kind = 'personal', String role = 'owner', bool demo = false}) =>
        db.into(db.workspaces).insert(
            Workspace(id: id, name: id, kind: kind, defaultCurrency: 'BDT', isDemo: demo, role: role));

    Future<int> queued() async => (await db.select(db.outbox).get()).length;

    Matcher refused(String feature, [String reason = PlanLimitException.reasonLimit]) => throwsA(
        isA<PlanLimitException>().having((e) => e.feature, 'feature', feature).having((e) => e.reason, 'reason', reason));

    setUp(() async {
      db = memoryDatabase();
      store = LocalStore(db);
      plan = entitlements();
      guard = PlanGuard(db, () => plan);
      ledger = LedgerRepository(db, store, guard);
      cashbooks = CashbookRepository(db, store, guard);
      await workspace(personalId);
    });
    tearDown(() => db.close());

    Future<List<String>> accounts(int count) async => [
          for (var i = 0; i < count; i++)
            await ledger.addAccount(personalId, name: 'Account $i', kind: 'cash', currency: 'BDT'),
        ];

    test('a fifth account is refused before anything is written', () async {
      await accounts(4);
      final before = await queued();
      await expectLater(
        ledger.addAccount(personalId, name: 'Fifth', kind: 'cash', currency: 'BDT'),
        throwsA(isA<PlanLimitException>()
            .having((e) => e.feature, 'feature', F.personalAccounts)
            .having((e) => (e.limit, e.current), 'numbers', (4, 4))),
      );
      expect(await queued(), before);
      expect((await ledger.watchAccounts(personalId).first).length, 4);
    });

    test('archived accounts do not count, and bringing one back needs room', () async {
      final ids = await accounts(4);
      final first = (await ledger.watchAccounts(personalId).first).firstWhere((a) => a.account.id == ids.first).account;
      await ledger.updateAccount(first, name: first.name, kind: first.kind, openingBalanceMinor: 0, isArchived: true);
      await ledger.addAccount(personalId, name: 'In its place', kind: 'cash', currency: 'BDT');

      final archived = (await ledger.watchAccounts(personalId).first).firstWhere((a) => a.account.id == ids.first).account;
      expect(archived.isArchived, isTrue);
      await expectLater(
        ledger.updateAccount(archived, name: archived.name, kind: archived.kind, openingBalanceMinor: 0, isArchived: false),
        refused(F.personalAccounts),
      );
    });

    test('only categories the user added count', () async {
      for (var i = 0; i < 12; i++) {
        await store.upsertRow('categories', {
          'id': 'default-$i', 'workspace_id': personalId, 'created_at': 'x', 'updated_at': 'x',
          'name': 'Default $i', 'kind': 'expense', 'is_default': true,
        });
      }
      expect(await guard.count(F.customCategories, personalId), 0);
      for (var i = 0; i < 10; i++) {
        await ledger.addCategory(personalId, 'Mine $i', 'expense');
      }
      await expectLater(ledger.addCategory(personalId, 'One more', 'expense'), refused(F.customCategories));
      // Deleting one makes room again
      final mine = (await ledger.watchCategories(personalId).first).firstWhere((c) => !c.isDefault);
      await ledger.deleteCategory(mine);
      await ledger.addCategory(personalId, 'One more', 'expense');
    });

    test('a budget for one month is a paid feature; the every-month budget is not', () async {
      final food = await ledger.addCategory(personalId, 'Food', 'expense');
      await ledger.setBudget(personalId, food, 100000, 'BDT');
      await expectLater(
        ledger.setBudget(personalId, food, 150000, 'BDT', month: '2026-10-01'),
        refused(F.budgetMonthOverride, PlanLimitException.reasonFeature),
      );
      plan = entitlements(plan: 'plus');
      await ledger.setBudget(personalId, food, 150000, 'BDT', month: '2026-10-01');
    });

    test('cashbooks are limited per business, businesses per account, the demo aside', () async {
      await workspace('shop', kind: 'business');
      await workspace('demo', kind: 'business', demo: true);
      await cashbooks.createCashbook('shop', 'Till', 'BDT');
      await cashbooks.createCashbook('shop', 'Bank', 'BDT');
      await expectLater(cashbooks.createCashbook('shop', 'Third', 'BDT'), refused(F.businessCashbooks));
      // Each business has its own allowance
      await cashbooks.createCashbook('demo', 'Sample', 'BDT');

      expect(await guard.count(F.businessWorkspaces, ''), 1);
      await expectLater(guard.roomFor(F.businessWorkspaces, ''), refused(F.businessWorkspaces));
      plan = entitlements(plan: 'plus');
      await guard.roomFor(F.businessWorkspaces, '');
    });

    test("in someone else's business their plan decides, so nothing is checked here", () async {
      await workspace('theirs', kind: 'business', role: 'admin');
      for (var i = 0; i < 5; i++) {
        await cashbooks.createCashbook('theirs', 'Book $i', 'BDT');
      }
    });

    test('a locked account is read-only, its transactions too, but it can still be archived', () async {
      final ids = await accounts(2);
      plan = entitlements(locks: [lock(kept: [ids[0]], locked: [ids[1]])]);
      final all = await ledger.watchAccounts(personalId).first;
      final kept = all.firstWhere((a) => a.account.id == ids[0]).account;
      final locked = all.firstWhere((a) => a.account.id == ids[1]).account;
      const reason = PlanLimitException.reasonLocked;

      await ledger.addTransaction(kept, kind: 'expense', amountMinor: 100, occurredOn: '2026-10-01');
      await expectLater(
        () => ledger.addTransaction(locked, kind: 'expense', amountMinor: 100, occurredOn: '2026-10-01'),
        refused(F.personalAccounts, reason),
      );
      await expectLater(
        () => ledger.addTransfer(kept, locked, amountMinor: 100, occurredOn: '2026-10-01'),
        refused(F.personalAccounts, reason),
      );
      await expectLater(
        ledger.updateAccount(locked, name: 'Renamed', kind: locked.kind, openingBalanceMinor: 0, isArchived: false),
        refused(F.personalAccounts, reason),
      );
      await ledger.updateAccount(locked, name: locked.name, kind: locked.kind, openingBalanceMinor: 0, isArchived: true);
    });

    test('before the first answer from the server nothing is refused here', () async {
      plan = null;
      await accounts(6);
    });

    test('while the server refuses nothing, neither does the app', () async {
      plan = Entitlements({...answer(), 'enforced': false}, fetchedAt: DateTime.utc(2026, 10, 10));
      expect(plan!.limitOf(F.personalAccounts), 4); // still shown
      await accounts(6);
      final food = await ledger.addCategory(personalId, 'Food', 'expense');
      await ledger.setBudget(personalId, food, 150000, 'BDT', month: '2026-10-01');
    });
  });

  group('sync', () {
    late AppDatabase db;
    late LocalStore store;

    http.Response json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

    setUp(() {
      db = memoryDatabase();
      store = LocalStore(db);
    });
    tearDown(() => db.close());

    test('a change the plan does not allow is undone and reported, not listed as a failure', () async {
      final stamps = <String>[];
      final refusals = <Map<String, dynamic>>[];
      final engine = SyncEngine(
        db,
        ApiClient(
          baseUrl: 'http://api.test',
          tokenStore: MemoryTokenStore()..token = 'token',
          httpClient: MockClient((request) async {
            final path = request.url.path;
            if (path == '/api/v1/workspaces/') {
              return json({
                'next': null,
                'results': [
                  {'id': personalId, 'name': 'Personal', 'kind': 'personal', 'default_currency': 'BDT', 'is_demo': false, 'role': 'owner'},
                ],
              });
            }
            if (path == '/api/v1/sync/push/') {
              final mutations = ((jsonDecode(request.body) as Map)['mutations'] as List).cast<Map<String, dynamic>>();
              return json({
                'results': [
                  for (final m in mutations)
                    {
                      'id': m['id'], 'status': 'rejected', 'row': null,
                      'error': {
                        'code': 'plan_limit', 'detail': 'no',
                        'meta': {'feature': F.personalAccounts, 'reason': 'limit', 'limit': 4, 'current': 4},
                      },
                    },
                ],
              });
            }
            return json({
              'changes': <String, dynamic>{}, 'next_since': 0, 'has_more': false,
              'accessible_cashbook_ids': <String>[], 'billing_stamp': '7.2',
            });
          }),
        ),
        store,
        onBillingStamp: stamps.add,
        onPlanLimit: refusals.add,
      );
      await db.into(db.workspaces).insert(const Workspace(
          id: personalId, name: 'Personal', kind: 'personal', defaultCurrency: 'BDT', isDemo: false, role: 'owner'));
      final id = await LedgerRepository(db, store).addAccount(personalId, name: 'Fifth', kind: 'cash', currency: 'BDT');

      await engine.sync();

      expect(refusals.single['feature'], F.personalAccounts);
      expect(stamps, ['7.2']);
      expect(await db.select(db.syncFailures).get(), isEmpty);
      expect(await db.select(db.outbox).get(), isEmpty);
      final left = await db.customSelect('SELECT id FROM accounts WHERE id = ?', variables: [Variable<String>(id)]).get();
      expect(left, isEmpty); // the server never had it
    });
  });

  group('in the app', () {
    testWidgets('the Plan screen shows the plan and what is in use', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      await addAccounts(app, 2);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await app.settle();
      expect(find.text('Free'), findsOneWidget);
      await tester.tap(find.text('Plan'));
      await app.settle();

      expect(find.text('Your plan'), findsOneWidget);
      expect(find.text('3 of 4'), findsOneWidget); // accounts
      expect(find.text('1 of 10'), findsOneWidget); // the one category of their own
      expect(find.text('0 of 1'), findsOneWidget); // businesses
      // Nothing about features this version of the app does not have
      expect(find.textContaining('AI'), findsNothing);
      await app.stop();
    });

    testWidgets('a fifth account opens the upgrade sheet and nothing is queued', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      await addAccounts(app, 3);
      await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
      final sent = server.pushed.length;

      await tester.tap(find.text('Accounts'));
      await app.settle();
      await tester.scrollUntilVisible(find.text('Add account'), 200);
      // At the limit, the screen says so before the wall
      expect(find.text('Accounts: 4 of 4'), findsOneWidget);
      await tester.tap(find.text('Add account'));
      await app.settle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Account name'), 'One too many');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await app.settle();

      expect(find.text('Your Free plan allows 4 accounts.'), findsOneWidget);
      expect(find.text('Plus'), findsOneWidget);
      expect(find.text('Everything in Free, and:'), findsOneWidget);
      expect(find.text('Unlimited'), findsWidgets);
      expect(find.text('A different budget for one month'), findsOneWidget);
      expect(server.events.first, {'kind': 'paywall_view', 'feature': F.personalAccounts});
      expect(server.pushed.length, sent);
      expect((await app.run(app.db.select(app.db.accounts).get())).length, 4);
      await app.stop();
    });

    testWidgets('a code moves the user to Plus and the limit is gone', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await app.settle();
      await tester.tap(find.text('Plan'));
      await app.settle();

      await tester.tap(find.text('Redeem a code'));
      await app.settle();
      await tester.enterText(find.byType(TextField), 'NOPE');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await app.settle();
      expect(find.text('This code is not valid.'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);

      await tester.tap(find.text('Redeem a code'));
      await app.settle();
      await tester.enterText(find.byType(TextField), 'WELCOME');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await app.settle();
      expect(find.text('Code applied. You are on the Plus plan.'), findsOneWidget);
      expect(find.text('Plus'), findsOneWidget);
      expect(server.codes, ['NOPE', 'WELCOME']);

      await addAccounts(app, 6);
      await app.stop();
    });

    testWidgets('a wrong code on the upgrade sheet is answered on the sheet, not under it', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await app.settle();
      await tester.tap(find.text('Plan'));
      await app.settle();
      await tester.tap(find.text('See plans'));
      await app.settle();

      await tester.tap(find.text('Redeem a code').last); // the sheet's own button
      await app.settle();
      await tester.enterText(find.byType(TextField), 'NOPE');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await app.settle();

      expect(find.text('Get more from Spendroo'), findsOneWidget); // still open
      expect(find.text('This code is not valid.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await app.stop();
    });

    testWidgets('a change in the admin reaches the app with the next sync', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      expect(app.container.read(entitlementsProvider).value!.limitOf(F.personalAccounts), 4);
      final fetches = server.fetches;

      // Nothing changed: syncing again does not ask again
      await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
      expect(server.fetches, fetches);

      server.features = {
        F.personalAccounts: {'kind': 'limit', 'limit': 6, 'unlimited': false},
      };
      server.stamp = '2.1';
      await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
      await app.settle();
      expect(server.fetches, fetches + 1);
      expect(app.container.read(entitlementsProvider).value!.limitOf(F.personalAccounts), 6);
      await addAccounts(app, 5);
      await app.stop();
    });

    testWidgets('the server refusing a synced change says why once and lists no failure', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      // The phone thinks there is room; the server knows better
      server.refuses.add('accounts');
      await addAccounts(app, 2);
      await app.run(app.container.read(syncControllerProvider.notifier).syncNow());
      await app.settle();

      // Two changes were refused; one sheet says so
      expect(find.text('Your Free plan allows 4 accounts.'), findsOneWidget);
      expect(await app.run(app.db.select(app.db.syncFailures).get()), isEmpty);
      expect((await app.run(app.db.select(app.db.accounts).get())).length, 1); // both undone
      await tester.tapAt(const Offset(10, 10)); // close the sheet
      await app.settle();
      expect(find.text('Your Free plan allows 4 accounts.'), findsNothing);
      expect(app.container.read(planLimitNoticeProvider), isNull);
      await app.stop();
    });

    testWidgets('a business the plan has no room for: the server says so and the sheet opens', (tester) async {
      final server = BillingServer()..refusesNewBusiness = true;
      final app = await openApp(tester, server);
      Object? error;
      await app.run(app.container
          .read(workspaceActionsProvider)
          .createBusiness('Second shop')
          .then<void>((_) {}, onError: (Object e) => error = e));
      expect(error, isA<PlanLimitException>().having((e) => e.upgradeTo, 'upgrade to', 'plus'));
      await app.stop();
    });

    testWidgets('after a downgrade the user chooses what to keep', (tester) async {
      final server = BillingServer()..locks = [lock(kept: [cashAccountId], locked: [bankAccountId])];
      final app = await openApp(tester, server);

      // Opens by itself the first time
      expect(find.byType(KeepPage), findsOneWidget);
      expect(find.text('Accounts in Personal'), findsOneWidget);
      expect(find.text('1 of 1 chosen'), findsOneWidget);
      CheckboxListTile tile(String label) => tester.widget(find.widgetWithText(CheckboxListTile, label));
      expect((tile('Cash').value, tile('Bank').value), (true, false));
      // One is allowed: the other cannot be ticked until this one is let go
      expect(tile('Bank').onChanged, isNull);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Cash'));
      await app.settle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Bank'));
      await app.settle();
      await tester.tap(find.widgetWithText(FilledButton, 'Keep these'));
      await app.settle();

      expect(server.kept.single, {'scope': personalId, 'ids': [bankAccountId]});
      expect(find.text('Saved. The others are read-only.'), findsOneWidget);
      expect(find.text('You can change this again from Nov 9, 2026.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Keep these'), findsNothing);

      // The one let go is marked on its row, and refuses an edit
      await tester.pageBack();
      await app.settle();
      await tester.tap(find.text('Accounts'));
      await app.settle();
      expect(find.text('Locked'), findsOneWidget);
      final cash = (await app.run(app.db.select(app.db.accounts).get())).single;
      Object? error;
      await app.run(app.container
          .read(ledgerRepositoryProvider)
          .addTransaction(cash, kind: 'expense', amountMinor: 100, occurredOn: '2026-10-02')
          .then<void>((_) {}, onError: (Object e) => error = e));
      expect(error, isA<PlanLimitException>().having((e) => e.reason, 'reason', PlanLimitException.reasonLocked));
      await app.stop();
    });

    testWidgets('an offer shows on the home screen and is taken with one tap', (tester) async {
      final server = BillingServer()
        ..offers = [
          {
            'slug': 'eid', 'title': 'Eid gift: Plus for a week', 'title_bn': '', 'body': '', 'body_bn': '',
            'cta': '', 'cta_bn': '', 'placements': ['home_banner', 'plan_screen'], 'ends_at': '2099-01-01T00:00:00+00:00',
            'benefit': {'kind': 'plan', 'plan': 'plus', 'days': 7}, 'applied': false, 'claimed': false, 'claimable': true,
          },
        ];
      final app = await openApp(tester, server);
      expect(find.text('Eid gift: Plus for a week'), findsOneWidget);
      expect(find.textContaining('Get it'), findsOneWidget);

      await tester.tap(find.text('Eid gift: Plus for a week'));
      await app.settle();
      expect(server.claimed, ['eid']);
      expect(find.text('It is yours now. Enjoy!'), findsOneWidget);
      expect(find.text('Eid gift: Plus for a week'), findsNothing);
      expect(app.container.read(entitlementsProvider).value!.plan.code, 'plus');
      await app.stop();
    });

    testWidgets('logging out forgets the plan', (tester) async {
      final server = BillingServer();
      final app = await openApp(tester, server);
      expect(await app.run(app.db.getSetting(entitlementsSettingKey)), isNotNull);
      expect(await app.run(app.db.getSetting(billingStampSettingKey)), '1.1');

      await app.run(app.container.read(authControllerProvider.notifier).logOut());
      await app.settle();
      expect(await app.run(app.db.getSetting(entitlementsSettingKey)), isNull);
      expect(await app.run(app.db.getSetting(billingStampSettingKey)), isNull);
      expect(app.container.read(entitlementsProvider).value, isNull);
      await app.stop();
    });
  });
}

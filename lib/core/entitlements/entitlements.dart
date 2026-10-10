import 'dart:convert';

/// Names of the things a plan can limit, as the server spells them
/// (billing/catalog/keys.py in the API).
abstract final class F {
  static const personalAccounts = 'personal.accounts';
  static const customCategories = 'personal.custom_categories';
  static const budgetMonthOverride = 'budgets.month_override';
  static const insightsCustomRange = 'insights.custom_range';
  static const insightsYearReview = 'insights.year_review';
  static const insightsTrendMonths = 'insights.trend_months';
  static const recurringTransactions = 'recurring.transactions';
  static const savingsGoals = 'goals.savings';
  static const homeWidget = 'widget.home';
  static const businessWorkspaces = 'business.workspaces';
  static const businessCashbooks = 'business.cashbooks';
  static const teamSeats = 'team.seats';
  static const reportRange = 'cashbook.report_range';
  static const reportExport = 'cashbook.report_export';
  static const auditTrail = 'history.audit_trail';
  static const customFields = 'entries.custom_fields';
  static const storageMb = 'storage.attachments_mb';
  static const aiCredits = 'ai.credits';
  static const pdfPages = 'statements.pdf_pages';
  static const devicesMax = 'devices.max';
  static const ads = 'ads.enabled';
}

DateTime? _time(Object? value) => value is String ? DateTime.tryParse(value) : null;

List<String> _strings(Object? value) => value is List ? [for (final item in value) '$item'] : const [];

/// What a plan gives for one feature.
class FeatureValue {
  const FeatureValue({
    required this.kind,
    this.enabled = false,
    this.limit,
    this.unlimited = false,
    this.used = 0,
    this.bonus = 0,
    this.resetsAt,
  });

  factory FeatureValue.fromJson(Map<String, dynamic> json) => FeatureValue(
        kind: json['kind'] as String? ?? 'flag',
        enabled: json['enabled'] as bool? ?? false,
        limit: (json['limit'] as num?)?.toInt(),
        unlimited: json['unlimited'] as bool? ?? false,
        used: (json['used'] as num?)?.toInt() ?? 0,
        bonus: (json['bonus'] as num?)?.toInt() ?? 0,
        resetsAt: _time(json['resets_at']),
      );

  /// 'flag' (on or off), 'limit' (how many at one time) or 'quota' (how much a month).
  final String kind;
  final bool enabled;

  /// Null with [unlimited].
  final int? limit;
  final bool unlimited;

  /// For a quota: used this month, and extra given on top of the plan.
  final int used;
  final int bonus;
  final DateTime? resetsAt;

  bool get isFlag => kind == 'flag';

  /// What is left of a quota this month. Null when unlimited.
  int? get remaining => unlimited || limit == null ? null : (limit! + bonus - used).clamp(0, 1 << 31);

  /// Whether the plan gives any of it at all.
  bool get included => isFlag ? enabled : (unlimited || (limit ?? 0) > 0);
}

/// After a downgrade the user holds more than the plan allows: these stay
/// editable, those are read-only.
class KeepLock {
  const KeepLock({
    required this.feature,
    required this.scope,
    required this.limit,
    required this.kept,
    required this.locked,
    required this.pending,
    this.canChangeAt,
  });

  factory KeepLock.fromJson(Map<String, dynamic> json) => KeepLock(
        feature: json['feature'] as String? ?? '',
        scope: json['scope'] as String? ?? '',
        limit: (json['limit'] as num?)?.toInt() ?? 0,
        kept: _strings(json['kept']),
        locked: _strings(json['locked']),
        pending: json['pending'] as bool? ?? false,
        canChangeAt: _time(json['can_change_at']),
      );

  final String feature;

  /// The workspace the limit applies in; empty for a limit across the account.
  final String scope;
  final int limit;
  final List<String> kept;
  final List<String> locked;

  /// The user has not chosen yet, so the oldest are the ones kept.
  final bool pending;

  /// When a choice already made may be changed. Null: now.
  final DateTime? canChangeAt;

  bool canChange(DateTime now) => canChangeAt == null || !now.isBefore(canChangeAt!);
}

/// A campaign the server wants this user to see.
class Offer {
  const Offer({
    required this.slug,
    required this.title,
    this.titleBn = '',
    this.body = '',
    this.bodyBn = '',
    this.cta = '',
    this.ctaBn = '',
    this.placements = const [],
    this.endsAt,
    this.benefitKind = '',
    this.applied = false,
    this.claimed = false,
    this.claimable = false,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        titleBn: json['title_bn'] as String? ?? '',
        body: json['body'] as String? ?? '',
        bodyBn: json['body_bn'] as String? ?? '',
        cta: json['cta'] as String? ?? '',
        ctaBn: json['cta_bn'] as String? ?? '',
        placements: _strings(json['placements']),
        endsAt: _time(json['ends_at']),
        benefitKind: json['benefit'] is Map ? '${(json['benefit'] as Map)['kind'] ?? ''}' : '',
        applied: json['applied'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
        claimable: json['claimable'] as bool? ?? false,
      );

  static const homeBanner = 'home_banner';
  static const upgradeSheet = 'upgrade_sheet';
  static const planScreen = 'plan_screen';

  final String slug;
  final String title;
  final String titleBn;
  final String body;
  final String bodyBn;
  final String cta;
  final String ctaBn;
  final List<String> placements;
  final DateTime? endsAt;
  final String benefitKind;

  /// Everyone it reaches already has what it gives, for as long as it runs.
  final bool applied;
  final bool claimed;
  final bool claimable;

  /// Bangla when asked for and written, else English.
  String _pick(String languageCode, String english, String bangla) =>
      languageCode == 'bn' && bangla.isNotEmpty ? bangla : english;

  String titleIn(String languageCode) => _pick(languageCode, title, titleBn);
  String bodyIn(String languageCode) => _pick(languageCode, body, bodyBn);
  String ctaIn(String languageCode) => _pick(languageCode, cta, ctaBn);
}

/// A plan's name as the server gives it, in both languages.
class PlanName {
  const PlanName({required this.code, required this.name, this.nameBn = '', this.tagline = '', this.taglineBn = '', this.rank = 0});

  factory PlanName.fromJson(Map<String, dynamic> json) => PlanName(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameBn: json['name_bn'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        taglineBn: json['tagline_bn'] as String? ?? '',
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );

  final String code;
  final String name;
  final String nameBn;
  final String tagline;
  final String taglineBn;

  /// Higher gives more.
  final int rank;

  String nameIn(String languageCode) => languageCode == 'bn' && nameBn.isNotEmpty ? nameBn : name;
  String taglineIn(String languageCode) => languageCode == 'bn' && taglineBn.isNotEmpty ? taglineBn : tagline;
}

/// What the server says the signed-in user's plan gives.
///
/// This only shapes what the app shows and offers. The server checks every
/// write again, so a changed copy on the phone unlocks nothing that syncs.
class Entitlements {
  Entitlements(this.json, {required this.fetchedAt})
      : plan = PlanName.fromJson(_map(json['plan'])),
        features = {
          for (final MapEntry(:key, :value) in _map(json['features']).entries)
            if (value is Map) key: FeatureValue.fromJson(value.cast<String, dynamic>()),
        },
        locks = [
          for (final lock in (json['locks'] as List?) ?? const [])
            if (lock is Map) KeepLock.fromJson(lock.cast<String, dynamic>()),
        ],
        offers = [
          for (final offer in (json['offers'] as List?) ?? const [])
            if (offer is Map) Offer.fromJson(offer.cast<String, dynamic>()),
        ];

  /// From the copy kept on the phone. Null when it cannot be read.
  static Entitlements? decode(String stored) {
    try {
      final body = (jsonDecode(stored) as Map).cast<String, dynamic>();
      final fetched = _time(body['fetched_at']);
      final json = body['entitlements'];
      if (fetched == null || json is! Map) return null;
      return Entitlements(json.cast<String, dynamic>(), fetchedAt: fetched);
    } on Object {
      return null;
    }
  }

  static Map<String, dynamic> _map(Object? value) => value is Map ? value.cast<String, dynamic>() : const {};

  /// The server's answer as it came. Keys this version does not know stay in it.
  final Map<String, dynamic> json;

  /// When the phone last heard from the server about this.
  final DateTime fetchedAt;

  final PlanName plan;
  final Map<String, FeatureValue> features;
  final List<KeepLock> locks;
  final List<Offer> offers;

  String encode() => jsonEncode({'fetched_at': fetchedAt.toUtc().toIso8601String(), 'entitlements': json});

  /// Changes whenever anything in the answer does.
  String get version => json['version'] as String? ?? '';

  /// 'default' for the plan everyone starts on, else where the plan came from.
  String get source => json['source'] as String? ?? 'default';
  bool get isDefaultPlan => source == 'default';
  DateTime? get expiresAt => _time(json['expires_at']);

  /// False while the server is set to refuse nothing (a switch in its admin):
  /// the app then refuses and locks nothing either, and only shows the plan.
  bool get enforced => json['enforced'] as bool? ?? true;

  /// The payment is late; the plan is kept for a few days.
  bool get inGrace => json['in_grace'] as bool? ?? false;
  int get offlineGraceDays => (json['offline_grace_days'] as num?)?.toInt() ?? 7;
  int get warnAtPercent => (json['warn_at_percent'] as num?)?.toInt() ?? 80;

  /// The plan ended while the phone was offline for longer than the server
  /// allows: extras are off until it hears from the server again.
  bool isStale([DateTime? now]) {
    final end = expiresAt;
    if (end == null) return false;
    return (now ?? DateTime.now()).isAfter(end.add(Duration(days: offlineGraceDays)));
  }

  FeatureValue? operator [](String feature) => features[feature];

  /// Whether a switched feature is on. A feature the server did not mention is off.
  bool can(String feature, {DateTime? now}) => !isStale(now) && (features[feature]?.enabled ?? false);

  /// The most allowed at one time. Null when unlimited, and for a feature the
  /// server did not mention: the app then lets the server decide.
  int? limitOf(String feature) {
    final value = features[feature];
    return value == null || value.unlimited ? null : value.limit;
  }

  late final Set<String> _locked = {for (final lock in locks) ...lock.locked};

  /// Read-only since a downgrade.
  bool isLocked(String id) => _locked.contains(id);

  KeepLock? lockFor(String feature, [String scope = '']) {
    for (final lock in locks) {
      if (lock.feature == feature && lock.scope == scope) return lock;
    }
    return null;
  }

  /// Something is locked and the user has not said what to keep.
  bool get hasPendingChoice => locks.any((lock) => lock.pending);

  /// Offers for one place in the app, still running.
  List<Offer> offersFor(String placement, [DateTime? now]) {
    final moment = now ?? DateTime.now();
    return [
      for (final offer in offers)
        if (offer.placements.contains(placement) && (offer.endsAt == null || offer.endsAt!.isAfter(moment))) offer,
    ];
  }
}

/// The plan does not allow what was asked. Thrown before a change is queued,
/// and built from the server's answer when it refuses one.
class PlanLimitException implements Exception {
  const PlanLimitException(this.feature, {this.reason = reasonLimit, this.limit, this.current, this.upgradeTo});

  /// From the body of a 402, or the `meta` of a refused sync change.
  factory PlanLimitException.fromJson(Map<dynamic, dynamic> json) => PlanLimitException(
        '${json['feature'] ?? ''}',
        reason: '${json['reason'] ?? reasonLimit}',
        limit: (json['limit'] as num?)?.toInt(),
        current: (json['current'] as num?)?.toInt(),
        upgradeTo: json['upgrade_to'] as String?,
      );

  static const reasonFeature = 'feature';
  static const reasonLimit = 'limit';
  static const reasonQuota = 'quota';
  static const reasonLocked = 'locked';

  final String feature;
  final String reason;
  final int? limit;
  final int? current;

  /// Code of the cheapest plan that gives more, when the server said.
  final String? upgradeTo;

  @override
  String toString() => 'PlanLimitException($feature, $reason)';
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../plan/plan_page.dart';
import '../plan/plan_text.dart';
import '../plan/upgrade_sheet.dart';
import 'ledger_repository.dart';

/// Slice colours for the spending chart. The first is the theme's primary, so
/// it stays readable in the dark theme.
List<Color> _chartColors(BuildContext context) => [
      Theme.of(context).colorScheme.primary,
      AppTheme.accentColor,
      AppTheme.secondaryColor,
      const Color(0xFFE8705F),
      const Color(0xFF3B9EE5),
      const Color(0xFF7A5AF8),
      const Color(0xFF1FA6A0),
      const Color(0xFF8A97AB),
    ];

String accountKindLabel(BuildContext context, String kind) => switch (kind) {
      'bank' => context.l10n.kindBank,
      'savings' => context.l10n.kindSavings,
      'mobile_money' => context.l10n.kindMobileMoney,
      'card' => context.l10n.kindCard,
      _ => context.l10n.kindCash,
    };

IconData accountKindIcon(String kind) => switch (kind) {
      'bank' => Icons.account_balance_rounded,
      'savings' => Icons.savings_rounded,
      'mobile_money' => Icons.phone_android_rounded,
      'card' => Icons.credit_card_rounded,
      _ => Icons.payments_rounded,
    };

/// [date] (ISO) preselects the day of a new transaction, e.g. from the budget calendar.
void openTransactionForm(BuildContext context, Workspace workspace, {TransactionView? existing, String? date}) =>
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TransactionFormPage(workspace: workspace, existing: existing, initialDate: date),
    ));

final monthSummaryProvider = StreamProvider.family<MonthSummary, (String, String)>(
  (ref, key) => ref.watch(ledgerRepositoryProvider).watchMonth(key.$1, ref.watch(selectedMonthProvider), key.$2),
);

final monthlyTotalsProvider = StreamProvider.family<List<MonthTotals>, (String, String)>(
  (ref, key) =>
      ref.watch(ledgerRepositoryProvider).watchMonthlyTotals(key.$1, ref.watch(selectedMonthProvider), key.$2),
);

final topCategoriesProvider = StreamProvider.family<List<CategoryChange>, (String, String)>(
  (ref, key) =>
      ref.watch(ledgerRepositoryProvider).watchTopCategories(key.$1, ref.watch(selectedMonthProvider), key.$2),
);

String _localDigits(BuildContext context, String text) =>
    context.languageCode == 'bn' ? Money.toBengaliDigits(text) : text;

/// Balances, the selected month's income and expense, how spending is pacing
/// against the budgets, where the money went, how the last six months compare
/// and which categories moved most.
/// Figures are in the workspace currency; accounts in other currencies are listed, not added up.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final currency = workspace.defaultCurrency;
    final key = (workspace.id, currency);
    final accounts = ref.watch(accountsProvider(workspace.id)).value ?? const <AccountBalance>[];
    final total = accounts
        .where((a) => a.account.currency == currency && !a.account.isArchived)
        .fold<int>(0, (sum, a) => sum + a.balanceMinor);
    final month = ref.watch(monthSummaryProvider(key)).value;
    final trend = ref.watch(monthlyTotalsProvider(key)).value ?? const <MonthTotals>[];
    final top = ref.watch(topCategoriesProvider(key)).value ?? const <CategoryChange>[];
    final budgets = ref.watch(budgetsProvider(workspace.id)).value ?? const <BudgetProgress>[];
    final budgetTotal =
        budgets.where((b) => b.budget.currency == currency).fold<int>(0, (sum, b) => sum + b.budget.amountMinor);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = now.year == selectedMonth.year && now.month == selectedMonth.month;
    final chartColors = _chartColors(context);

    return PassbookBody(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderFigure(label: l10n.totalBalance, amountMinor: total, currency: currency),
          const SizedBox(height: 12),
          MonthSwitcher(month: selectedMonth, onChanged: ref.read(selectedMonthProvider.notifier).set),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
          children: [
            if (month != null) ...[
              Entrance(
                child: SectionCard(children: [
                  Row(
                    children: [
                      StatTile(
                        label: l10n.income,
                        amountMinor: month.incomeMinor,
                        currency: currency,
                        color: context.amountColor(true),
                        icon: Icons.south_west_rounded,
                      ),
                      StatTile(
                        label: l10n.expense,
                        amountMinor: month.expenseMinor,
                        currency: currency,
                        color: context.amountColor(false),
                        icon: Icons.north_east_rounded,
                      ),
                      StatTile(
                        label: l10n.net,
                        amountMinor: month.incomeMinor - month.expenseMinor,
                        currency: currency,
                        color: context.amountColor(month.incomeMinor >= month.expenseMinor),
                        icon: Icons.drag_handle_rounded,
                      ),
                    ],
                  ),
                ]),
              ),
              if (budgetTotal > 0)
                Entrance(
                  index: 1,
                  child: SectionCard(children: [
                    PaceBar(
                      spentMinor: month.expenseMinor,
                      limitMinor: budgetTotal,
                      currency: currency,
                      dayFraction: isCurrentMonth ? now.day / daysInMonth(selectedMonth) : null,
                    ),
                  ]),
                ),
              Entrance(
                index: 2,
                child: SectionCard(title: l10n.spendingByCategory, children: [
                  if (month.byCategory.isEmpty)
                    Text(l10n.noSpendingYet, style: text.bodyMedium?.copyWith(color: context.colors.muted))
                  else ...[
                    SizedBox(
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 62,
                              startDegreeOffset: -90,
                              sections: [
                                for (final (index, slice) in month.byCategory.indexed)
                                  PieChartSectionData(
                                    value: slice.value.toDouble(),
                                    color: chartColors[index % chartColors.length],
                                    showTitle: false,
                                    radius: 26,
                                  ),
                              ],
                            ),
                            duration: context.motion(AppMotion.emphasised),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.spent, style: text.bodySmall),
                              SizedBox(
                                width: 108,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    Money.compact(month.expenseMinor, currency, locale: context.languageCode),
                                    style: text.headlineSmall?.copyWith(fontFeatures: tabularFigures),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (index, slice) in month.byCategory.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: chartColors[index % chartColors.length],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(slice.key ?? l10n.uncategorised, overflow: TextOverflow.ellipsis)),
                            if (month.expenseMinor > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  _localDigits(context, '${(slice.value * 100 / month.expenseMinor).round()}%'),
                                  style: text.bodySmall,
                                ),
                              ),
                            Text(
                              context.money(slice.value, currency),
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                            ),
                          ],
                        ),
                      ),
                  ],
                ]),
              ),
            ],
            if (trend.any((m) => m.incomeMinor > 0 || m.expenseMinor > 0))
              SectionCard(title: l10n.lastSixMonths, children: [_TrendChart(trend: trend, currency: currency)]),
            if (top.isNotEmpty)
              SectionCard(title: l10n.topCategories, children: [
                for (final item in top)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.categoryName ?? l10n.uncategorised, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              _ChangeChip(percent: item.changePercent),
                            ],
                          ),
                        ),
                        Text(
                          context.money(item.thisMonthMinor, currency),
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                        ),
                      ],
                    ),
                  ),
              ]),
            if (accounts.isNotEmpty)
              SectionCard(title: l10n.accountBalances, children: [
                for (final item in accounts.where((a) => !a.account.isArchived))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        IconBadge(accountKindIcon(item.account.kind), size: 36),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.account.name, overflow: TextOverflow.ellipsis)),
                        Text(
                          context.money(item.balanceMinor, item.account.currency),
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                        ),
                      ],
                    ),
                  ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// "+12% vs last month" in red when spending rose, green when it fell.
class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.percent});

  /// Null: the category had no spending last month.
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rose = (percent ?? 0) > 0;
    final color = percent == null ? context.colors.muted : context.amountColor(!rose);
    final signed = percent == null ? null : _localDigits(context, '${rose ? '+' : ''}$percent');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (percent != null && percent != 0)
          Icon(rose ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: color),
        if (percent != null && percent != 0) const SizedBox(width: 4),
        Flexible(
          child: Text(
            signed == null ? l10n.newThisMonth : l10n.changeVsLastMonth(signed),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Income and expense bars for each month, oldest on the left.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend, required this.currency});

  final List<MonthTotals> trend;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final locale = context.languageCode;
    final months = MaterialLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final highest = trend.fold<int>(1, (max, m) => [max, m.incomeMinor, m.expenseMinor].reduce((a, b) => a > b ? a : b));
    const top = BorderRadius.vertical(top: Radius.circular(5));

    Widget legend(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(label, style: text.bodySmall),
          ],
        );

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: highest * 1.15,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0E1B30),
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    Money.format(rod.toY.round(), currency, locale: locale),
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                      // "Oct" from "October 2026"
                      final label = months.formatMonthYear(trend[index].month).split(' ').first;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(label.length > 3 && locale != 'bn' ? label.substring(0, 3) : label,
                            style: text.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (final (index, m) in trend.indexed)
                  BarChartGroupData(x: index, barsSpace: 4, barRods: [
                    BarChartRodData(
                      toY: m.incomeMinor.toDouble(),
                      color: AppTheme.successColor,
                      width: 10,
                      borderRadius: top,
                    ),
                    BarChartRodData(
                      toY: m.expenseMinor.toDouble(),
                      color: AppTheme.errorColor,
                      width: 10,
                      borderRadius: top,
                    ),
                  ]),
              ],
            ),
            duration: context.motion(AppMotion.emphasised),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            legend(AppTheme.successColor, context.l10n.income),
            const SizedBox(width: 20),
            legend(AppTheme.errorColor, context.l10n.expense),
          ],
        ),
      ],
    );
  }
}

/// One transaction row: what, when, from which account, how much.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, required this.onTap, this.showDate = true});

  final TransactionView view;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = view.transaction;
    final isTransfer = t.kind == 'transfer';
    final isIn = t.amountMinor > 0;
    final label = isTransfer ? l10n.transfer : (view.categoryName ?? l10n.uncategorised);
    return MoneyRow(
      icon: isTransfer ? Icons.swap_horiz_rounded : (isIn ? Icons.south_west_rounded : Icons.north_east_rounded),
      tint: isTransfer ? null : context.amountColor(isIn),
      title: t.note.isNotEmpty ? t.note : label,
      detail: [
        if (showDate) formatDate(context, t.occurredOn),
        view.accountName,
        if (t.note.isNotEmpty) label,
      ].join(' · '),
      amount: context.money(t.amountMinor, t.currency),
      amountColor: isTransfer ? null : context.amountColor(isIn),
      onTap: onTap,
    );
  }
}

/// The month's transactions under day headings, with a search box and a
/// filter by kind. Both work on the device, over what is already loaded.
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _query = '';
  String _kind = 'all';

  bool _matches(TransactionView view) {
    final t = view.transaction;
    if (_kind != 'all' && t.kind != _kind) return false;
    final query = Money.toAsciiDigits(_query.trim().toLowerCase());
    if (query.isEmpty) return true;
    return [
      t.note,
      view.categoryName ?? '',
      view.accountName,
      Money.toInput(t.amountMinor.abs(), t.currency),
    ].any((field) => field.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workspace = widget.workspace;
    final text = Theme.of(context).textTheme;

    Widget list(List<TransactionView> all) {
      final shown = all.where(_matches).toList();
      if (shown.isEmpty) {
        final searching = _query.trim().isNotEmpty;
        return ListView(children: [
          SizedBox(
            height: 340,
            child: all.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: l10n.noTransactions,
                    actionLabel: l10n.addTransaction,
                    onAction: () => openTransactionForm(context, workspace),
                  )
                : EmptyState(
                    icon: Icons.search_off_rounded,
                    message: searching ? l10n.noResultsFor(_query.trim()) : l10n.noMatches,
                  ),
          ),
        ]);
      }

      // A heading before the first row of each day, carrying the day's net in the workspace currency
      final rows = <Widget>[];
      String? day;
      for (final view in shown) {
        final t = view.transaction;
        if (t.occurredOn != day) {
          day = t.occurredOn;
          final net = shown
              .where((v) =>
                  v.transaction.occurredOn == day &&
                  v.transaction.kind != 'transfer' &&
                  v.transaction.currency == workspace.defaultCurrency)
              .fold<int>(0, (sum, v) => sum + v.transaction.amountMinor);
          rows.add(Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 14, AppSpace.page, 4),
            child: Row(
              children: [
                Expanded(child: Text(friendlyDate(context, t.occurredOn), style: text.titleSmall)),
                Text(
                  context.money(net, workspace.defaultCurrency),
                  style: text.bodySmall?.copyWith(fontFeatures: tabularFigures),
                ),
              ],
            ),
          ));
        }
        rows.add(TransactionTile(
          view: view,
          showDate: false,
          onTap: () => openTransactionForm(context, workspace, existing: view),
        ));
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index],
      );
    }

    return PassbookBody(
      header: MonthSwitcher(
        month: ref.watch(selectedMonthProvider),
        onChanged: ref.read(selectedMonthProvider.notifier).set,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.sm),
            child: Theme(
              // On the pale sheet the search pill is white
              data: Theme.of(context).copyWith(
                inputDecorationTheme:
                    Theme.of(context).inputDecorationTheme.copyWith(fillColor: context.colors.sheet),
              ),
              child: AppSearchField(
                hint: l10n.searchTransactions,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            child: SlidingSegmented<String>(
              segments: {
                'all': l10n.filterAll,
                'expense': l10n.expense,
                'income': l10n.income,
                'transfer': l10n.transfer,
              },
              value: _kind,
              onChanged: (value) => setState(() => _kind = value),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
              child: AsyncView(value: ref.watch(transactionsProvider(workspace.id)), builder: list),
            ),
          ),
        ],
      ),
    );
  }
}

/// Add an expense, income or transfer; or edit the amount, date, category and note of an existing one.
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, required this.workspace, this.existing, this.initialDate});

  final Workspace workspace;
  final TransactionView? existing;
  final String? initialDate;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Transaction? _original = widget.existing?.transaction;
  late String _kind = _original?.kind ?? 'expense';
  late final _amount = TextEditingController(
    text: _original == null ? '' : Money.toInput(_original.amountMinor.abs(), _original.currency),
  );
  late final _note = TextEditingController(text: _original?.note ?? '');
  late String _date = _original?.occurredOn ?? widget.initialDate ?? todayIso();
  late String? _accountId = _original?.accountId;
  String? _toAccountId;
  late String? _categoryId = _original?.categoryId;
  int _refused = 0;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _refuse(String message) {
    setState(() => _refused++);
    context.showMessage(message);
  }

  Future<void> _save(List<AccountBalance> accounts) => guarded(context, () => _write(accounts));

  Future<void> _write(List<AccountBalance> accounts) async {
    if (!_formKey.currentState!.validate()) return setState(() => _refused++);
    final l10n = context.l10n;
    final repo = ref.read(ledgerRepositoryProvider);
    final account = accounts.firstWhere((a) => a.account.id == _accountId).account;
    final amount = Money.evaluate(_amount.text, account.currency)!;

    if (_original != null) {
      await repo.updateTransaction(_original,
          amountMinor: amount, occurredOn: _date, categoryId: _categoryId, note: _note.text.trim());
    } else if (_kind == 'transfer') {
      final to = accounts.firstWhere((a) => a.account.id == _toAccountId).account;
      if (to.id == account.id) return _refuse(l10n.sameAccountError);
      if (to.currency != account.currency) return _refuse(l10n.currencyMismatch);
      await repo.addTransfer(account, to, amountMinor: amount, occurredOn: _date, note: _note.text.trim());
    } else {
      await repo.addTransaction(account,
          kind: _kind, amountMinor: amount, occurredOn: _date, categoryId: _categoryId, note: _note.text.trim());
    }
    if (!mounted) return;
    final formatted = context.money(amount, account.currency);
    switch (_kind) {
      case 'income':
        showEventBurst(context, AppEvent.moneyIn, label: '+$formatted');
      case 'transfer':
        showEventBurst(context, AppEvent.transfer, label: formatted);
      default:
        showEventBurst(context, AppEvent.moneyOut, label: '−$formatted');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final accounts = (ref.watch(accountsProvider(widget.workspace.id)).value ?? const <AccountBalance>[])
        .where((a) => !a.account.isArchived || a.account.id == _accountId)
        .toList();
    final categories = (ref.watch(categoriesProvider(widget.workspace.id)).value ?? const <Category>[])
        .where((c) => c.kind == (_kind == 'income' ? 'income' : 'expense'))
        .toList();
    if (accounts.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: AppLoader()));
    _accountId ??= accounts.first.account.id;
    _toAccountId ??= accounts.length > 1 ? accounts[1].account.id : accounts.first.account.id;
    final account = accounts.firstWhere((a) => a.account.id == _accountId, orElse: () => accounts.first).account;
    final editing = _original != null;
    final isTransfer = _kind == 'transfer';
    Color kindColor(String kind) => switch (kind) {
          'income' => AppTheme.successColor,
          'transfer' => scheme.primary,
          _ => AppTheme.errorColor,
        };

    Widget accountPicker(String label, String? value, ValueChanged<String?> onChanged) => SelectField<String>(
          label: label,
          value: value,
          options: [
            for (final a in accounts)
              SelectOption(
                a.account.id,
                a.account.name,
                icon: accountKindIcon(a.account.kind),
                detail: '${accountKindLabel(context, a.account.kind)} · ${a.account.currency}',
              ),
          ],
          // The account of a saved transaction is fixed: its currency came from it
          onChanged: editing ? null : onChanged,
        );

    return Scaffold(
      backgroundColor: context.colors.sheet,
      appBar: AppBar(
        backgroundColor: context.colors.sheet,
        title: Text(editing ? l10n.editTransaction : l10n.addTransaction),
        actions: [
          if (editing)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (await confirm(context, l10n.deleteConfirm)) {
                  await ref.read(ledgerRepositoryProvider).deleteTransaction(_original);
                  if (!context.mounted) return;
                  showEventBurst(context, AppEvent.deleted);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      // In the bottom slot, so it rides above the keyboard and messages float above it
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.md),
            child: Shake(
              trigger: _refused,
              child: BusyButton(label: l10n.save, color: kindColor(_kind), onPressed: () => _save(accounts)),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.lg),
          children: [
            if (!editing) ...[
              SlidingSegmented<String>(
                segments: {'expense': l10n.expense, 'income': l10n.income, 'transfer': l10n.transfer},
                value: _kind,
                colorOf: kindColor,
                onChanged: (value) => setState(() {
                  _kind = value;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 20),
            ],
            AmountField(
              controller: _amount,
              currency: account.currency,
              hero: true,
              autofocus: !editing,
              color: isTransfer ? null : context.amountColor(_kind == 'income'),
            ),
            const SizedBox(height: 20),
            accountPicker(isTransfer ? l10n.fromAccount : l10n.account, _accountId,
                (value) => setState(() => _accountId = value)),
            const SizedBox(height: 12),
            if (isTransfer && !editing) ...[
              accountPicker(l10n.toAccount, _toAccountId, (value) => setState(() => _toAccountId = value)),
              const SizedBox(height: 12),
            ],
            if (!isTransfer) ...[
              SelectField<String>(
                label: l10n.category,
                icon: Icons.sell_outlined,
                value: _categoryId,
                noneLabel: l10n.none,
                options: [for (final c in categories) SelectOption(c.id, c.name)],
                createLabel: l10n.newCategory,
                onCreate: (name) async {
                  String? id;
                  await guarded(context, () async {
                    id = await ref
                        .read(ledgerRepositoryProvider)
                        .addCategory(widget.workspace.id, name, _kind == 'income' ? 'income' : 'expense');
                  });
                  return id;
                },
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
            ],
            DateField(value: _date, onChanged: (value) => setState(() => _date = value)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.note,
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              ),
              maxLength: 200,
              buildCounter: quietCounter,
            ),
          ],
        ),
      ),
    );
  }
}

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final currency = workspace.defaultCurrency;
    final value = ref.watch(accountsProvider(workspace.id));
    final plan = ref.watch(entitlementsProvider).value;
    final total = (value.value ?? const <AccountBalance>[])
        .where((a) => a.account.currency == currency && !a.account.isArchived)
        .fold<int>(0, (sum, a) => sum + a.balanceMinor);

    return PassbookBody(
      header: HeaderFigure(label: l10n.totalBalance, amountMinor: total, currency: currency),
      child: AsyncView(
        value: value,
        builder: (accounts) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
          children: [
            for (final (index, item) in accounts.indexed)
              Entrance(
                index: index,
                child: Opacity(
                  opacity: item.account.isArchived ? 0.55 : 1,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpace.md),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => showAccountForm(context, workspace, existing: item.account),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        child: Row(
                          children: [
                            IconBadge(accountKindIcon(item.account.kind)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.account.name, style: text.titleMedium, overflow: TextOverflow.ellipsis),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.account.isArchived
                                              ? l10n.archived
                                              : accountKindLabel(context, item.account.kind),
                                          style: text.bodySmall?.copyWith(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Read-only since a downgrade; archiving it is still allowed
                                      if (!item.account.isArchived && (plan?.isLocked(item.account.id) ?? false)) ...[
                                        const SizedBox(width: 8),
                                        const LockedTag(),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            MoneyText(item.balanceMinor, item.account.currency, style: text.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AddRowButton(label: l10n.addAccount, onPressed: () => showAccountForm(context, workspace)),
            LimitHint(feature: F.personalAccounts, workspace: workspace),
          ],
        ),
      ),
    );
  }
}

Future<void> showAccountForm(BuildContext context, Workspace workspace, {Account? existing}) => showAppSheet<void>(
      context,
      title: existing == null ? context.l10n.addAccount : context.l10n.editAccount,
      builder: (_) => _AccountForm(workspace: workspace, existing: existing),
    );

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({required this.workspace, this.existing});

  final Workspace workspace;
  final Account? existing;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _kind = widget.existing?.kind ?? 'cash';
  late String _currency = widget.existing?.currency ?? widget.workspace.defaultCurrency;
  late final _opening = TextEditingController(
    text: Money.toInput(widget.existing?.openingBalanceMinor ?? 0, widget.existing?.currency ?? widget.workspace.defaultCurrency),
  );
  late bool _archived = widget.existing?.isArchived ?? false;
  int _refused = 0;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() => guarded(context, _write);

  Future<void> _write() async {
    if (!_formKey.currentState!.validate()) return setState(() => _refused++);
    final repo = ref.read(ledgerRepositoryProvider);
    final opening = Money.evaluate(_opening.text, _currency)!;
    if (widget.existing == null) {
      await repo.addAccount(widget.workspace.id,
          name: _name.text.trim(), kind: _kind, currency: _currency, openingBalanceMinor: opening);
    } else {
      await repo.updateAccount(widget.existing!,
          name: _name.text.trim(), kind: _kind, openingBalanceMinor: opening, isArchived: _archived);
    }
    if (!mounted) return;
    showEventBurst(context, AppEvent.saved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.existing != null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.accountName),
            validator: (value) => (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 12),
          SelectField<String>(
            label: l10n.accountKind,
            value: _kind,
            options: [
              for (final kind in const ['cash', 'bank', 'savings', 'mobile_money', 'card'])
                SelectOption(kind, accountKindLabel(context, kind), icon: accountKindIcon(kind)),
            ],
            onChanged: (value) => setState(() => _kind = value!),
          ),
          const SizedBox(height: 12),
          SelectField<String>(
            label: l10n.currency,
            value: _currency,
            options: currencyOptions(include: _currency),
            // Fixed once the account exists: its transactions are in this currency
            onChanged: editing ? null : (value) => setState(() => _currency = value!),
          ),
          const SizedBox(height: 12),
          AmountField(controller: _opening, currency: _currency, label: l10n.openingBalance, allowZero: true),
          if (editing) ...[
            const SizedBox(height: 12),
            SwitchField(
              title: l10n.archive,
              value: _archived,
              onChanged: (value) => setState(() => _archived = value),
            ),
          ],
          const SizedBox(height: 20),
          Shake(trigger: _refused, child: BusyButton(label: l10n.save, onPressed: _save)),
        ],
      ),
    );
  }
}

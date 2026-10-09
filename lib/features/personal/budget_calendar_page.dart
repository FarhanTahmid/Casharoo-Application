import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/ui.dart';
import '../plan/upgrade_sheet.dart';
import 'ledger_repository.dart';
import 'personal_pages.dart';

/// Expense per day of the selected month, keyed by (workspace id, currency).
final dailySpendProvider = StreamProvider.family<Map<int, int>, (String, String)>(
  (ref, key) => ref.watch(ledgerRepositoryProvider).watchDailySpend(key.$1, ref.watch(selectedMonthProvider), key.$2),
);

/// Transactions of one day, keyed by (workspace id, ISO date).
final dayTransactionsProvider = StreamProvider.family<List<TransactionView>, (String, String)>(
  (ref, key) => ref.watch(ledgerRepositoryProvider).watchTransactions(key.$1, day: key.$2),
);

/// The month at a glance: what the budgets allow, what each day cost, and how
/// each category is doing. Days are coloured against the daily allowance
/// (the month's total budget spread evenly over its days).
class BudgetCalendarPage extends ConsumerWidget {
  const BudgetCalendarPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final month = ref.watch(selectedMonthProvider);
    final currency = workspace.defaultCurrency;
    final budgets = ref.watch(budgetsProvider(workspace.id)).value ?? const <BudgetProgress>[];
    final daily = ref.watch(dailySpendProvider((workspace.id, currency))).value ?? const <int, int>{};

    final totalBudget =
        budgets.where((b) => b.budget.currency == currency).fold<int>(0, (sum, b) => sum + b.budget.amountMinor);
    final spent = daily.values.fold<int>(0, (sum, value) => sum + value);
    final allowance = totalBudget ~/ daysInMonth(month);
    final remaining = totalBudget - spent;
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    void addBudget() => showBudgetForm(context, ref, workspace, month: month);

    return PassbookBody(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Without a budget there is nothing to have left; show what was spent
          if (totalBudget > 0)
            HeaderFigure(
              label: l10n.remaining,
              amountMinor: remaining,
              currency: currency,
              color: remaining < 0 ? const Color(0xFFFF9AA2) : null,
            )
          else
            HeaderFigure(label: l10n.spent, amountMinor: spent, currency: currency),
          const SizedBox(height: 12),
          MonthSwitcher(month: month, onChanged: ref.read(selectedMonthProvider.notifier).set),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
        children: [
          if (totalBudget > 0)
            Entrance(
              child: SectionCard(children: [
                Row(
                  children: [
                    StatTile(
                      label: l10n.budgetThisMonth,
                      amountMinor: totalBudget,
                      currency: currency,
                      color: Theme.of(context).colorScheme.primary,
                      icon: Icons.flag_rounded,
                    ),
                    StatTile(
                      label: l10n.spent,
                      amountMinor: spent,
                      currency: currency,
                      color: context.amountColor(false),
                      icon: Icons.north_east_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LimitBar(
                  value: spent / totalBudget,
                  marker: isCurrentMonth ? now.day / daysInMonth(month) : null,
                  height: 12,
                ),
              ]),
            ),
          Entrance(
            index: 1,
            child: SectionCard(
              padding: const EdgeInsets.all(AppSpace.md),
              children: [
                if (allowance > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text('${l10n.dailyAllowance}: ${l10n.perDay(context.money(allowance, currency))}',
                        style: text.bodySmall),
                  ),
                _CalendarGrid(
                  month: month,
                  daily: daily,
                  allowance: allowance,
                  currency: currency,
                  onDayTap: (day) => _showDay(context, workspace, DateTime(month.year, month.month, day)),
                ),
              ],
            ),
          ),
          if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(l10n.noBudgets, textAlign: TextAlign.center, style: TextStyle(color: context.colors.muted)),
            )
          else
            for (final item in budgets) _BudgetCard(workspace: workspace, item: item, month: month),
          AddRowButton(label: l10n.addBudget, onPressed: addBudget),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.daily,
    required this.allowance,
    required this.currency,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<int, int> daily;
  final int allowance;
  final String currency;
  final ValueChanged<int> onDayTap;

  /// No spending: plain. Within the allowance: green. Up to half again over: amber. Beyond: red.
  Color? _shade(BuildContext context, int spent) {
    if (spent == 0) return null;
    if (allowance == 0) return Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
    if (spent <= allowance) return AppTheme.successColor.withValues(alpha: 0.18);
    if (spent * 2 <= allowance * 3) return AppTheme.warningColor.withValues(alpha: 0.28);
    return AppTheme.errorColor.withValues(alpha: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final locale = context.languageCode;
    final text = Theme.of(context).textTheme;
    final firstWeekday = localizations.firstDayOfWeekIndex; // 0 = Sunday
    final leading = (DateTime(month.year, month.month, 1).weekday % 7 - firstWeekday + 7) % 7;
    final days = daysInMonth(month);
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    String digits(String text) => locale == 'bn' ? Money.toBengaliDigits(text) : text;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(localizations.narrowWeekdays[(firstWeekday + i) % 7], style: text.labelSmall),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  key: ValueKey('day-$day'),
                  color: _shade(context, daily[day] ?? 0) ?? Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCurrentMonth && now.day == day
                        ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onDayTap(day),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          digits('$day'),
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                        ),
                        if ((daily[day] ?? 0) > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Money.compact(daily[day]!, currency, locale: locale),
                              style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _showDay(BuildContext context, Workspace workspace, DateTime date) => showAppSheet<void>(
      context,
      title: formatDate(context, isoDate(date)),
      scrolls: false,
      trailing: Builder(
        builder: (context) => TextButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.addTransaction),
          onPressed: () {
            Navigator.pop(context);
            openTransactionForm(context, workspace, date: isoDate(date));
          },
        ),
      ),
      builder: (_) => _DaySheet(workspace: workspace, date: isoDate(date)),
    );

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.workspace, required this.date});

  final Workspace workspace;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(dayTransactionsProvider((workspace.id, date))).value ?? const <TransactionView>[];
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          context.l10n.noTransactionsOnDay,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.muted),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final view in transactions)
          TransactionTile(
            view: view,
            showDate: false,
            onTap: () {
              Navigator.pop(context);
              openTransactionForm(context, workspace, existing: view);
            },
          ),
      ],
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.workspace, required this.item, required this.month});

  final Workspace workspace;
  final BudgetProgress item;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final currency = item.budget.currency;
    // Going over the limit while the card is on screen gives it a shake
    return Shake(
      trigger: item.isOver ? 1 : 0,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBudgetForm(context, ref, workspace, month: month, existing: item),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.categoryName, style: text.titleMedium, overflow: TextOverflow.ellipsis)),
                    if (item.isOverride) _Tag(l10n.thisMonthOnly, context.colors.muted),
                    if (item.isOver) _Tag(l10n.overBudget, context.colors.moneyOut),
                  ],
                ),
                const SizedBox(height: 8),
                LimitBar(value: item.spentMinor / item.budget.amountMinor),
                const SizedBox(height: 6),
                Text(
                  l10n.spentOf(
                    context.money(item.spentMinor, currency),
                    context.money(item.budget.amountMinor, currency),
                  ),
                  style: text.bodyMedium?.copyWith(fontFeatures: tabularFigures),
                ),
                if (item.recurring != null)
                  Text(
                    l10n.usualLimit(context.money(item.recurring!.amountMinor, item.recurring!.currency)),
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      );
}

/// Add or change a budget. "This month only" sets an override for [month]
/// and leaves the category's usual limit as it is.
Future<void> showBudgetForm(BuildContext context, WidgetRef ref, Workspace workspace,
    {required DateTime month, BudgetProgress? existing}) async {
  final l10n = context.l10n;
  final repo = ref.read(ledgerRepositoryProvider);
  final currency = existing?.budget.currency ?? workspace.defaultCurrency;
  final categories = (await repo.watchCategories(workspace.id).first).where((c) => c.kind == 'expense').toList();
  if (!context.mounted) return;

  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(
    text: existing == null ? '' : Money.toInput(existing.budget.amountMinor, currency),
  );
  final options = [for (final c in categories) SelectOption(c.id, c.name)];
  var categoryId = existing?.budget.categoryId ?? categories.firstOrNull?.id;
  var thisMonthOnly = existing?.isOverride ?? false;
  var refused = 0;

  await showAppSheet<void>(
    context,
    title: existing == null ? l10n.addBudget : existing.categoryName,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountField(controller: amount, currency: currency, label: l10n.monthlyLimit, hero: true),
            const SizedBox(height: 16),
            if (existing == null) ...[
              SelectField<String>(
                label: l10n.category,
                icon: Icons.sell_outlined,
                value: categoryId,
                options: options,
                createLabel: l10n.newCategory,
                onCreate: (name) async {
                  String? id;
                  await guarded(context, () async => id = await repo.addCategory(workspace.id, name, 'expense'));
                  if (id != null) options.add(SelectOption(id!, name));
                  return id;
                },
                onChanged: (value) => setState(() => categoryId = value),
              ),
              const SizedBox(height: 12),
            ],
            SwitchField(
              title: l10n.thisMonthOnly,
              subtitle: '${MaterialLocalizations.of(context).formatMonthYear(month)} · ${l10n.thisMonthOnlyHint}',
              value: thisMonthOnly,
              // An override stays an override; remove it to go back to the usual limit
              onChanged: existing?.isOverride == true ? null : (value) => setState(() => thisMonthOnly = value),
            ),
            const SizedBox(height: 20),
            Shake(
              trigger: refused,
              child: FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate() || categoryId == null) return setState(() => refused++);
                  final saved = await guarded(
                    context,
                    () => repo.setBudget(workspace.id, categoryId!, Money.evaluate(amount.text, currency)!, currency,
                        month: thisMonthOnly ? monthKey(month) : null),
                  );
                  if (!saved || !context.mounted) return;
                  showEventBurst(context, AppEvent.saved);
                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ),
            if (existing != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () async {
                    await repo.deleteBudget(existing.budget.id);
                    if (!context.mounted) return;
                    showEventBurst(context, AppEvent.deleted);
                    Navigator.pop(context);
                  },
                  child: Text(existing.isOverride && existing.recurring != null ? l10n.useUsualLimit : l10n.delete),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

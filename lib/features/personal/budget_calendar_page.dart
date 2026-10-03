import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
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
    final month = ref.watch(selectedMonthProvider);
    final currency = workspace.defaultCurrency;
    final budgets = ref.watch(budgetsProvider(workspace.id)).value ?? const <BudgetProgress>[];
    final daily = ref.watch(dailySpendProvider((workspace.id, currency))).value ?? const <int, int>{};

    final totalBudget =
        budgets.where((b) => b.budget.currency == currency).fold<int>(0, (sum, b) => sum + b.budget.amountMinor);
    final spent = daily.values.fold<int>(0, (sum, value) => sum + value);
    final allowance = totalBudget ~/ daysInMonth(month);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        MonthSwitcher(month: month, onChanged: ref.read(selectedMonthProvider.notifier).set),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Figure(l10n.budgetThisMonth, context.money(totalBudget, currency)),
                _Figure(l10n.spent, context.money(spent, currency), color: amountColor(false)),
                _Figure(
                  l10n.remaining,
                  context.money(totalBudget - spent, currency),
                  color: totalBudget - spent < 0 ? AppTheme.errorColor : AppTheme.successColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allowance > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text('${l10n.dailyAllowance}: ${l10n.perDay(context.money(allowance, currency))}',
                        style: Theme.of(context).textTheme.bodySmall),
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
        ),
        const SizedBox(height: 12),
        if (budgets.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noBudgets, textAlign: TextAlign.center))
        else
          for (final item in budgets) _BudgetCard(workspace: workspace, item: item, month: month),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
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
  Color? _shade(int spent) {
    if (spent == 0) return null;
    if (allowance == 0) return AppTheme.primaryColor.withValues(alpha: 0.15);
    if (spent <= allowance) return AppTheme.successColor.withValues(alpha: 0.18);
    if (spent * 2 <= allowance * 3) return AppTheme.warningColor.withValues(alpha: 0.28);
    return AppTheme.errorColor.withValues(alpha: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final locale = context.languageCode;
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
                  child: Text(
                    localizations.narrowWeekdays[(firstWeekday + i) % 7],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < leading; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  key: ValueKey('day-$day'),
                  color: _shade(daily[day] ?? 0) ?? Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isCurrentMonth && now.day == day
                        ? const BorderSide(color: AppTheme.primaryColor, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onDayTap(day),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(digits('$day'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        if ((daily[day] ?? 0) > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Money.compact(daily[day]!, currency, locale: locale),
                              style: Theme.of(context).textTheme.labelSmall,
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

Future<void> _showDay(BuildContext context, Workspace workspace, DateTime date) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(workspace: workspace, date: isoDate(date)),
    );

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.workspace, required this.date});

  final Workspace workspace;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final transactions = ref.watch(dayTransactionsProvider((workspace.id, date))).value ?? const <TransactionView>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(formatDate(context, date), style: Theme.of(context).textTheme.titleMedium)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTransaction),
                    onPressed: () {
                      Navigator.pop(context);
                      openTransactionForm(context, workspace, date: date);
                    },
                  ),
                ],
              ),
            ),
            if (transactions.isEmpty)
              Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noTransactionsOnDay, textAlign: TextAlign.center))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
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
                ),
              ),
          ],
        ),
      ),
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
    final currency = item.budget.currency;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showBudgetForm(context, ref, workspace, month: month, existing: item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (item.isOverride)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text(l10n.thisMonthOnly),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (item.isOver)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(l10n.overBudget, style: const TextStyle(color: AppTheme.errorColor)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (item.spentMinor / item.budget.amountMinor).clamp(0, 1).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: item.isOver ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(l10n.spentOf(
                context.money(item.spentMinor, currency),
                context.money(item.budget.amountMinor, currency),
              )),
              if (item.recurring != null)
                Text(
                  l10n.usualLimit(context.money(item.recurring!.amountMinor, item.recurring!.currency)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or change a budget. "This month only" sets an override for [month]
/// and leaves the category's usual limit as it is.
Future<void> showBudgetForm(BuildContext context, WidgetRef ref, Workspace workspace,
    {required DateTime month, BudgetProgress? existing}) async {
  final l10n = context.l10n;
  final repo = ref.read(ledgerRepositoryProvider);
  final currency = existing?.budget.currency ?? workspace.defaultCurrency;
  final categories = (await repo.watchCategories(workspace.id).first).where((c) => c.kind == 'expense').toList();
  if (!context.mounted || categories.isEmpty) return;

  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController(
    text: existing == null ? '' : Money.toInput(existing.budget.amountMinor, currency),
  );
  var categoryId = existing?.budget.categoryId ?? categories.first.id;
  var thisMonthOnly = existing?.isOverride ?? false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? l10n.addBudget : existing.categoryName),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null) ...[
                DropdownButtonFormField<String>(
                  value: categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (value) => categoryId = value!,
                ),
                const SizedBox(height: 16),
              ],
              AmountField(controller: amount, currency: currency, label: l10n.monthlyLimit),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.thisMonthOnly),
                subtitle: Text('${MaterialLocalizations.of(context).formatMonthYear(month)} · ${l10n.thisMonthOnlyHint}'),
                value: thisMonthOnly,
                // An override stays an override; remove it to go back to the usual limit
                onChanged: existing?.isOverride == true ? null : (value) => setState(() => thisMonthOnly = value),
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await repo.deleteBudget(existing.budget.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(existing.isOverride && existing.recurring != null ? l10n.useUsualLimit : l10n.delete),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await repo.setBudget(workspace.id, categoryId, Money.parse(amount.text, currency)!, currency,
                  month: thisMonthOnly ? monthKey(month) : null);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}

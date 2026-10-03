import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'ledger_repository.dart';

const _chartColors = [
  AppTheme.primaryColor, AppTheme.accentColor, AppTheme.secondaryColor, AppTheme.errorColor,
  Color(0xFF209EF3), Color(0xFF6F32FD), Colors.teal, Colors.brown,
];

String accountKindLabel(BuildContext context, String kind) => switch (kind) {
      'bank' => context.l10n.kindBank,
      'savings' => context.l10n.kindSavings,
      'mobile_money' => context.l10n.kindMobileMoney,
      'card' => context.l10n.kindCard,
      _ => context.l10n.kindCash,
    };

IconData accountKindIcon(String kind) => switch (kind) {
      'bank' => Icons.account_balance,
      'savings' => Icons.savings,
      'mobile_money' => Icons.phone_android,
      'card' => Icons.credit_card,
      _ => Icons.payments,
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

/// Balances, the selected month's income and expense, where the money went,
/// how the last six months compare and which categories moved most.
/// Figures are in the workspace currency; accounts in other currencies are listed, not added up.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = workspace.defaultCurrency;
    final key = (workspace.id, currency);
    final accounts = ref.watch(accountsProvider(workspace.id)).value ?? const <AccountBalance>[];
    final total = accounts
        .where((a) => a.account.currency == currency && !a.account.isArchived)
        .fold<int>(0, (sum, a) => sum + a.balanceMinor);
    final month = ref.watch(monthSummaryProvider(key)).value;
    final trend = ref.watch(monthlyTotalsProvider(key)).value ?? const <MonthTotals>[];
    final top = ref.watch(topCategoriesProvider(key)).value ?? const <CategoryChange>[];
    final selectedMonth = ref.watch(selectedMonthProvider);
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    Widget section(String title, List<Widget> children) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title, style: titleStyle), const SizedBox(height: 12), ...children],
            ),
          ),
        );

    return RefreshIndicator(
      onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(l10n.totalBalance),
                  Text(
                    context.money(total, currency),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          MonthSwitcher(month: selectedMonth, onChanged: ref.read(selectedMonthProvider.notifier).set),
          if (month != null) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _Stat(l10n.income, context.money(month.incomeMinor, currency), amountColor(true)),
                    _Stat(l10n.expense, context.money(month.expenseMinor, currency), amountColor(false)),
                    _Stat(
                      l10n.net,
                      context.money(month.incomeMinor - month.expenseMinor, currency),
                      amountColor(month.incomeMinor >= month.expenseMinor),
                    ),
                  ],
                ),
              ),
            ),
            section(l10n.spendingByCategory, [
              if (month.byCategory.isEmpty)
                Text(l10n.noSpendingYet)
              else ...[
                SizedBox(
                  height: 180,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (final (index, slice) in month.byCategory.indexed)
                        PieChartSectionData(
                          value: slice.value.toDouble(),
                          color: _chartColors[index % _chartColors.length],
                          showTitle: false,
                          radius: 44,
                        ),
                    ],
                  )),
                ),
                const SizedBox(height: 12),
                for (final (index, slice) in month.byCategory.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 6, backgroundColor: _chartColors[index % _chartColors.length]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(slice.key ?? l10n.uncategorised)),
                        Text(context.money(slice.value, currency)),
                      ],
                    ),
                  ),
              ],
            ]),
          ],
          if (trend.any((m) => m.incomeMinor > 0 || m.expenseMinor > 0))
            section(l10n.lastSixMonths, [_TrendChart(trend: trend, currency: currency)]),
          if (top.isNotEmpty)
            section(l10n.topCategories, [
              for (final item in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.categoryName ?? l10n.uncategorised),
                            Text(
                              switch (item.changePercent) {
                                null => l10n.newThisMonth,
                                final p => l10n.changeVsLastMonth(_signedPercent(context, p)),
                              },
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: (item.changePercent ?? 0) > 0 ? AppTheme.errorColor : AppTheme.successColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(context.money(item.thisMonthMinor, currency)),
                    ],
                  ),
                ),
            ]),
          if (accounts.isNotEmpty)
            section(l10n.accountBalances, [
              for (final item in accounts.where((a) => !a.account.isArchived))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(accountKindIcon(item.account.kind), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.account.name)),
                      Text(context.money(item.balanceMinor, item.account.currency)),
                    ],
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

String _signedPercent(BuildContext context, int percent) {
  final text = '${percent > 0 ? '+' : ''}$percent';
  return context.languageCode == 'bn' ? Money.toBengaliDigits(text) : text;
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
    final highest = trend.fold<int>(1, (max, m) => [max, m.incomeMinor, m.expenseMinor].reduce((a, b) => a > b ? a : b));
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: highest * 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  Money.format(rod.toY.round(), currency, locale: locale),
                  const TextStyle(color: Colors.white, fontSize: 12),
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
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.length) return const SizedBox.shrink();
                    // "Oct" from "October 2026"
                    final label = months.formatMonthYear(trend[index].month).split(' ').first;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(label.length > 3 && locale != 'bn' ? label.substring(0, 3) : label,
                          style: Theme.of(context).textTheme.labelSmall),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (final (index, m) in trend.indexed)
                BarChartGroupData(x: index, barsSpace: 3, barRods: [
                  BarChartRodData(toY: m.incomeMinor.toDouble(), color: AppTheme.successColor, width: 8),
                  BarChartRodData(toY: m.expenseMinor.toDouble(), color: AppTheme.errorColor, width: 8),
                ]),
            ],
          )),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 5, backgroundColor: AppTheme.successColor),
            const SizedBox(width: 4),
            Text(context.l10n.income, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 16),
            const CircleAvatar(radius: 5, backgroundColor: AppTheme.errorColor),
            const SizedBox(width: 4),
            Text(context.l10n.expense, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      );
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
    final label = isTransfer ? l10n.transfer : (view.categoryName ?? l10n.uncategorised);
    return ListTile(
      leading: CircleAvatar(
        child: Icon(isTransfer ? Icons.swap_horiz : (t.amountMinor > 0 ? Icons.south_west : Icons.north_east)),
      ),
      title: Text(t.note.isNotEmpty ? t.note : label),
      subtitle: Text([
        if (showDate) formatDate(context, t.occurredOn),
        view.accountName,
        if (t.note.isNotEmpty) label,
      ].join(' · ')),
      trailing: Text(
        context.money(t.amountMinor, t.currency),
        style: TextStyle(fontWeight: FontWeight.w600, color: isTransfer ? null : amountColor(t.amountMinor > 0)),
      ),
      onTap: onTap,
    );
  }
}

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      children: [
        MonthSwitcher(month: ref.watch(selectedMonthProvider), onChanged: ref.read(selectedMonthProvider.notifier).set),
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
            child: AsyncView(
              value: ref.watch(transactionsProvider(workspace.id)),
              builder: (transactions) => transactions.isEmpty
                  ? ListView(children: [
                      SizedBox(height: 400, child: EmptyState(icon: Icons.receipt_long_outlined, message: l10n.noTransactions)),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => TransactionTile(
                        view: transactions[index],
                        onTap: () => openTransactionForm(context, workspace, existing: transactions[index]),
                      ),
                    ),
            ),
          ),
        ),
      ],
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

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(List<AccountBalance> accounts) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final repo = ref.read(ledgerRepositoryProvider);
    final account = accounts.firstWhere((a) => a.account.id == _accountId).account;
    final amount = Money.parse(_amount.text, account.currency)!;

    if (_original != null) {
      await repo.updateTransaction(_original,
          amountMinor: amount, occurredOn: _date, categoryId: _categoryId, note: _note.text.trim());
    } else if (_kind == 'transfer') {
      final to = accounts.firstWhere((a) => a.account.id == _toAccountId).account;
      if (to.id == account.id) return context.showMessage(l10n.sameAccountError);
      if (to.currency != account.currency) return context.showMessage(l10n.currencyMismatch);
      await repo.addTransfer(account, to, amountMinor: amount, occurredOn: _date, note: _note.text.trim());
    } else {
      await repo.addTransaction(account,
          kind: _kind, amountMinor: amount, occurredOn: _date, categoryId: _categoryId, note: _note.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = (ref.watch(accountsProvider(widget.workspace.id)).value ?? const <AccountBalance>[])
        .where((a) => !a.account.isArchived || a.account.id == _accountId)
        .toList();
    final categories = (ref.watch(categoriesProvider(widget.workspace.id)).value ?? const <Category>[])
        .where((c) => c.kind == (_kind == 'income' ? 'income' : 'expense'))
        .toList();
    if (accounts.isEmpty) return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    _accountId ??= accounts.first.account.id;
    _toAccountId ??= accounts.length > 1 ? accounts[1].account.id : accounts.first.account.id;
    final account = accounts.firstWhere((a) => a.account.id == _accountId, orElse: () => accounts.first).account;
    final editing = _original != null;
    final isTransfer = _kind == 'transfer';

    DropdownButtonFormField<String> accountPicker(String label, String? value, ValueChanged<String?> onChanged) =>
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final a in accounts)
              DropdownMenuItem(value: a.account.id, child: Text('${a.account.name} (${a.account.currency})')),
          ],
          // The account of a saved transaction is fixed: its currency came from it
          onChanged: editing ? null : onChanged,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.editTransaction : l10n.addTransaction),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, l10n.deleteConfirm)) {
                  await ref.read(ledgerRepositoryProvider).deleteTransaction(_original);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!editing) ...[
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'expense', label: Text(l10n.expense)),
                  ButtonSegment(value: 'income', label: Text(l10n.income)),
                  ButtonSegment(value: 'transfer', label: Text(l10n.transfer)),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) => setState(() {
                  _kind = selection.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
            ],
            AmountField(controller: _amount, currency: account.currency),
            const SizedBox(height: 16),
            accountPicker(isTransfer ? l10n.fromAccount : l10n.account, _accountId,
                (value) => setState(() => _accountId = value)),
            const SizedBox(height: 16),
            if (isTransfer && !editing) ...[
              accountPicker(l10n.toAccount, _toAccountId, (value) => setState(() => _toAccountId = value)),
              const SizedBox(height: 16),
            ],
            if (!isTransfer) ...[
              DropdownButtonFormField<String?>(
                value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                key: ValueKey('category-$_kind-$_categoryId-${categories.length}'),
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.none)),
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  DropdownMenuItem(value: '__add__', child: Text('+ ${l10n.newCategory}')),
                ],
                onChanged: (value) async {
                  if (value != '__add__') return setState(() => _categoryId = value);
                  final name = await promptText(context, title: l10n.newCategory, label: l10n.categoryName);
                  if (name == null) return setState(() {});
                  final id = await ref
                      .read(ledgerRepositoryProvider)
                      .addCategory(widget.workspace.id, name, _kind == 'income' ? 'income' : 'expense');
                  setState(() => _categoryId = id);
                },
              ),
              const SizedBox(height: 16),
            ],
            DateField(value: _date, onChanged: (value) => setState(() => _date = value)),
            const SizedBox(height: 16),
            TextFormField(controller: _note, decoration: InputDecoration(labelText: l10n.note), maxLength: 200),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => _save(accounts), child: Text(l10n.save)),
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
  Widget build(BuildContext context, WidgetRef ref) => AsyncView(
        value: ref.watch(accountsProvider(workspace.id)),
        builder: (accounts) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final item in accounts)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(accountKindIcon(item.account.kind))),
                  title: Text(item.account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.account.isArchived
                      ? context.l10n.archived
                      : accountKindLabel(context, item.account.kind)),
                  trailing: Text(
                    context.money(item.balanceMinor, item.account.currency),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onTap: () => showAccountForm(context, workspace, existing: item.account),
                ),
              ),
          ],
        ),
      );
}

Future<void> showAccountForm(BuildContext context, Workspace workspace, {Account? existing}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  static const _currencies = ['BDT', 'USD', 'EUR', 'GBP', 'INR', 'AED', 'SAR', 'MYR', 'SGD', 'CAD', 'AUD', 'JPY'];

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _kind = widget.existing?.kind ?? 'cash';
  late String _currency = widget.existing?.currency ?? widget.workspace.defaultCurrency;
  late final _opening = TextEditingController(
    text: Money.toInput(widget.existing?.openingBalanceMinor ?? 0, widget.existing?.currency ?? widget.workspace.defaultCurrency),
  );
  late bool _archived = widget.existing?.isArchived ?? false;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(ledgerRepositoryProvider);
    final opening = Money.parse(_opening.text, _currency)!;
    if (widget.existing == null) {
      await repo.addAccount(widget.workspace.id,
          name: _name.text.trim(), kind: _kind, currency: _currency, openingBalanceMinor: opening);
    } else {
      await repo.updateAccount(widget.existing!,
          name: _name.text.trim(), kind: _kind, openingBalanceMinor: opening, isArchived: _archived);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? l10n.editAccount : l10n.addAccount, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.accountName),
              validator: (value) => (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _kind,
              decoration: InputDecoration(labelText: l10n.accountKind),
              items: [
                for (final kind in const ['cash', 'bank', 'savings', 'mobile_money', 'card'])
                  DropdownMenuItem(value: kind, child: Text(accountKindLabel(context, kind))),
              ],
              onChanged: (value) => setState(() => _kind = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: l10n.currency),
              items: [
                for (final code in {..._currencies, _currency}) DropdownMenuItem(value: code, child: Text(code)),
              ],
              // Fixed once the account exists: its transactions are in this currency
              onChanged: editing ? null : (value) => setState(() => _currency = value!),
            ),
            const SizedBox(height: 16),
            AmountField(controller: _opening, currency: _currency, label: l10n.openingBalance, allowZero: true),
            if (editing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.archive),
                value: _archived,
                onChanged: (value) => setState(() => _archived = value),
              ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

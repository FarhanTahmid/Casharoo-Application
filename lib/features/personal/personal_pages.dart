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
  AppTheme.primaryColor, AppTheme.accentColor, AppTheme.warningColor, AppTheme.successColor,
  AppTheme.errorColor, AppTheme.secondaryColor, Colors.teal, Colors.brown,
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

void openTransactionForm(BuildContext context, Workspace workspace, {TransactionView? existing}) =>
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TransactionFormPage(workspace: workspace, existing: existing),
    ));

/// Balances, this month's income and expense, and where the money went.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = workspace.defaultCurrency;
    final accounts = ref.watch(accountsProvider(workspace.id)).value ?? const <AccountBalance>[];
    // Balances in other currencies are listed under Accounts, not added up here
    final total = accounts
        .where((a) => a.account.currency == currency && !a.account.isArchived)
        .fold<int>(0, (sum, a) => sum + a.balanceMinor);
    final repo = ref.watch(ledgerRepositoryProvider);

    return RefreshIndicator(
      onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Card(
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
          const SizedBox(height: 12),
          StreamBuilder<MonthSummary>(
            stream: repo.watchMonth(workspace.id, DateTime.now(), currency),
            builder: (context, snapshot) {
              final month = snapshot.data;
              if (month == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.thisMonth, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _Stat(l10n.income, context.money(month.incomeMinor, currency), amountColor(true)),
                              _Stat(l10n.expense, context.money(month.expenseMinor, currency), amountColor(false)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.spendingByCategory, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
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
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
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
                itemBuilder: (context, index) {
                  final view = transactions[index];
                  final t = view.transaction;
                  final isTransfer = t.kind == 'transfer';
                  final label = isTransfer ? l10n.transfer : (view.categoryName ?? l10n.uncategorised);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(isTransfer
                          ? Icons.swap_horiz
                          : (t.amountMinor > 0 ? Icons.south_west : Icons.north_east)),
                    ),
                    title: Text(t.note.isNotEmpty ? t.note : label),
                    subtitle: Text('${formatDate(context, t.occurredOn)} · ${view.accountName}'
                        '${t.note.isNotEmpty ? ' · $label' : ''}'),
                    trailing: Text(
                      context.money(t.amountMinor, t.currency),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isTransfer ? null : amountColor(t.amountMinor > 0),
                      ),
                    ),
                    onTap: () => openTransactionForm(context, workspace, existing: view),
                  );
                },
              ),
      ),
    );
  }
}

/// Add an expense, income or transfer; or edit the amount, date, category and note of an existing one.
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, required this.workspace, this.existing});

  final Workspace workspace;
  final TransactionView? existing;

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
  late String _date = _original?.occurredOn ?? todayIso();
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

/// Monthly limits per expense category, with how much of each is used.
class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key, required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncView(
      value: ref.watch(budgetsProvider(workspace.id)),
      builder: (budgets) => budgets.isEmpty
          ? EmptyState(icon: Icons.savings_outlined, message: l10n.noBudgets)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final item in budgets)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showBudgetForm(context, ref, workspace, existing: item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                if (item.isOver)
                                  Text(l10n.overBudget, style: const TextStyle(color: AppTheme.errorColor)),
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
                              context.money(item.spentMinor, item.budget.currency),
                              context.money(item.budget.amountMinor, item.budget.currency),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<void> showBudgetForm(BuildContext context, WidgetRef ref, Workspace workspace, {BudgetProgress? existing}) async {
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

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
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
            child: Text(l10n.delete),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await repo.setBudget(workspace.id, categoryId, Money.parse(amount.text, currency)!, currency);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

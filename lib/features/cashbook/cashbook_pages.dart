import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import 'cashbook_repository.dart';

/// Home of a business workspace: its cashbooks with their balances.
class CashbooksPage extends ConsumerWidget {
  const CashbooksPage({super.key, required this.workspace});

  final Workspace workspace;

  bool get _canManage => workspace.role == 'owner' || workspace.role == 'admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
        child: AsyncView(
          value: ref.watch(cashbooksProvider(workspace.id)),
          builder: (books) => books.isEmpty
              ? ListView(children: [
                  SizedBox(height: 400, child: EmptyState(icon: Icons.menu_book_outlined, message: l10n.noCashbooks)),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final summary = books[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                        title: Text(summary.book.bookName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l10n.entriesCount(summary.entryCount)),
                        trailing: Text(
                          context.money(summary.balanceMinor, summary.book.currency),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: amountColor(summary.balanceMinor >= 0),
                          ),
                        ),
                        onTap: () => context.push('/cashbook/${summary.book.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final name = await promptText(context, title: l10n.addCashbook, label: l10n.cashbookName);
                if (name != null) {
                  await ref.read(cashbookRepositoryProvider).createCashbook(workspace.id, name, workspace.defaultCurrency);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addCashbook),
            )
          : null,
    );
  }
}

/// One cashbook: balance, entries, and the Cash in / Cash out buttons.
class CashbookPage extends ConsumerWidget {
  const CashbookPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(cashbookProvider(bookId)).value;
    final workspaces = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    if (summary == null) {
      // Deleted here or on another device
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.menu_book_outlined, message: l10n.noCashbooks));
    }
    final book = summary.book;
    final workspace = workspaces.where((w) => w.id == book.workspaceId).firstOrNull;
    final repo = ref.read(cashbookRepositoryProvider);

    return FutureBuilder<String>(
      future: workspace == null ? Future.value('view') : repo.permissionFor(book, workspace),
      builder: (context, snapshot) {
        final permission = snapshot.data ?? 'view';
        final canEdit = permission != 'view';
        return Scaffold(
          appBar: AppBar(
            title: Text(book.bookName),
            actions: [
              IconButton(
                tooltip: l10n.report,
                icon: const Icon(Icons.pie_chart_outline),
                onPressed: () => context.push('/cashbook/$bookId/report'),
              ),
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'rename') {
                      final name = await promptText(context,
                          title: l10n.rename, label: l10n.cashbookName, initial: book.bookName);
                      if (name != null) await repo.renameCashbook(bookId, name);
                    } else if (await confirm(context, l10n.deleteConfirm)) {
                      await repo.deleteCashbook(bookId);
                      if (context.mounted) context.pop();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                    if (workspace?.role == 'owner') PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              _BalanceHeader(summary: summary),
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.readOnly, style: Theme.of(context).textTheme.bodySmall),
                ),
              Expanded(
                child: AsyncView(
                  value: ref.watch(entriesProvider(bookId)),
                  builder: (entries) => entries.isEmpty
                      ? EmptyState(icon: Icons.receipt_long_outlined, message: l10n.noEntries)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _EntryTile(
                            view: entries[index],
                            onTap: canEdit ? () => _openForm(context, book, entry: entries[index].entry) : null,
                          ),
                        ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: canEdit
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: amountColor(true)),
                            onPressed: () => _openForm(context, book, entryType: 'cash_in'),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.cashIn),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: amountColor(false)),
                            onPressed: () => _openForm(context, book, entryType: 'cash_out'),
                            icon: const Icon(Icons.remove),
                            label: Text(l10n.cashOut),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _openForm(BuildContext context, Cashbook book, {String? entryType, Entry? entry}) => Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => EntryFormPage(book: book, entryType: entryType ?? entry!.entryType, entry: entry),
        ),
      );
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.summary});

  final CashbookSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = summary.book.currency;
    Widget total(String label, int amount, Color color) => Expanded(
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(context.money(amount, currency), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.balance, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              context.money(summary.balanceMinor, currency),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(children: [
              total(l10n.totalIn, summary.cashInMinor, amountColor(true)),
              total(l10n.totalOut, summary.cashOutMinor, amountColor(false)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.view, this.onTap});

  final EntryView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = view.entry;
    final details = [formatDate(context, entry.entryDate), view.categoryName, view.paymentMethodName]
        .whereType<String>()
        .join(' · ');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor(view.isCashIn).withValues(alpha: 0.12),
        child: Icon(view.isCashIn ? Icons.south_west : Icons.north_east, color: amountColor(view.isCashIn)),
      ),
      title: Text(
        (entry.title?.isNotEmpty ?? false) ? entry.title! : (view.isCashIn ? context.l10n.cashIn : context.l10n.cashOut),
      ),
      subtitle: Text(details),
      trailing: Text(
        context.money(entry.amountMinor, entry.currency),
        style: TextStyle(fontWeight: FontWeight.w600, color: amountColor(view.isCashIn)),
      ),
      onTap: onTap,
    );
  }
}

/// Add or edit one cash-in or cash-out entry.
class EntryFormPage extends ConsumerStatefulWidget {
  const EntryFormPage({super.key, required this.book, required this.entryType, this.entry});

  final Cashbook book;
  final String entryType;

  /// Null when adding.
  final Entry? entry;

  @override
  ConsumerState<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends ConsumerState<EntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.entry == null ? '' : Money.toInput(widget.entry!.amountMinor, widget.book.currency),
  );
  late final _title = TextEditingController(text: widget.entry?.title ?? '');
  late final _remarks = TextEditingController(text: widget.entry?.remarks ?? '');
  late String _date = widget.entry?.entryDate ?? todayIso();
  late String? _categoryId = widget.entry?.categoryId;
  late String? _paymentMethodId = widget.entry?.paymentMethodId;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(cashbookRepositoryProvider);
    final amount = Money.parse(_amount.text, widget.book.currency)!;
    if (widget.entry == null) {
      await repo.addEntry(
        widget.book,
        entryType: widget.entryType,
        amountMinor: amount,
        entryDate: _date,
        title: _blankToNull(_title.text),
        remarks: _blankToNull(_remarks.text),
        categoryId: _categoryId,
        paymentMethodId: _paymentMethodId,
      );
    } else {
      await repo.updateEntry(
        widget.entry!,
        amountMinor: amount,
        entryDate: _date,
        title: _blankToNull(_title.text),
        remarks: _blankToNull(_remarks.text),
        categoryId: _categoryId,
        paymentMethodId: _paymentMethodId,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = ref.read(cashbookRepositoryProvider);
    final categories = ref.watch(entryCategoriesProvider(widget.book.id)).value ?? const <EntryCategory>[];
    final methods = ref.watch(paymentMethodsProvider(widget.book.id)).value ?? const <PaymentMethod>[];
    final isIn = widget.entryType == 'cash_in';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? l10n.editEntry : (isIn ? l10n.cashIn : l10n.cashOut)),
        actions: [
          if (widget.entry != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, l10n.deleteConfirm)) {
                  await repo.deleteEntry(widget.entry!.id);
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
            AmountField(controller: _amount, currency: widget.book.currency),
            const SizedBox(height: 16),
            DateField(value: _date, onChanged: (value) => setState(() => _date = value)),
            const SizedBox(height: 16),
            TextFormField(controller: _title, decoration: InputDecoration(labelText: l10n.title), maxLength: 200),
            _PickerField(
              label: l10n.category,
              value: _categoryId,
              options: {for (final c in categories) c.id: c.categoryName},
              addLabel: l10n.newCategory,
              onAdd: (name) => repo.addCategory(widget.book, name),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 16),
            _PickerField(
              label: l10n.paymentMethod,
              value: _paymentMethodId,
              options: {for (final m in methods) m.id: m.paymentMethodName},
              addLabel: l10n.newPaymentMethod,
              onAdd: (name) => repo.addPaymentMethod(widget.book, name),
              onChanged: (value) => setState(() => _paymentMethodId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _remarks, decoration: InputDecoration(labelText: l10n.remarks), maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: amountColor(isIn)),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown with "None" and, optionally, a "New…" item that creates an option.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.addLabel,
    this.onAdd,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;
  final String? addLabel;
  final Future<String> Function(String name)? onAdd;

  static const _addSentinel = '__add__';

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
        // A value that is gone (deleted elsewhere) shows as None instead of crashing the dropdown
        value: options.containsKey(value) ? value : null,
        key: ValueKey('$label-$value-${options.length}'),
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(value: null, child: Text(context.l10n.none)),
          for (final option in options.entries) DropdownMenuItem(value: option.key, child: Text(option.value)),
          if (onAdd != null) DropdownMenuItem(value: _addSentinel, child: Text('+ $addLabel')),
        ],
        onChanged: (selected) async {
          if (selected != _addSentinel) return onChanged(selected);
          final name = await promptText(context, title: addLabel!);
          onChanged(name == null ? value : await onAdd!(name));
        },
      );
}

/// Totals by category and by payment method, computed on the device.
class CashbookReportPage extends ConsumerWidget {
  const CashbookReportPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(cashbookProvider(bookId)).value;
    final repo = ref.watch(cashbookRepositoryProvider);
    if (summary == null) return Scaffold(appBar: AppBar(title: Text(l10n.report)));

    Widget section(String title, bool byCategory) => StreamBuilder<List<BreakdownRow>>(
          stream: repo.watchBreakdown(bookId, byCategory: byCategory),
          builder: (context, snapshot) => Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final row in snapshot.data ?? const <BreakdownRow>[])
                  ListTile(
                    dense: true,
                    title: Text(row.name ?? l10n.uncategorised),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (row.cashInMinor > 0)
                          Text('+${context.money(row.cashInMinor, summary.book.currency)}',
                              style: TextStyle(color: amountColor(true))),
                        if (row.cashOutMinor > 0)
                          Text('-${context.money(row.cashOutMinor, summary.book.currency)}',
                              style: TextStyle(color: amountColor(false))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.report}: ${summary.book.bookName}')),
      body: ListView(
        children: [
          _BalanceHeader(summary: summary),
          section(l10n.byCategory, true),
          section(l10n.byPaymentMethod, false),
        ],
      ),
    );
  }
}

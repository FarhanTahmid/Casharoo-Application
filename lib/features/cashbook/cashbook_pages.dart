import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../plan/plan_page.dart';
import '../plan/plan_text.dart';
import '../plan/upgrade_sheet.dart';
import 'cashbook_repository.dart';

/// Light enough to read as "money out" on the navy header.
const _outOnHeader = Color(0xFFFF9AA2);

/// Home of a business workspace: its cashbooks with their balances.
class CashbooksPage extends ConsumerWidget {
  const CashbooksPage({super.key, required this.workspace});

  final Workspace workspace;

  bool get _canManage => workspace.role == 'owner' || workspace.role == 'admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final value = ref.watch(cashbooksProvider(workspace.id));
    final plan = ref.watch(entitlementsProvider).value;
    final total = (value.value ?? const <CashbookSummary>[])
        .where((s) => s.book.currency == workspace.defaultCurrency)
        .fold<int>(0, (sum, s) => sum + s.balanceMinor);

    Future<void> addCashbook() => showAppSheet<void>(
          context,
          title: l10n.addCashbook,
          builder: (_) => _CashbookForm(workspace: workspace),
        );

    return Scaffold(
      body: PassbookBody(
        header: HeaderFigure(label: l10n.balance, amountMinor: total, currency: workspace.defaultCurrency),
        child: RefreshIndicator(
          onRefresh: ref.read(syncControllerProvider.notifier).syncNow,
          child: AsyncView(
            value: value,
            builder: (books) => books.isEmpty
                ? ListView(children: [
                    SizedBox(
                      height: 380,
                      child: EmptyState(
                        icon: Icons.menu_book_outlined,
                        message: l10n.noCashbooks,
                        actionLabel: _canManage ? l10n.addCashbook : null,
                        onAction: addCashbook,
                      ),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 96),
                    itemCount: books.length + 1,
                    itemBuilder: (context, index) {
                      if (index == books.length) return LimitHint(feature: F.businessCashbooks, workspace: workspace);
                      final summary = books[index];
                      return Entrance(
                        index: index,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: AppSpace.md),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/cashbook/${summary.book.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              child: Row(
                                children: [
                                  const IconBadge(Icons.menu_book_rounded),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(summary.book.bookName,
                                            style: text.titleMedium, overflow: TextOverflow.ellipsis),
                                        // A book in another currency is not in the total above: say which
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                  summary.book.currency == workspace.defaultCurrency
                                                      ? l10n.entriesCount(summary.entryCount)
                                                      : '${l10n.entriesCount(summary.entryCount)} · ${summary.book.currency}',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: text.bodySmall?.copyWith(fontSize: 13)),
                                            ),
                                            // Read-only since a downgrade
                                            if (plan?.isLocked(summary.book.id) ?? false) ...[
                                              const SizedBox(width: 8),
                                              const LockedTag(),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  MoneyText(
                                    summary.balanceMinor,
                                    summary.book.currency,
                                    style: text.titleMedium?.copyWith(color: context.amountColor(summary.balanceMinor >= 0)),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: context.colors.muted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: addCashbook,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addCashbook),
            )
          : null,
    );
  }
}

/// Name and currency of a new cashbook. The currency starts as the workspace's
/// and cannot change later: every entry in the book is in it.
class _CashbookForm extends ConsumerStatefulWidget {
  const _CashbookForm({required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<_CashbookForm> createState() => _CashbookFormState();
}

class _CashbookFormState extends ConsumerState<_CashbookForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late String _currency = widget.workspace.defaultCurrency;
  int _refused = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return setState(() => _refused++);
    final created = await guarded(
      context,
      () => ref.read(cashbookRepositoryProvider).createCashbook(widget.workspace.id, _name.text.trim(), _currency),
    );
    if (!created || !mounted) return;
    showEventBurst(context, AppEvent.saved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.cashbookName),
            validator: (value) => (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 12),
          SelectField<String>(
            label: l10n.currency,
            value: _currency,
            options: currencyOptions(include: _currency),
            onChanged: (value) => setState(() => _currency = value!),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(l10n.currencyFixedHint, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 20),
          Shake(trigger: _refused, child: BusyButton(label: l10n.save, onPressed: _save)),
        ],
      ),
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
        return PassbookScaffold(
          title: Text(book.bookName),
          actions: [
            IconButton(
              tooltip: l10n.report,
              icon: const Icon(Icons.pie_chart_outline_rounded),
              onPressed: () => context.push('/cashbook/$bookId/report'),
            ),
            if (canEdit)
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'categories') {
                    context.push('/cashbook/$bookId/categories');
                  } else if (action == 'rename') {
                    final name =
                        await promptText(context, title: l10n.rename, label: l10n.cashbookName, initial: book.bookName);
                    if (name != null && context.mounted) {
                      await guarded(context, () => repo.renameCashbook(bookId, name));
                    }
                  } else if (await confirm(context, l10n.deleteConfirm)) {
                    await repo.deleteCashbook(bookId);
                    if (!context.mounted) return;
                    showEventBurst(context, AppEvent.deleted);
                    context.pop();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                  if (permission == 'admin') PopupMenuItem(value: 'categories', child: Text(l10n.categories)),
                  if (workspace?.role == 'owner') PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
          ],
          header: _BalanceHeader(summary: summary),
          body: Column(
            children: [
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 0),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: context.colors.muted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.readOnly, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
              Expanded(
                child: AsyncView(
                  value: ref.watch(entriesProvider(bookId)),
                  builder: (entries) => entries.isEmpty
                      ? EmptyState(icon: Icons.receipt_long_outlined, message: l10n.noEntries)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                          itemCount: entries.length,
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
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.sheet,
                    boxShadow: [BoxShadow(color: context.colors.shadow, blurRadius: 24, offset: const Offset(0, -6))],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor: amountColor(true), foregroundColor: Colors.white),
                              onPressed: () => _openForm(context, book, entryType: 'cash_in'),
                              icon: const Icon(Icons.south_west_rounded),
                              label: Text(l10n.cashIn),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor: amountColor(false), foregroundColor: Colors.white),
                              onPressed: () => _openForm(context, book, entryType: 'cash_out'),
                              icon: const Icon(Icons.north_east_rounded),
                              label: Text(l10n.cashOut),
                            ),
                          ),
                        ],
                      ),
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

/// The cashbook's balance on the navy header, with what came in and went out.
class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.summary});

  final CashbookSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = summary.book.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeaderFigure(label: l10n.balance, amountMinor: summary.balanceMinor, currency: currency),
        const SizedBox(height: 12),
        Row(children: [
          HeaderStat(
            label: l10n.totalIn,
            amountMinor: summary.cashInMinor,
            currency: currency,
            color: context.colors.mint,
          ),
          HeaderStat(label: l10n.totalOut, amountMinor: summary.cashOutMinor, currency: currency, color: _outOnHeader),
        ]),
      ],
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
    return MoneyRow(
      icon: view.isCashIn ? Icons.south_west_rounded : Icons.north_east_rounded,
      tint: entry.categoryId == null
          ? context.amountColor(view.isCashIn)
          : context.categoryTint(view.categoryColor, entry.categoryId),
      title: (entry.title?.isNotEmpty ?? false) ? entry.title! : (view.isCashIn ? context.l10n.cashIn : context.l10n.cashOut),
      detail: details,
      amount: context.money(entry.amountMinor, entry.currency),
      amountColor: context.amountColor(view.isCashIn),
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
  int _refused = 0;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _save() => guarded(context, _write);

  Future<void> _write() async {
    if (!_formKey.currentState!.validate()) return setState(() => _refused++);
    final repo = ref.read(cashbookRepositoryProvider);
    final amount = Money.evaluate(_amount.text, widget.book.currency)!;
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
    if (!mounted) return;
    final isIn = widget.entryType == 'cash_in';
    showEventBurst(
      context,
      isIn ? AppEvent.moneyIn : AppEvent.moneyOut,
      label: '${isIn ? '+' : '−'}${context.money(amount, widget.book.currency)}',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = ref.read(cashbookRepositoryProvider);
    final categories = ref.watch(entryCategoriesProvider(widget.book.id)).value ?? const <EntryCategory>[];
    final methods = ref.watch(paymentMethodsProvider(widget.book.id)).value ?? const <PaymentMethod>[];
    final isIn = widget.entryType == 'cash_in';

    return Scaffold(
      backgroundColor: context.colors.sheet,
      appBar: AppBar(
        backgroundColor: context.colors.sheet,
        title: Text(widget.entry != null ? l10n.editEntry : (isIn ? l10n.cashIn : l10n.cashOut)),
        actions: [
          if (widget.entry != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (await confirm(context, l10n.deleteConfirm)) {
                  await repo.deleteEntry(widget.entry!.id);
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
              child: BusyButton(label: l10n.save, color: amountColor(isIn), onPressed: _save),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.lg),
          children: [
            AmountField(
              controller: _amount,
              currency: widget.book.currency,
              hero: true,
              autofocus: widget.entry == null,
              color: context.amountColor(isIn),
            ),
            const SizedBox(height: 20),
            DateField(value: _date, onChanged: (value) => setState(() => _date = value)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.title),
              maxLength: 200,
              buildCounter: quietCounter,
            ),
            const SizedBox(height: 12),
            SelectField<String>(
              label: l10n.category,
              icon: Icons.sell_outlined,
              value: _categoryId,
              noneLabel: l10n.none,
              options: [
                for (final c in categories) SelectOption(c.id, c.categoryName, color: categoryFill(c.color, c.id)),
              ],
              createLabel: l10n.newCategory,
              onCreate: (name) => repo.addCategory(widget.book, name),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 12),
            SelectField<String>(
              label: l10n.paymentMethod,
              icon: Icons.account_balance_wallet_outlined,
              value: _paymentMethodId,
              noneLabel: l10n.none,
              options: [for (final m in methods) SelectOption(m.id, m.paymentMethodName)],
              createLabel: l10n.newPaymentMethod,
              onCreate: (name) => repo.addPaymentMethod(widget.book, name),
              onChanged: (value) => setState(() => _paymentMethodId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarks,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.remarks),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Totals by category and by payment method, computed on the device.
class CashbookReportPage extends ConsumerWidget {
  const CashbookReportPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(cashbookProvider(bookId)).value;
    final repo = ref.watch(cashbookRepositoryProvider);
    if (summary == null) return Scaffold(appBar: AppBar(title: Text(l10n.report)));
    final currency = summary.book.currency;

    Widget section(String title, bool byCategory) => StreamBuilder<List<BreakdownRow>>(
          stream: repo.watchBreakdown(bookId, byCategory: byCategory),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <BreakdownRow>[];
            // Bars share one scale, so the longest is the biggest figure in the section
            final largest = rows.fold<int>(
                1, (max, r) => [max, r.cashInMinor, r.cashOutMinor].reduce((a, b) => a > b ? a : b));
            Widget bar(int amount, Color color) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: amount / largest),
                    duration: context.motion(const Duration(milliseconds: 450)),
                    curve: AppMotion.ease,
                    builder: (context, value, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value.clamp(0.02, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                );
            final spent = byCategory ? rows.where((r) => r.cashOutMinor > 0).toList() : const <BreakdownRow>[];
            return SectionCard(title: title, children: [
              // Where the money went, each category in its own colour
              if (spent.isNotEmpty)
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
                            for (final row in spent)
                              PieChartSectionData(
                                value: row.cashOutMinor.toDouble(),
                                color: categoryFill(row.color, row.id),
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
                          Text(l10n.totalOut, style: text.bodySmall),
                          SizedBox(
                            width: 108,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Money.compact(summary.cashOutMinor, currency, locale: context.languageCode),
                                style: text.headlineSmall?.copyWith(fontFeatures: tabularFigures),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (byCategory)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 10),
                              child: ColorDot(categoryFill(row.color, row.id)),
                            ),
                          Expanded(child: Text(row.name ?? l10n.uncategorised, overflow: TextOverflow.ellipsis)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (row.cashInMinor > 0)
                                Text(
                                  '+${context.money(row.cashInMinor, currency)}',
                                  style: text.bodyMedium?.copyWith(
                                    color: context.amountColor(true),
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabularFigures,
                                  ),
                                ),
                              if (row.cashOutMinor > 0)
                                Text(
                                  '-${context.money(row.cashOutMinor, currency)}',
                                  style: text.bodyMedium?.copyWith(
                                    color: context.amountColor(false),
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: tabularFigures,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (row.cashInMinor > 0) bar(row.cashInMinor, amountColor(true)),
                      if (row.cashOutMinor > 0) bar(row.cashOutMinor, amountColor(false)),
                    ],
                  ),
                ),
            ]);
          },
        );

    return PassbookScaffold(
      title: Text('${l10n.report}: ${summary.book.bookName}'),
      header: _BalanceHeader(summary: summary),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
        children: [
          section(l10n.byCategory, true),
          section(l10n.byPaymentMethod, false),
        ],
      ),
    );
  }
}

/// The categories of one cashbook: add one, or change a name or colour.
/// For the people who may administer the book.
class CashbookCategoriesPage extends ConsumerWidget {
  const CashbookCategoriesPage({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final book = ref.watch(cashbookProvider(bookId)).value?.book;
    final repo = ref.read(cashbookRepositoryProvider);
    if (book == null) return Scaffold(appBar: AppBar(title: Text(l10n.categories)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: AsyncView(
        value: ref.watch(entryCategoriesProvider(bookId)),
        builder: (categories) => categories.isEmpty
            ? EmptyState(icon: Icons.sell_outlined, message: l10n.noCategories)
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 96),
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (index, category) in categories.indexed) ...[
                          if (index > 0) const Divider(indent: 68),
                          ListTile(
                            leading: IconBadge(
                              Icons.sell_outlined,
                              color: context.categoryTint(category.color, category.id),
                              size: 36,
                            ),
                            title: Text(category.categoryName),
                            trailing: Icon(Icons.chevron_right_rounded, color: context.colors.muted),
                            onTap: () async {
                              final edited = await showCategorySheet(context,
                                  title: l10n.editCategory,
                                  initialName: category.categoryName,
                                  initialColor: category.color);
                              if (edited != null && context.mounted) {
                                await guarded(context,
                                    () => repo.updateCategory(category, name: edited.name, color: edited.color));
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newCategory),
        onPressed: () async {
          final edited = await showCategorySheet(context, title: l10n.newCategory);
          if (edited == null || !context.mounted) return;
          await repo.addCategory(book, edited.name, color: edited.color);
          if (context.mounted) showEventBurst(context, AppEvent.saved);
        },
      ),
    );
  }
}

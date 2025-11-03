import 'dart:async';
import 'package:flutter/material.dart';
import 'package:casharoo/services/cashbook_operations/models/api_repository.dart';
import 'package:casharoo/services/cashbook_operations/models/mock_repository.dart';
import 'package:casharoo/services/cashbook_operations/data/entry.dart';
import 'package:casharoo/services/cashbook_operations/models/filters.dart';
import 'package:casharoo/services/reports/screens/reports_page.dart';
import './entry_forms/entry_forms_page.dart';
import './popups/category_picker_sheet.dart';
import './popups/payment_mode_sheet.dart';
import 'widgets/balance_carousel.dart';
import 'widgets/entry_list_item.dart';
import 'widgets/filter_bar.dart';
import 'widgets/top_actions_overflow.dart';

class CashbookEntriesPage extends StatefulWidget {
  final String cashbookId;
  final String cashbookName;
  const CashbookEntriesPage({
    super.key,
    required this.cashbookId,
    required this.cashbookName,
  });

  @override
  State<CashbookEntriesPage> createState() => _CashbookEntriesPageState();
}

class _CashbookEntriesPageState extends State<CashbookEntriesPage> {
  final EntryRepository repo = MockEntryRepository(); // swap to real impl later
  final TextEditingController _searchCtrl = TextEditingController();
  EntryFilters filters = EntryFilters();

  // data
  List<Entry> entries = [];
  double totalIn = 0, totalOut = 0, net = 0;

  // selection
  final Set<String> _selected = {};
  bool get selectionMode => _selected.isNotEmpty;

  // banner/analytics auto-slide
  final PageController _summaryCtrl = PageController(viewportFraction: 0.95);
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _autoTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_summaryCtrl.positions.isEmpty) return;
      final next = ((_summaryCtrl.page ?? 0).round() + 1) % 3;
      _summaryCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _summaryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await repo.listEntries(
      cashbookId: widget.cashbookId,
      filters: filters.copyWith(search: _searchCtrl.text),
    );
    setState(() {
      entries = res.$1;
      totalIn = res.$2;
      totalOut = res.$3;
      net = res.$4;
      // maintain selected only if still present
      _selected.removeWhere((id) => !entries.any((e) => e.id == id));
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected entries?'),
        content: Text('This will permanently delete ${_selected.length} entries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.deleteEntriesBulk(cashbookId: widget.cashbookId, entryIds: _selected.toList());
    _selected.clear();
    // silent refresh
    await _load();
  }

  Future<void> _openAdd(EntryType t) async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(
          cashbookId: widget.cashbookId,
          initialType: t,
          repo: repo,
        ),
      ),
    );
    if (created == true) {
      await _load(); // silent refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.cashbookName, style: t.titleLarge),
            Text('Add Member, Book Activity etc', style: t.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add member',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {/* TODO: route */},
          ),
          IconButton(
            tooltip: 'Reports',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportsPage(cashbookId: widget.cashbookId, repo: repo)),
              );
            },
          ),
          TopActionsOverflow(onNavigate: (route) {/* TODO */}),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: selectionMode
          ? FloatingActionButton.extended(
              onPressed: _bulkDelete,
              backgroundColor: cs.error,
              icon: const Icon(Icons.delete_rounded),
              label: Text('Delete (${_selected.length})'),
            )
          : _EntryActionBar(
              onCashIn: () => _openAdd(EntryType.cashIn),
              onCashOut: () => _openAdd(EntryType.cashOut),
            ),

      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // Search
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by remark or amount',
              ),
            ),
            const SizedBox(height: 12),

            // Filters row
            FilterBar(
              filters: filters,
              onChange: (f) async {
                setState(() => filters = f);
                await _load();
              },
              onOpenCategories: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CategoryPickerSheet(cashbookId: widget.cashbookId, repo: repo),
                );
                await _load();
              },
              onOpenPaymentModes: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PaymentModeSheet(cashbookId: widget.cashbookId, repo: repo),
                );
                await _load();
              },
            ),

            const SizedBox(height: 12),

            // Balance + Analytics carousel
            BalanceCarousel(
              controller: _summaryCtrl,
              net: net,
              totalIn: totalIn,
              totalOut: totalOut,
              onViewReports: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReportsPage(cashbookId: widget.cashbookId, repo: repo)),
                );
              },
            ),

            const SizedBox(height: 16),

            // Entries header
            Center(child: Text('Showing ${entries.length} entries', style: t.bodySmall)),
            const SizedBox(height: 8),

            // Entries
            ..._buildEntryTiles(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEntryTiles(BuildContext context) {
    final tiles = <Widget>[];
    DateTime? currentDay;

    for (final e in entries) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      if (currentDay != day) {
        currentDay = day;
        tiles.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(child: Divider(endIndent: 12)),
              Text('${day.day} ${_month(day.month)} ${day.year}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Expanded(child: Divider(indent: 12)),
            ],
          ),
        ));
      }

      tiles.add(
        EntryListItem(
          entry: e,
          selected: _selected.contains(e.id),
          onTap: selectionMode ? () => _toggleSelect(e.id) : null,
          onLongPress: () => _toggleSelect(e.id),
        ),
      );
    }
    return tiles;
  }

  String _month(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m-1];
  }
}

class _EntryActionBar extends StatelessWidget {
  final VoidCallback onCashIn;
  final VoidCallback onCashOut;
  const _EntryActionBar({required this.onCashIn, required this.onCashOut});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCashIn,
              icon: const Icon(Icons.add),
              label: const Text('CASH IN'),
              style: ElevatedButton.styleFrom(backgroundColor: cs.secondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCashOut,
              icon: const Icon(Icons.remove),
              label: const Text('CASH OUT'),
              style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../utils/utils.dart';
import './widgets/adaptive_scaffold.dart';
import './widgets/cashbook_card.dart';
import './widgets/cashbook_filter_sheet.dart';
import './widgets/add_cashbook_dialog.dart';
import './widgets/search_delegate.dart' as cbsearch;

class CashbookHomePage extends StatefulWidget {
  const CashbookHomePage({super.key});

  @override
  State<CashbookHomePage> createState() => _CashbookHomePageState();
}

class _CashbookHomePageState extends State<CashbookHomePage> {
  final _utility = CashbookUtils();

  List<Cashbook> _cashbooks = [];
  final Set<String> _selectedIds = <String>{};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  final List<String> _banners = const [
    'Feature Upgrades Are Coming Soon!',
    'Allow data operator to edit entries for faster corrections.',
    'More Custom Field types: Number and Dropdown.',
  ];

  final PageController _bannerCtrl = PageController(viewportFraction: 0.95);
  Timer? _autoTimer;
  bool _showBanner = true;

  CashbookSort _sort = CashbookSort.lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
    _startAutoBanner();
  }

  void _startAutoBanner() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_showBanner || _bannerCtrl.positions.isEmpty) return;
      final next = (_bannerCtrl.page ?? 0).round() + 1;
      _bannerCtrl.animateToPage(
        next % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _load() async {
    final items = await _utility.fetchCashbooks(); // API hook
    if (!mounted) return;
    setState(() {
      _cashbooks = _utility.sort(items, _sort);
      // if items changed, clear invalid selections
      _selectedIds.removeWhere((id) => !_cashbooks.any((c) => c.id == id));
    });
  }

  void _openFilter() async {
    final result = await showModalBottomSheet<CashbookSort>(
      context: context,
      showDragHandle: true,
      builder: (_) => CashbookFilterSheet(selected: _sort),
    );
    if (result != null && result != _sort) {
      setState(() {
        _sort = result;
        _cashbooks = _utility.sort(_cashbooks, _sort);
      });
    }
  }

  void _openSearch() async {
    final chosen = await showSearch<Cashbook?>(
      context: context,
      delegate: cbsearch.CashbookSearchDelegate(data: _cashbooks),
    );
    if (chosen != null && mounted) {
      // TODO: navigate to details if you add a details page
    }
  }

  Future<void> _openAddDialog() async {
    final created = await showDialog<Cashbook>(
      context: context,
      builder: (_) => const AddCashbookDialog(),
    );
    if (created != null) {
      await _load(); // silently reload
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text('This will permanently delete $count cashbook(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // API hook (implement bulk endpoint if available)
    await _utility.bulkDeleteCashbooks(_selectedIds.toList());
    _clearSelection();
    await _load(); // silent refresh
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AdaptiveScaffold(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        // TODO: navigate to Help/Settings
      },
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Cancel selection',
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              )
            : null,
        title: _selectionMode
            ? Text('${_selectedIds.length} selected')
            : const Text('Casharooo'),
        actions: [
          if (!_selectionMode) ...[
            IconButton(
              tooltip: 'Sort / Filter',
              onPressed: _openFilter,
              icon: const Icon(Icons.filter_list_rounded),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Select all',
              onPressed: () {
                setState(
                  () => _selectedIds
                    ..clear()
                    ..addAll(_cashbooks.map((e) => e.id)),
                );
              },
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Delete selected',
              onPressed: _bulkDelete,
              icon: const Icon(Icons.delete_forever_rounded),
            ),
          ],
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add New Book'),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            if (_showBanner) ...[
              _BannerCarousel(
                banners: _banners,
                controller: _bannerCtrl,
                onClose: () => setState(() => _showBanner = false),
              ),
              const SizedBox(height: 16),
            ],
            Text('Your Books', style: t.headlineMedium),
            const SizedBox(height: 12),
            ..._cashbooks.map((c) {
              final selected = _selectedIds.contains(c.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CashbookCard(
                  cashbook: c,
                  // Selection-specific flags & callbacks:
                  selectionMode: _selectionMode,
                  selected: selected,
                  onCardTap: () {
                    if (_selectionMode) {
                      _toggleSelect(c.id);
                    } else {
                      // TODO: open details
                    }
                  },
                  onCardLongPress: () {
                    if (!_selectionMode) {
                      setState(() => _selectedIds.add(c.id));
                    } else {
                      _toggleSelect(c.id);
                    }
                  },
                  // Keep single-delete path inside each card (with its own confirmation).
                  onDelete: () async {
                    await _load();
                  },
                  onRename: () async {
                    await _load();
                  },
                  onMove: () {
                    /* optional */
                  },
                ),
              );
            }),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<String> banners;
  final PageController controller;
  final VoidCallback onClose;
  const _BannerCarousel({
    required this.banners,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        SizedBox(
          height: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: PageView.builder(
              controller: controller,
              itemCount: banners.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondary.withOpacity(.18),
                      cs.tertiary.withOpacity(.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_circle_rounded,
                      color: cs.secondary,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        banners[i],
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}
